const db = require('../config/database');
const { createSession, deleteSession } = require('../config/sessionStore');
const { fetchLiveSignals } = require('../services/openMeteoService');

const ADMIN_EMAIL = (process.env.ADMIN_EMAIL || 'admin@cashurance.com').toLowerCase();
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'Admin@123';

const payoutOverrides = new Map();
const fraudStatusOverrides = new Map();

function all(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.all(sql, params, (err, rows) => {
            if (err) {
                reject(err);
                return;
            }
            resolve(rows);
        });
    });
}

function run(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.run(sql, params, function onRun(err) {
            if (err) {
                reject(err);
                return;
            }
            resolve({ changes: this.changes });
        });
    });
}

function get(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.get(sql, params, (err, row) => {
            if (err) {
                reject(err);
                return;
            }
            resolve(row);
        });
    });
}

function toIsoDate(value) {
    if (!value) return null;
    const parsed = new Date(value);
    if (Number.isNaN(parsed.getTime())) return null;
    return parsed.toISOString();
}

function normalizeSeverity(value) {
    if (value === 'catastrophic') return 'high';
    if (value === 'severe') return 'medium';
    return 'low';
}

function triggerType(eventType) {
    switch (eventType) {
        case 'flood':
        case 'heat':
            return 'Weather';
        case 'aqi':
            return 'Air Quality';
        default:
            return 'Mobility';
    }
}

function triggerMessage(alert) {
    if (alert.eventType === 'flood') {
        return `Rain trigger level: ${alert.metrics?.rainMm ?? 0}mm.`;
    }
    if (alert.eventType === 'heat') {
        return `Heat trigger level: ${alert.metrics?.temperature ?? 0}C.`;
    }
    if (alert.eventType === 'aqi') {
        return `AQI trigger level: ${alert.metrics?.usAqi ?? 0}.`;
    }
    return `Mobility stress score: ${alert.metrics?.trafficScore ?? 0}.`;
}

async function buildLiveTriggerFeed(workers) {
    const zoneMap = new Map();
    workers.forEach((worker) => {
        const zone = String(worker.zone_name || '').trim();
        if (zone && !zoneMap.has(zone)) {
            zoneMap.set(zone, {
                zoneName: zone,
                latitude: Number(worker.zone_latitude),
                longitude: Number(worker.zone_longitude),
            });
        }
    });

    const zones = [...zoneMap.values()].slice(0, 12);
    const signals = await Promise.all(zones.map(async (zone) => {
        try {
            return {
                zone: zone.zoneName,
                payload: await fetchLiveSignals(zone),
            };
        } catch (_) {
            return null;
        }
    }));

    const feed = [];
    signals.filter(Boolean).forEach((item) => {
        item.payload.triggerAlerts.forEach((alert) => {
            feed.push({
                id: alert.eventId,
                city: item.zone,
                type: triggerType(alert.eventType),
                severity: normalizeSeverity(alert.severity),
                message: triggerMessage(alert),
                createdAt: alert.timestamp,
            });
        });
    });

    return feed.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
}

