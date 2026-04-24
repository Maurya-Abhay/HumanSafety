const jwt = require('jsonwebtoken');
const User = require('../models/user.model');
const Settings = require('../models/settings.model');
const { generateOTP, storeOTP, verifyOTP } = require('../services/otp.service');
const { sendSMS } = require('../services/sms.service');

const sendOTP = async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) return res.status(400).json({ success: false, message: 'Phone required' });
    
    const otp = generateOTP();
    storeOTP(phone, otp);
    await sendSMS(phone, `Your HumanSafety OTP is: ${otp}`);
    
    res.status(200).json({ success: true, message: 'OTP sent', phone });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to send OTP', error: error.message });
  }
};

const verifyOTPAndLogin = async (req, res) => {
  try {
    const { phone, otp } = req.body;
    if (!phone || !otp) return res.status(400).json({ message: 'Phone and OTP required' });
    
    const check = verifyOTP(phone, otp);
    if (!check.valid) return res.status(400).json({ message: check.message });
    
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
      { expiresIn: process.env.JWT_EXPIRE }
    );
    
    res.status(200).json({
      message: 'Login successful',
      token,
      user: { id: user._id, phone: user.phone, name: user.name },
    });
  } catch (error) {
    res.status(500).json({ message: 'Login failed', error: error.message });
  }
};

const logout = async (req, res) => {
  try {
    res.status(200).json({ message: 'Logout successful' });
  } catch (error) {
    res.status(500).json({ message: 'Logout failed', error: error.message });
  }
};

const signup = async (req, res) => {
  try {
    const { fullName, phone, email, password } = req.body;
    
    // Validate required fields
    if (!fullName || !phone) {
      return res.status(400).json({ message: 'Full name and phone are required' });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ phone });
    if (existingUser) {
      return res.status(400).json({ message: 'User with this phone already exists' });
    }

    // Create new user
    const user = await User.create({
      phone,
      name: fullName,
      email: email || '',
      password: password || '', // Will be hashed by pre-save hook if provided
    });

    // Create default settings
    await Settings.create({ userId: user._id });

    res.status(201).json({
      message: 'Account created successfully. Please verify with OTP.',
      user: {
        id: user._id,
        phone: user.phone,
        name: user.name,
        email: user.email,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to create account', error: error.message });
  }
};

module.exports = { sendOTP, verifyOTPAndLogin, logout, signup };
