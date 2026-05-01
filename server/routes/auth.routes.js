const express = require('express');
const { 
  sendOTP, 
  verifyOTPAndLogin, 
  signup, 
  logout,
  loginWithPassword,   // 👈 ADD
  refreshToken         // 👈 ADD
} = require('../controllers/auth.controller');

const { validateSendOTP, validateVerifyOTP } = require('../middleware/validation.middleware');
const { verifyToken } = require('../middleware/auth.middleware');

const router = express.Router();


// ================== PASSWORD LOGIN (MAIN) ==================
router.post('/login', loginWithPassword);


// ================== SIGNUP ==================
router.post('/signup', signup);


// ================== OTP (OPTIONAL - FUTURE USE) ==================
router.post('/send-otp', validateSendOTP, sendOTP);
router.post('/verify-otp', validateVerifyOTP, verifyOTPAndLogin);


// ================== TOKEN REFRESH ==================
router.post('/refresh-token', refreshToken);


// ================== LOGOUT ==================
router.post('/logout', verifyToken, logout);


module.exports = router;