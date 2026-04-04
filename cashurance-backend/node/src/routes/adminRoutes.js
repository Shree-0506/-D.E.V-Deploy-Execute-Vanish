const express = require('express');
const adminController = require('../controllers/adminController');
const { requireAdminAuth } = require('../middleware/adminAuth');

const router = express.Router();

router.post('/auth/login', adminController.login);
router.post('/auth/logout', requireAdminAuth, adminController.logout);

router.get('/dashboard', requireAdminAuth, adminController.dashboard);
router.get('/workers', requireAdminAuth, adminController.listWorkers);
router.get('/workers/:id/history', requireAdminAuth, adminController.workerHistory);
router.get('/workers/:id/activity', requireAdminAuth, adminController.workerActivity);
router.patch('/workers/:id/status', requireAdminAuth, adminController.updateWorkerStatus);
router.get('/activity/feed', requireAdminAuth, adminController.listActivityFeed);

router.get('/triggers', requireAdminAuth, adminController.listTriggers);
router.get('/payouts', requireAdminAuth, adminController.listPayouts);
router.post('/payouts/:id/action', requireAdminAuth, adminController.updatePayoutStatus);

router.get('/fraud-alerts', requireAdminAuth, adminController.listFraudAlerts);
router.post('/fraud-alerts/:id/action', requireAdminAuth, adminController.updateFraudStatus);

module.exports = router;
