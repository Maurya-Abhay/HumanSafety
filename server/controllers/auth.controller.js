const jwt = require('jsonwebtoken');
const User = require('../models/user.model');
const Settings = require('../models/settings.model');
const { generateOTP, storeOTP, verifyOTP } = require('../services/otp.service');
const { sendSMS } = require('../services/sms.service');


// ================== OTP (OPTIONAL - FUTURE USE) ==================

const sendOTP = async (req, res) => {
  try {
    const { phone } = req.body;

    if (!phone) {
      return res.status(400).json({ success: false, message: 'Phone required' });
    }

    const otp = generateOTP();
    storeOTP(phone, otp);

    await sendSMS(phone, `Your HumanSafety OTP is: ${otp}`);

    res.status(200).json({
      success: true,
      message: 'OTP sent',
      phone,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to send OTP',
      error: error.message,
    });
  }
};


const verifyOTPAndLogin = async (req, res) => {
  try {
    const { phone, otp } = req.body;

    if (!phone || !otp) {
      return res.status(400).json({ message: 'Phone and OTP required' });
    }

    const check = verifyOTP(phone, otp);
    if (!check.valid) {
      return res.status(400).json({ message: check.message });
    }

    let user = await User.findOne({ phone });

    if (!user) {
      user = await User.create({ phone });
      await Settings.create({ userId: user._id });
    }

    user.lastLogin = new Date();
    await user.save();

    const token = jwt.sign(
      { userId: user._id, phone: user.phone },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    res.status(200).json({
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        phone: user.phone,
        name: user.name,
        email: user.email,
      },
    });

  } catch (error) {
    res.status(500).json({
      message: 'Login failed',
      error: error.message,
    });
  }
};


// ================== PASSWORD LOGIN (MAIN) ==================

const loginWithPassword = async (req, res) => {
  try {
    const { phone, password } = req.body;

    if (!phone || !password) {
      return res.status(400).json({ message: 'Phone and password required' });
    }

    const user = await User.findOne({ phone });

    if (!user) {
      return res.status(400).json({ message: 'User not found' });
    }

    if (!user.password) {
      return res.status(400).json({
        message: 'Please signup with password first',
      });
    }

    if (user.isBlocked) {
      return res.status(403).json({ message: 'User is blocked' });
    }

    const isMatch = await user.comparePassword(password);

    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid password' });
    }

    user.lastLogin = new Date();
    await user.save();

    const token = jwt.sign(
      { userId: user._id, phone: user.phone },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    res.status(200).json({
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        phone: user.phone,
        name: user.name,
        email: user.email,
      },
    });

  } catch (error) {
    res.status(500).json({
      message: 'Login failed',
      error: error.message,
    });
  }
};


// ================== SIGNUP ==================

const signup = async (req, res) => {
  try {
    const { fullName, phone, email, password } = req.body;

    if (!fullName || !phone || !email || !password) {
      return res.status(400).json({
        message: 'Full name, phone, email and password are required',
      });
    }

    const existingUser = await User.findOne({ phone });

    if (existingUser) {
      return res.status(400).json({
        message: 'User with this phone already exists',
      });
    }

    const user = await User.create({
      phone,
      name: fullName,
      email: email,
      password,
    });

    await Settings.create({ userId: user._id });

    const token = jwt.sign(
      { userId: user._id, phone: user.phone },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    res.status(201).json({
      message: 'Account created successfully',
      token,
      user: {
        id: user._id,
        phone: user.phone,
        name: user.name,
        email: user.email,
      },
    });

  } catch (error) {
    res.status(500).json({
      message: 'Failed to create account',
      error: error.message,
    });
  }
};


// ================== LOGOUT ==================

const logout = async (req, res) => {
  try {
    res.status(200).json({
      message: 'Logout successful',
    });
  } catch (error) {
    res.status(500).json({
      message: 'Logout failed',
      error: error.message,
    });
  }
};


// ================== EXPORT ==================

module.exports = {
  sendOTP,
  verifyOTPAndLogin,
  loginWithPassword, // 👈 MAIN LOGIN
  signup,
  logout,
};