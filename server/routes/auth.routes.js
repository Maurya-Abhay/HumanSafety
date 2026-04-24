const express = require('express');
const { sendOTP, verifyOTPAndLogin, logout, signup } = require('../controllers/auth.controller');
const { validateSendOTP, validateVerifyOTP } = require('../middleware/validation.middleware');
const { verifyToken } = require('../middleware/auth.middleware');

const router = express.Router();

// POST /auth/send-otp - Send OTP to phone and email
router.post('/send-otp', validateSendOTP, sendOTP);

// POST /auth/verify-otp - Verify OTP and login
router.post('/verify-otp', validateVerifyOTP, verifyOTPAndLogin);

// POST /auth/signup - Create new user account
router.post('/signup', signup);

// POST /auth/logout - Logout (requires auth)
router.post('/logout', verifyToken, logout);

module.exports = router;
