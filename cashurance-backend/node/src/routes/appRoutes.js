const express = require('express');
const { requireAuth } = require('../middleware/auth');
const appController = require('../controllers/appController');

const router = express.Router();

router.get('/state', requireAuth, appController.getState);
router.post('/zone/confirm', requireAuth, appController.confirmZone);
router.post('/policy/purchase', requireAuth, appController.purchasePolicy);
router.post('/intent', requireAuth, appController.setOnlineIntent);
router.patch('/profile', requireAuth, appController.updateProfile);
router.patch('/location', requireAuth, appController.updateLocation);
router.put('/notifications/preferences', requireAuth, appController.updateNotificationPreferences);

module.exports = router;
