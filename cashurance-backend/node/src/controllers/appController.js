const db = require('../config/database');
const { fetchLiveSignals } = require('../services/openMeteoService');
const { scorePremiumWithML } = require('../services/mlPremiumService');

function run(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.run(sql, params, function onRun(err) {
            if (err) {
                reject(err);
                return;
            }
            resolve({ lastID: this.lastID, changes: this.changes });
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

async function recordActivity(workerId, eventType, metadata = null) {
    await run(
        'INSERT INTO activity_logs (worker_id, event_type, metadata) VALUES (?, ?, ?)',
        [workerId, eventType, metadata ? JSON.stringify(metadata) : null],
    );
}

function startOfCurrentWeekSunday() {
    const now = new Date();
    const day = now.getDay();
    const sunday = new Date(now);
    sunday.setDate(now.getDate() - day);
    sunday.setHours(0, 0, 0, 0);
    return sunday.toISOString();
}

function startOfNextWeekSunday(fromDate = new Date()) {
    const base = new Date(fromDate);
    const day = base.getDay();
    const sunday = new Date(base);
    sunday.setDate(base.getDate() - day + 7);
    sunday.setHours(0, 0, 0, 0);
    return sunday.toISOString();
}

function computeDaysRemaining(policyStartIso) {
    if (!policyStartIso) return 0;
    const start = new Date(policyStartIso);
    const end = new Date(start);
    end.setDate(start.getDate() + 6);
    end.setHours(23, 59, 59, 999);
    const now = new Date();
    if (now > end) return 0;
    const ms = end.getTime() - now.getTime();
    return Math.max(0, Math.ceil(ms / (1000 * 60 * 60 * 24)));
}

function latestPaidDate(payoutHistory) {
    const paid = payoutHistory.filter((item) => item.status === 'paid');
    if (paid.length === 0) return null;
    const latest = paid.reduce((max, item) => {
        return new Date(item.eventDate) > new Date(max.eventDate) ? item : max;
    });
    return latest.eventDate;
}

function triggerReasonFromAlert(alert) {
    switch (alert.eventType) {
        case 'flood':
            return `Rain intensity currently ${alert.metrics?.rainMm ?? 0}mm in your zone.`;
        case 'heat':
            return `Current temperature is ${alert.metrics?.temperature ?? 0}C in your zone.`;
        case 'aqi':
            return `US AQI currently ${alert.metrics?.usAqi ?? 0} with elevated particulate load.`;
        default:
            return `Mobility stress score ${alert.metrics?.trafficScore ?? 0} detected for your zone.`;
    }
}

function payoutEventName(eventType) {
    switch (eventType) {
        case 'flood':
            return 'Heavy Rain / Flood';
        case 'heat':
            return 'Heatwave';
        case 'aqi':
            return 'AQI Spike';
        default:
            return 'Traffic Collapse';
    }
}

function buildPayoutHistory(triggerAlerts, worker, { isPolicyActive, onlineToday }) {
    const avgIncome = Number(worker.avg_daily_income) || 1200;
    const basePayout = avgIncome * 0.60;
    // Hard cap from README: min(0.75 × avg_daily_income, 1000)
    const maxPayout = Math.min(avgIncome * 0.75, 1000);

    return triggerAlerts.map((alert) => {
        const isTriggered = alert.zoneStatus === 'triggered';
        const severityFactor = alert.severity === 'catastrophic' ? 1.25 : (alert.severity === 'severe' ? 1.15 : 1.0);
        const eligible = isPolicyActive && onlineToday && isTriggered;

        let status = 'rejected';
        if (eligible && alert.eventType === 'aqi') {
            status = 'pending';
        } else if (eligible) {
            status = 'paid';
        }

        // Apply severity then enforce hard cap
        const rawAmount = basePayout * severityFactor;
        const cappedAmount = Math.min(rawAmount, maxPayout);

        return {
            eventType: payoutEventName(alert.eventType),
            eventDate: alert.timestamp,
            amount: eligible ? Number(cappedAmount.toFixed(0)) : 0,
            status,
            triggerReason: eligible
                ? triggerReasonFromAlert(alert)
                : 'Not eligible because policy is inactive, rider is offline, or zone is not triggered.',
            dataSource: alert.dataSource,
            eventId: alert.eventId,
        };
    });
}

exports.getState = async (req, res) => {
    try {
        const worker = await get(
            `SELECT
                id,
                full_name,
                phone,
                platform,
                upi_id,
                zone_name,
                zone_latitude,
                zone_longitude,
                zone_confirmed,
                online_today,
                policy_start,
                policy_premium,
                last_payment_at,
                next_payment_due_at,
                avg_daily_income,
                policies_purchased,
                payouts_settled,
                notif_event_alerts,
                notif_weekly_reminders,
                notif_payout_updates
            FROM workers
            WHERE id = ?`,
            [req.workerId],
        );

        if (!worker) {
            return res.status(404).json({ success: false, message: 'Worker not found.' });
        }

        const policyDaysRemaining = computeDaysRemaining(worker.policy_start);
        const isPolicyActive = policyDaysRemaining > 0;
        const workerZoneName = String(worker.zone_name || '').trim();

        const liveSignals = await fetchLiveSignals({
            zoneName: workerZoneName || 'Bengaluru',
            latitude: Number(worker.zone_latitude),
            longitude: Number(worker.zone_longitude),
        }).catch(() => ({
            location: {
                zoneLabel: workerZoneName || 'Your Area',
                latitude: Number(worker.zone_latitude),
                longitude: Number(worker.zone_longitude),
            },
            readings: {
                temperature: 0,
                rainMm: 0,
                usAqi: 0,
                pm25: 0,
                pm10: 0,
                trafficScore: 0.2,
            },
            riskFeed: [
                { label: 'Rain', level: 'Low', icon: 'R' },
                { label: 'Heat', level: 'Low', icon: 'H' },
                { label: 'AQI', level: 'Good', icon: 'A' },
                { label: 'Traffic', level: 'Normal', icon: 'T' },
            ],
            triggerAlerts: [],
        }));
        const resolvedZoneName = workerZoneName
            || String(liveSignals.location?.zoneLabel || '').trim()
            || 'Your Area';
        const resolvedLatitude = Number.isFinite(Number(worker.zone_latitude))
            ? Number(worker.zone_latitude)
            : Number(liveSignals.location?.latitude) || 0;
        const resolvedLongitude = Number.isFinite(Number(worker.zone_longitude))
            ? Number(worker.zone_longitude)
            : Number(liveSignals.location?.longitude) || 0;
        const activePolicy = isPolicyActive
            ? {
                weekStart: worker.policy_start,
                premiumPaid: worker.policy_premium || 40,
                zoneName: resolvedZoneName,
                status: 'active',
            }
            : null;

        const inferredTrustScore = Math.max(
            40,
            Math.min(
                98,
                58
                    + (Number(worker.policies_purchased) || 0) * 2
                    + (Number(worker.payouts_settled) || 0)
                    - (Number(worker.online_today) === 1 ? 0 : 8),
            ),
        );
        const inferredWorkingHours = Number(worker.online_today) === 1 ? 9 : 5;

        const premiumBreakdown = await scorePremiumWithML({
            zoneName: resolvedZoneName,
            readings: liveSignals.readings,
            trustScore: inferredTrustScore,
            workingHours: inferredWorkingHours,
        });
        const premiumTotal = worker.policy_premium || (
            premiumBreakdown.baseRate
            + premiumBreakdown.zoneRisk
            + premiumBreakdown.weatherVolatility
            + premiumBreakdown.mobilityRisk
            - premiumBreakdown.safetyDiscount
        );
        const payoutHistory = buildPayoutHistory(liveSignals.triggerAlerts, worker, {
            isPolicyActive,
            onlineToday: Number(worker.online_today) === 1,
        });
        const maxPayout = Math.min((Number(worker.avg_daily_income) || 1200) * 0.75, 1000);
        const payDue = isPolicyActive ? 0 : premiumTotal;
        const payDueDate = worker.next_payment_due_at || startOfNextWeekSunday();

        return res.json({
            success: true,
            data: {
                profile: {
                    name: worker.full_name || 'Rider',
                    phone: worker.phone,
                    platform: worker.platform || 'Other',
                    upiId: worker.upi_id || '',
                    zoneName: resolvedZoneName,
                    latitude: resolvedLatitude,
                    longitude: resolvedLongitude,
                    zoneRadius: 2.5,
                    policiesPurchased: worker.policies_purchased || 0,
                    payoutsSettled: worker.payouts_settled || 0,
                    avgSettlementSeconds: 258,
                },
                notificationPrefs: {
                    eventAlerts: Number(worker.notif_event_alerts) !== 0,
                    weeklyReminders: Number(worker.notif_weekly_reminders) !== 0,
                    payoutNotifs: Number(worker.notif_payout_updates) !== 0,
                },
                zoneConfirmed: Number(worker.zone_confirmed) === 1,
                onlineToday: Number(worker.online_today) === 1,
                activePolicy,
                premiumBreakdown,
                insuranceMeta: {
                    productType: 'Weekly parametric income protection',
                    coverageWindow: 'Sunday 00:00 to Saturday 23:59',
                    claimMethod: 'Zero-touch settlement',
                    exclusions: [
                        'Health events',
                        'Personal accidents',
                        'Vehicle breakdown',
                        'Fuel cost increases',
                        'Voluntary inactivity',
                        'Platform suspension',
                    ],
                    payoutFormula: 'Payout = (FRB x Sm) + IRB',
                    maxPayout,
                },
                paymentSummary: {
                    lastPayDate: worker.last_payment_at,
                    lastPayoutDate: latestPaidDate(payoutHistory),
                    daysRemaining: policyDaysRemaining,
                    payAmount: premiumTotal,
                    payDue,
                    payDueDate,
                },
                riskFeed: liveSignals.riskFeed,
                triggerAlerts: liveSignals.triggerAlerts,
                payoutHistory,
            },
        });
    } catch (error) {
        console.error('getState error', error);
        return res.status(500).json({ success: false, message: 'Internal server error.' });
    }
};

exports.confirmZone = async (req, res) => {
    try {
        const { zoneName, latitude, longitude } = req.body;
        const lat = Number(latitude);
        const lon = Number(longitude);
        if (!zoneName || !Number.isFinite(lat) || !Number.isFinite(lon)) {
            return res.status(400).json({ success: false, message: 'zoneName, latitude and longitude are required.' });
        }

        await run(
            'UPDATE workers SET zone_name = ?, zone_latitude = ?, zone_longitude = ?, zone_confirmed = 1 WHERE id = ?',
            [zoneName, lat, lon, req.workerId],
        );
        await recordActivity(req.workerId, 'zone_confirmed', { zoneName, latitude: lat, longitude: lon });

        return res.json({ success: true });
    } catch (error) {
        console.error('confirmZone error', error);
        return res.status(500).json({ success: false, message: 'Internal server error.' });
    }
};

exports.purchasePolicy = async (req, res) => {
    try {
        const { premiumPaid = 40 } = req.body;
        const now = new Date().toISOString();
        const weekStart = startOfCurrentWeekSunday();
        const nextDue = startOfNextWeekSunday();
        await run(
            `UPDATE workers
             SET policy_start = ?, policy_premium = ?, last_payment_at = ?, next_payment_due_at = ?,
                 policies_purchased = COALESCE(policies_purchased, 0) + 1
             WHERE id = ?`,
            [weekStart, premiumPaid, now, nextDue, req.workerId],
        );
        await recordActivity(req.workerId, 'policy_purchased', { premiumPaid, weekStart });

        return res.json({ success: true });
    } catch (error) {
        console.error('purchasePolicy error', error);
        return res.status(500).json({ success: false, message: 'Internal server error.' });
    }
};

exports.setOnlineIntent = async (req, res) => {
    try {
        const { onlineToday } = req.body;
        if (typeof onlineToday !== 'boolean') {
            return res.status(400).json({ success: false, message: 'onlineToday must be a boolean.' });
        }

        await run(
            'UPDATE workers SET online_today = ? WHERE id = ?',
            [onlineToday ? 1 : 0, req.workerId],
        );
        await recordActivity(req.workerId, 'online_intent_changed', { onlineToday });

        return res.json({ success: true });
    } catch (error) {
        console.error('setOnlineIntent error', error);
        return res.status(500).json({ success: false, message: 'Internal server error.' });
    }
};

exports.updateProfile = async (req, res) => {
    try {
        const {
            fullName,
            platform,
            upiId,
            zoneName,
        } = req.body;

        const normalizedName = String(fullName || '').trim();
        const normalizedPlatform = String(platform || '').trim();
        const normalizedUpi = String(upiId || '').trim();
        const normalizedZone = String(zoneName || '').trim();

        if (!normalizedName || !normalizedPlatform || !normalizedUpi) {
            return res.status(400).json({
                success: false,
                message: 'fullName, platform and upiId are required.',
            });
        }

        if (!/^[\w.+-]{2,}@[\w.-]{2,}$/.test(normalizedUpi)) {
            return res.status(400).json({ success: false, message: 'Invalid UPI ID format.' });
        }

        await run(
            `UPDATE workers
             SET full_name = ?, platform = ?, upi_id = ?, zone_name = COALESCE(NULLIF(?, ''), zone_name)
             WHERE id = ?`,
            [normalizedName, normalizedPlatform, normalizedUpi, normalizedZone, req.workerId],
        );

        await recordActivity(req.workerId, 'profile_updated', {
            fullName: normalizedName,
            platform: normalizedPlatform,
            hasZoneUpdate: normalizedZone.length > 0,
        });

        return res.json({ success: true });
    } catch (error) {
        console.error('updateProfile error', error);
        return res.status(500).json({ success: false, message: 'Internal server error.' });
    }
};

exports.updateLocation = async (req, res) => {
    try {
        const { zoneName, latitude, longitude } = req.body;
        const normalizedZone = String(zoneName || '').trim();
        const lat = Number(latitude);
        const lon = Number(longitude);

        if (!normalizedZone || !Number.isFinite(lat) || !Number.isFinite(lon)) {
            return res.status(400).json({
                success: false,
                message: 'zoneName, latitude and longitude are required.',
            });
        }

        await run(
            `UPDATE workers
             SET zone_name = ?, zone_latitude = ?, zone_longitude = ?, zone_confirmed = 1
             WHERE id = ?`,
            [normalizedZone, lat, lon, req.workerId],
        );

        await recordActivity(req.workerId, 'location_updated', {
            zoneName: normalizedZone,
            latitude: lat,
            longitude: lon,
        });

        return res.json({ success: true });
    } catch (error) {
        console.error('updateLocation error', error);
        return res.status(500).json({ success: false, message: 'Internal server error.' });
    }
};

exports.updateNotificationPreferences = async (req, res) => {
    try {
        const {
            eventAlerts,
            weeklyReminders,
            payoutNotifs,
        } = req.body;

        if (
            typeof eventAlerts !== 'boolean'
            || typeof weeklyReminders !== 'boolean'
            || typeof payoutNotifs !== 'boolean'
        ) {
            return res.status(400).json({
                success: false,
                message: 'eventAlerts, weeklyReminders and payoutNotifs must be booleans.',
            });
        }

        await run(
            `UPDATE workers
             SET notif_event_alerts = ?, notif_weekly_reminders = ?, notif_payout_updates = ?
             WHERE id = ?`,
            [eventAlerts ? 1 : 0, weeklyReminders ? 1 : 0, payoutNotifs ? 1 : 0, req.workerId],
        );

        await recordActivity(req.workerId, 'notification_preferences_updated', {
            eventAlerts,
            weeklyReminders,
            payoutNotifs,
        });

        return res.json({ success: true });
    } catch (error) {
        console.error('updateNotificationPreferences error', error);
        return res.status(500).json({ success: false, message: 'Internal server error.' });
    }
};
