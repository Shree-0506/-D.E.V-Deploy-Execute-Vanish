const crypto = require('crypto');

const sessions = new Map();

function createSession(sessionData) {
    const token = crypto.randomUUID();
    sessions.set(token, {
        ...sessionData,
        createdAt: Date.now(),
    });
    return token;
}

function getSession(token) {
    return sessions.get(token);
}

function deleteSession(token) {
    sessions.delete(token);
}

module.exports = {
    createSession,
    getSession,
    deleteSession,
};
