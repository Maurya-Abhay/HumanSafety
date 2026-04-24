const express = require('express');
const { requestHelp, acceptHelp, rejectHelp, completeHelp } = require('../controllers/help.controller');
const { verifyToken } = require('../middleware/auth.middleware');

const router = express.Router();

router.post('/request', verifyToken, requestHelp);
router.post('/accept', verifyToken, acceptHelp);
router.post('/reject', verifyToken, rejectHelp);
router.post('/complete', verifyToken, completeHelp);

module.exports = router;
