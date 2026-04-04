const { getSession } = require('../config/sessionStore');
const db = require('../config/database');

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

async function requireAuth(req, res, next) {
    const authHeader = req.headers.authorization || '';
    const [scheme, token] = authHeader.split(' ');

    if (scheme !== 'Bearer' || !token) {
        return res.status(401).json({ success: false, message: 'Missing auth token.' });
    }

    const session = getSession(token);
    if (!session || session.type !== 'worker' || !session.workerId) {
        return res.status(401).json({ success: false, message: 'Invalid or expired session.' });
    }

    try {
        const worker = await get('SELECT status FROM workers WHERE id = ?', [session.workerId]);
        if (!worker) {
            return res.status(401).json({ success: false, message: 'Invalid session worker.' });
        }
        if (String(worker.status || '').toUpperCase() === 'SUSPENDED') {
            return res.status(403).json({
                success: false,
                message: 'Account is restricted. Please contact support.',
            });
        }
    } catch (error) {
        console.error('requireAuth status check error', error);
        return res.status(500).json({ success: false, message: 'Internal server error.' });
    }

    req.authToken = token;
    req.workerId = session.workerId;
    next();
}

module.exports = {
    requireAuth,
};
