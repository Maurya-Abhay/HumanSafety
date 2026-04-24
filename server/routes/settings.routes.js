const express = require('express');
const { getSettings, updateSettings } = require('../controllers/settings.controller');
const { verifyToken } = require('../middleware/auth.middleware');

const router = express.Router();

router.get('/', verifyToken, getSettings);
router.put('/update', verifyToken, updateSettings);

module.exports = router;