async function derivePayoutRows(workers) {
    const rows = [];
    const zoneSignals = new Map();

    for (const worker of workers) {
        if (!worker.zone_confirmed || !worker.online_today) {
            // skip
            continue;
        }

        const zone = String(worker.zone_name || 'Bengaluru');
        if (!zoneSignals.has(zone)) {
            try {
                zoneSignals.set(zone, await fetchLiveSignals({
                    zoneName: zone,
                    latitude: Number(worker.zone_latitude),
                    longitude: Number(worker.zone_longitude),
                }));
            } catch (_) {
                zoneSignals.set(zone, null);
            }
        }

        const signals = zoneSignals.get(zone);
        if (!signals) continue;

        const triggered = signals.triggerAlerts.filter((alert) => alert.zoneStatus === 'triggered');
        if (!triggered.length) continue;

        // Unified payout formula — same as appController
        const avgIncome = Number(worker.avg_daily_income) || 1200;
        const basePayout = avgIncome * 0.60;
        const maxPayout = Math.min(avgIncome * 0.75, 1000);

        // Use the worst severity across all triggered events
        const hasCatastrophic = triggered.some((a) => a.severity === 'catastrophic');
        const hasSevere = triggered.some((a) => a.severity === 'severe');
        const severityFactor = hasCatastrophic ? 1.25 : (hasSevere ? 1.15 : 1.0);

        const rawAmount = basePayout * severityFactor;
        const amount = Number(Math.min(rawAmount, maxPayout).toFixed(2));

        const id = `PAYOUT-${worker.id}`;
        const overridden = payoutOverrides.get(id);

        rows.push({
            id,
            workerId: worker.id,
            workerName: worker.full_name,
            platform: worker.platform || 'Unknown',
            zone: worker.zone_name || 'Unknown',
            amount,
            createdAt: toIsoDate(worker.last_payment_at) || new Date().toISOString(),
            status: overridden || 'pending',
            reason: `Live trigger-qualified payout (${triggered.length} trigger events in zone, severity: ${hasCatastrophic ? 'catastrophic' : hasSevere ? 'severe' : 'normal'}).`,
        });
    }

    return rows;
}

function deriveFraudRows(workers) {
    return workers.slice(0, 6).map((worker, index) => {
        const id = `FRAUD-${worker.id}`;
        const overrideStatus = fraudStatusOverrides.get(id);
        const baseRisk = worker.online_today ? 'medium' : 'low';
        return {
            id,
            workerId: worker.id,
            workerName: worker.full_name,
            signal: index % 2 === 0 ? 'GPS mismatch' : 'Duplicate payout fingerprint',
            risk: baseRisk,
            status: overrideStatus || 'open',
            createdAt: new Date(Date.now() - index * 3600 * 1000).toISOString(),
        };
    });
}

