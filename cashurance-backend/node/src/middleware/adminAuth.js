const { getSession } = require('../config/sessionStore');

function requireAdminAuth(req, res, next) {
    const authHeader = req.headers.authorization || '';
    const [scheme, token] = authHeader.split(' ');

    if (scheme !== 'Bearer' || !token) {
        return res.status(401).json({ success: false, message: 'Missing admin auth token.' });
    }

    const session = getSession(token);
    if (!session || session.type !== 'admin' || !session.email) {
        return res.status(401).json({ success: false, message: 'Invalid or expired admin session.' });
    }

    req.authToken = token;
    req.adminEmail = session.email;
    next();
}

module.exports = {
    requireAdminAuth,
};
