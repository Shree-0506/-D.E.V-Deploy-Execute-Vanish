const crypto = require('crypto');
const db = require('../config/database');
const { createSession, deleteSession } = require('../config/sessionStore');

const MAX_LOGIN_DISTANCE_KM = 100;
const TEST_USER_PHONE = '9999999999';
const TEST_USER_PASSWORD = 'abcdef';

function hashPassword(value) {
    return crypto.createHash('sha256').update(value).digest('hex');
}

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

function recordActivity(workerId, eventType, metadata = null) {
    return run(
        'INSERT INTO activity_logs (worker_id, event_type, metadata) VALUES (?, ?, ?)',
        [workerId, eventType, metadata ? JSON.stringify(metadata) : null],
    );
}

function toRadians(degrees) {
    return (degrees * Math.PI) / 180;
}

function distanceKm(lat1, lon1, lat2, lon2) {
    const R = 6371;
    const dLat = toRadians(lat2 - lat1);
    const dLon = toRadians(lon2 - lon1);
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
        + Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2))
        * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

exports.register = async (req, res) => {
    try {
        const {
            full_name,
            phone,
            password,
            dob = null,
            address = null,
            pincode = null,
            platform = 'Other',
            platform_worker_id = null,
            upi_id = '',
                zone_name = '',
        } = req.body;

        if (!full_name || !phone || !password) {
            return res.status(400).json({
                success: false,
                message: 'full_name, phone and password are required.',
            });
        }

        const normalizedPhone = String(phone).trim();
            const normalizedZoneName = String(zone_name || '').trim();
        const pwdHash = hashPassword(String(password));

        const result = await run(
            `INSERT INTO workers (
                full_name,
                phone,
                password_hash,
                dob,
                address,
                pincode,
                platform,
                platform_worker_id,
                upi_id,
                status,
                zone_name,
                zone_confirmed,
                online_today,
                policies_purchased,
                payouts_settled
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVE', ?, 0, 1, 0, 0)`,
            [
                full_name,
                normalizedPhone,
                pwdHash,
                dob,
                address,
                pincode,
                platform,
                platform_worker_id,
                upi_id,
                    normalizedZoneName,
            ],
        );

        return res.status(201).json({
            success: true,
            message: 'Registration complete.',
            data: {
                worker_id: result.lastID,
            },
        });
    } catch (error) {
        if (error.message && error.message.includes('UNIQUE constraint failed')) {
            return res.status(400).json({
                success: false,
                message: 'Phone number already registered.',
            });
        }
        console.error('register error', error);
        return res.status(500).json({ success: false, message: 'Internal server error.' });
    }
};

exports.login = async (req, res) => {
    try {
        const { phone, password, latitude, longitude } = req.body;
        if (!phone || !password) {
            return res.status(400).json({
                success: false,
                message: 'phone and password are required.',
            });
        }

        const normalizedPhone = String(phone).trim();
        const isTestCredentials = (
            normalizedPhone === TEST_USER_PHONE
            && String(password) === TEST_USER_PASSWORD
        );

        let row = await get(
            `SELECT
                id,
                full_name,
                phone,
                password_hash,
                zone_confirmed,
                zone_name,
                zone_latitude,
                zone_longitude,
                status
             FROM workers
             WHERE phone = ?`,
            [normalizedPhone],
        );

        if (!row && isTestCredentials) {
            await run(
                `INSERT INTO workers (
                    full_name,
                    phone,
                    password_hash,
                    platform,
                    upi_id,
                    status,
                    zone_name,
                    zone_confirmed,
                    online_today,
                    policies_purchased,
                    payouts_settled
                ) VALUES (?, ?, ?, 'Other', '', 'ACTIVE', '', 1, 1, 0, 0)`,
                ['Test Rider', TEST_USER_PHONE, hashPassword(TEST_USER_PASSWORD)],
            );

            row = await get(
                `SELECT
                    id,
                    full_name,
                    phone,
                    password_hash,
                    zone_confirmed,
                    zone_name,
                    zone_latitude,
                    zone_longitude,
                    status
                 FROM workers
                 WHERE phone = ?`,
                [normalizedPhone],
            );
        }

        if (!row || !row.password_hash || row.password_hash !== hashPassword(String(password))) {
            return res.status(401).json({ success: false, message: 'Invalid credentials.' });
        }

        if (String(row.status || '').toUpperCase() === 'SUSPENDED') {
            return res.status(403).json({
                success: false,
                message: 'Account is restricted. Please contact support.',
            });
        }

        const firstTimeSetup = Number(row.zone_confirmed) === 0;
        const bypassLocationRestriction = isTestCredentials;
        const loginLatitude = Number(latitude);
        const loginLongitude = Number(longitude);
        const hasLoginLocation = Number.isFinite(loginLatitude) && Number.isFinite(loginLongitude);

        if (!firstTimeSetup && !bypassLocationRestriction) {
            if (!hasLoginLocation) {
                return res.status(403).json({
                    success: false,
                    message: 'Location verification required at login. Please enable location permission.',
                });
            }

            const registeredLatitude = Number(row.zone_latitude);
            const registeredLongitude = Number(row.zone_longitude);
            const canVerifyRegistered = Number.isFinite(registeredLatitude) && Number.isFinite(registeredLongitude);

            if (canVerifyRegistered) {
                const km = distanceKm(
                    registeredLatitude,
                    registeredLongitude,
                    loginLatitude,
                    loginLongitude,
                );
                if (km > MAX_LOGIN_DISTANCE_KM) {
                    return res.status(403).json({
                        success: false,
                        message: 'Out of your region, please contact admin to change your location.',
                    });
                }
            }
        }

        const token = createSession({
            type: 'worker',
            workerId: row.id,
        });
        await recordActivity(row.id, 'worker_logged_in', {
            firstTimeSetup,
            bypassLocationRestriction,
            latitude: hasLoginLocation ? loginLatitude : null,
            longitude: hasLoginLocation ? loginLongitude : null,
        });
        return res.json({
            success: true,
            data: {
                token,
                worker_id: row.id,
                full_name: row.full_name,
                phone: row.phone,
                first_time_setup: firstTimeSetup,
            },
        });
    } catch (error) {
        console.error('login error', error);
        return res.status(500).json({ success: false, message: 'Internal server error.' });
    }
};

exports.logout = (req, res) => {
    Promise.resolve()
        .then(() => {
            if (req.workerId) {
                return recordActivity(req.workerId, 'worker_logged_out');
            }
            return null;
        })
        .catch((error) => {
            console.error('logout activity log error', error);
        })
        .finally(() => {
            if (req.authToken) {
                deleteSession(req.authToken);
            }
            res.json({ success: true });
        });
};