async function recordAdminAction({
    adminEmail,
    type,
    workerId = null,
    status = null,
    reason = null,
    refId = null,
}) {
    await run(
        `INSERT INTO admin_audit_logs (admin_email, action_type, worker_id, status, reason, ref_id)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [adminEmail || ADMIN_EMAIL, type, workerId, status, reason, refId],
    );
}

async function recordWorkerActivity(workerId, eventType, metadata = null) {
    await run(
        'INSERT INTO activity_logs (worker_id, event_type, metadata) VALUES (?, ?, ?)',
        [workerId, eventType, metadata ? JSON.stringify(metadata) : null],
    );
}

exports.login = async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ success: false, message: 'email and password are required.' });
    }

    if (String(email).trim().toLowerCase() !== ADMIN_EMAIL || String(password) !== ADMIN_PASSWORD) {
        return res.status(401).json({ success: false, message: 'Invalid admin credentials.' });
    }

    const token = createSession({
        type: 'admin',
        email: ADMIN_EMAIL,
    });

    return res.json({
        success: true,
        data: {
            token,
            email: ADMIN_EMAIL,
        },
    });
};

exports.logout = (req, res) => {
    if (req.authToken) {
        deleteSession(req.authToken);
    }
    return res.json({ success: true });
};

exports.dashboard = async (req, res) => {
    try {
        const workers = await all(
              `SELECT id, full_name, status, zone_name, zone_latitude, zone_longitude, zone_confirmed, online_today, avg_daily_income, payouts_settled
             FROM workers
             ORDER BY created_at DESC`,
        );
        const [payouts, liveTriggerFeed] = await Promise.all([
            derivePayoutRows(workers),
            buildLiveTriggerFeed(workers),
        ]);

        const activeWorkers = workers.filter((w) => String(w.status || '').toUpperCase() === 'ACTIVE').length;
        const onlineWorkers = workers.filter((w) => Number(w.online_today) === 1).length;
        const totalExposure = workers.reduce((sum, w) => sum + Number(w.avg_daily_income || 0), 0);
        const pendingPayouts = payouts.filter((p) => p.status === 'pending').length;
        const activityRow = await get(
            `SELECT COUNT(*) AS count
             FROM activity_logs
             WHERE created_at >= datetime('now', '-1 day')`,
        );
        const suspensionRow = await get(
            `SELECT COUNT(*) AS count
             FROM admin_audit_logs
             WHERE action_type = 'worker_status_update'
             AND status = 'SUSPENDED'
             AND created_at >= datetime('now', 'start of day')`,
        );

        return res.json({
            success: true,
            data: {
                metrics: {
                    totalWorkers: workers.length,
                    activeWorkers,
                    onlineWorkers,
                    pendingPayouts,
                    triggerEvents: liveTriggerFeed.length,
                    totalExposure: Number(totalExposure.toFixed(2)),
                    recentWorkerActivity: Number(activityRow?.count || 0),
                    suspensionsToday: Number(suspensionRow?.count || 0),
                },
            },
        });
    } catch (error) {
        console.error('admin dashboard error', error);
        return res.status(500).json({ success: false, message: 'Internal server error.' });
    }
};

exports.listWorkers = async (req, res) => {
    try {
        const workers = await all(
            `SELECT
                id,
                full_name,
                phone,
                platform,
                status,
                zone_name,
                zone_confirmed,
                online_today,
                policy_premium,
                last_payment_at,
                next_payment_due_at,
                policies_purchased,
                payouts_settled,
                created_at
             FROM workers
             ORDER BY created_at DESC`,
        );

        return res.json({ success: true, data: { workers } });
    } catch (error) {
        console.error('admin listWorkers error', error);
        return res.status(500).json({ success: false, message: 'Internal server error.' });
    }
};

exports.updateWorkerStatus = async (req, res) => {
    try {
        const workerId = Number(req.params.id);
        const { status, reason = null } = req.body;
        const normalizedStatus = String(status || '').trim().toUpperCase();

        if (!workerId || !['ACTIVE', 'SUSPENDED'].includes(normalizedStatus)) {
            return res.status(400).json({ success: false, message: 'Invalid worker id or status.' });
        }
        if (normalizedStatus === 'SUSPENDED' && !String(reason || '').trim()) {
            return res.status(400).json({ success: false, message: 'Suspension reason is required.' });
        }

        const result = await run('UPDATE workers SET status = ? WHERE id = ?', [normalizedStatus, workerId]);
        if (!result.changes) {
            return res.status(404).json({ success: false, message: 'Worker not found.' });
        }

        await recordAdminAction({
            adminEmail: req.adminEmail,
            type: 'worker_status_update',
            workerId,
            status: normalizedStatus,
            reason,
        });
        await recordWorkerActivity(workerId, 'status_updated_by_admin', {
            status: normalizedStatus,
            reason: String(reason || '').trim() || null,
        });

        return res.json({ success: true });
    } catch (error) {
        console.error('admin updateWorkerStatus error', error);
        return res.status(500).json({ success: false, message: 'Internal server error.' });
    }
};

exports.workerHistory = async (req, res) => {
    try {
        const workerId = Number(req.params.id);
        if (!workerId) {
            return res.status(400).json({ success: false, message: 'Invalid worker id.' });
        }

        const rows = await all(
            `SELECT
                id,
                full_name,
                phone,
                platform,
                status,
                zone_name,
                zone_confirmed,
                online_today,
                policy_start,
                policy_premium,
                last_payment_at,
                next_payment_due_at,
                avg_daily_income,
                policies_purchased,
                payouts_settled,
                created_at
             FROM workers
             WHERE id = ?`,
            [workerId],
        );

        const worker = rows[0];
        if (!worker) {
            return res.status(404).json({ success: false, message: 'Worker not found.' });
        }

        const [payoutRows, liveTriggerFeed] = await Promise.all([
            derivePayoutRows([worker]),
            buildLiveTriggerFeed([worker]),
        ]);
        const workerActions = await all(
            `SELECT
                id,
                action_type AS type,
                worker_id AS workerId,
                status,
                reason,
                ref_id AS refId,
                created_at AS createdAt,
                admin_email AS adminEmail
             FROM admin_audit_logs
             WHERE worker_id = ?
             ORDER BY created_at DESC
             LIMIT 100`,
            [workerId],
        );
        const activityTimeline = await all(
            `SELECT
                id,
                worker_id AS workerId,
                event_type AS eventType,
                metadata,
                created_at AS createdAt
             FROM activity_logs
             WHERE worker_id = ?
             ORDER BY created_at DESC
             LIMIT 200`,
            [workerId],
        );

        const disruptions = liveTriggerFeed.filter(
            (item) => String(item.city || '').toLowerCase() === String(worker.zone_name || '').toLowerCase(),
        );

        return res.json({
            success: true,
            data: {
                worker,
                payouts: payoutRows,
                disruptions,
                adminActions: workerActions,
                activityTimeline,
            },
        });
    } catch (error) {
        console.error('admin workerHistory error', error);
        return res.status(500).json({ success: false, message: 'Internal server error.' });
    }
};

exports.listTriggers = async (req, res) => {
    try {
        const workers = await all(
              `SELECT id, zone_name, zone_latitude, zone_longitude
             FROM workers
             ORDER BY created_at DESC`,
        );
        const triggers = await buildLiveTriggerFeed(workers);
        return res.json({
            success: true,
            data: {
                triggers,
            },
        });
    } catch (error) {
        console.error('admin listTriggers error', error);
        return res.status(500).json({ success: false, message: 'Internal server error.' });
    }
};

exports.listPayouts = async (req, res) => {
    try {
        const workers = await all(
              `SELECT id, full_name, platform, zone_name, zone_latitude, zone_longitude, zone_confirmed, online_today, avg_daily_income, last_payment_at
             FROM workers`,
        );

        const payouts = await derivePayoutRows(workers);

        return res.json({
            success: true,
            data: {
                payouts,
            },
        });
    } catch (error) {
        console.error('admin listPayouts error', error);
        return res.status(500).json({ success: false, message: 'Internal server error.' });
    }
};

exports.updatePayoutStatus = (req, res) => {
    const payoutId = String(req.params.id || '').trim();
    const action = String(req.body.action || '').trim().toLowerCase();

    if (!payoutId || !['approve', 'reject'].includes(action)) {
        return res.status(400).json({ success: false, message: 'Invalid payout action.' });
    }

    payoutOverrides.set(payoutId, action === 'approve' ? 'approved' : 'rejected');
    const payoutWorkerId = Number(String(payoutId).replace('PAYOUT-', ''));
    const status = action === 'approve' ? 'APPROVED' : 'REJECTED';
    Promise.resolve()
        .then(() => recordAdminAction({
            adminEmail: req.adminEmail,
            type: 'payout_update',
            workerId: Number.isNaN(payoutWorkerId) ? null : payoutWorkerId,
            status,
            refId: payoutId,
        }))
        .then(() => {
            if (!Number.isNaN(payoutWorkerId)) {
                return recordWorkerActivity(payoutWorkerId, 'payout_reviewed', {
                    payoutId,
                    status,
                });
            }
            return null;
        })
        .then(() => res.json({ success: true }))
        .catch((error) => {
            console.error('admin updatePayoutStatus error', error);
            res.status(500).json({ success: false, message: 'Internal server error.' });
        });
};

exports.listFraudAlerts = async (req, res) => {
    try {
        const workers = await all(
            `SELECT id, full_name, online_today
             FROM workers
             ORDER BY created_at DESC`,
        );

        return res.json({
            success: true,
            data: {
                alerts: deriveFraudRows(workers),
            },
        });
    } catch (error) {
        console.error('admin listFraudAlerts error', error);
        return res.status(500).json({ success: false, message: 'Internal server error.' });
    }
};

exports.updateFraudStatus = (req, res) => {
    const alertId = String(req.params.id || '').trim();
    const action = String(req.body.action || '').trim().toLowerCase();

    if (!alertId || !['resolve', 'escalate'].includes(action)) {
        return res.status(400).json({ success: false, message: 'Invalid fraud action.' });
    }

    fraudStatusOverrides.set(alertId, action === 'resolve' ? 'resolved' : 'escalated');
    const fraudWorkerId = Number(String(alertId).replace('FRAUD-', ''));
    const status = action === 'resolve' ? 'RESOLVED' : 'ESCALATED';
    Promise.resolve()
        .then(() => recordAdminAction({
            adminEmail: req.adminEmail,
            type: 'fraud_update',
            workerId: Number.isNaN(fraudWorkerId) ? null : fraudWorkerId,
            status,
            refId: alertId,
        }))
        .then(() => {
            if (!Number.isNaN(fraudWorkerId)) {
                return recordWorkerActivity(fraudWorkerId, 'fraud_alert_reviewed', {
                    alertId,
                    status,
                });
            }
            return null;
        })
        .then(() => res.json({ success: true }))
        .catch((error) => {
            console.error('admin updateFraudStatus error', error);
            res.status(500).json({ success: false, message: 'Internal server error.' });
        });
};

exports.workerActivity = async (req, res) => {
    try {
        const workerId = Number(req.params.id);
        if (!workerId) {
            return res.status(400).json({ success: false, message: 'Invalid worker id.' });
        }

        const timeline = await all(
            `SELECT
                id,
                worker_id AS workerId,
                event_type AS eventType,
                metadata,
                created_at AS createdAt
             FROM activity_logs
             WHERE worker_id = ?
             ORDER BY created_at DESC
             LIMIT 200`,
            [workerId],
        );

        return res.json({ success: true, data: { activity: timeline } });
    } catch (error) {
        console.error('admin workerActivity error', error);
        return res.status(500).json({ success: false, message: 'Internal server error.' });
    }
};

exports.listActivityFeed = async (req, res) => {
    try {
        const page = Math.max(1, Number(req.query.page || 1));
        const limit = Math.min(100, Math.max(1, Number(req.query.limit || 25)));
        const offset = (page - 1) * limit;
        const workerId = req.query.workerId ? Number(req.query.workerId) : null;
        const eventType = String(req.query.eventType || '').trim();

        const where = [];
        const params = [];

        if (workerId) {
            where.push('a.worker_id = ?');
            params.push(workerId);
        }
        if (eventType) {
            where.push('a.event_type = ?');
            params.push(eventType);
        }

        const whereClause = where.length ? `WHERE ${where.join(' AND ')}` : '';

        const rows = await all(
            `SELECT
                a.id,
                a.worker_id AS workerId,
                w.full_name AS workerName,
                a.event_type AS eventType,
                a.metadata,
                a.created_at AS createdAt
             FROM activity_logs a
             LEFT JOIN workers w ON w.id = a.worker_id
             ${whereClause}
             ORDER BY a.created_at DESC
             LIMIT ? OFFSET ?`,
            [...params, limit, offset],
        );

        const countRow = await get(
            `SELECT COUNT(*) AS count
             FROM activity_logs a
             ${whereClause}`,
            params,
        );

        return res.json({
            success: true,
            data: {
                items: rows,
                page,
                limit,
                total: Number(countRow?.count || 0),
            },
        });
    } catch (error) {
        console.error('admin listActivityFeed error', error);
        return res.status(500).json({ success: false, message: 'Internal server error.' });
    }
};
