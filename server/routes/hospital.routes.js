const express = require('express');
const { requestHospital, getNearbyHospitals } = require('../controllers/hospital.controller');
const { verifyToken } = require('../middleware/auth.middleware');

const router = express.Router();

router.post('/request', verifyToken, requestHospital);
router.get('/nearby', verifyToken, getNearbyHospitals);

module.exports = router;
