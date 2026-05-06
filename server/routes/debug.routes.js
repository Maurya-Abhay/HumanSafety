const express = require('express');
const User = require('../models/user.model');

const router = express.Router();

/**
 * Debug endpoint to check CORS configuration
 * Usage: GET /debug/cors-config
 */
router.get('/cors-config', (req, res) => {
  const allowedOrigins = (process.env.CORS_ORIGIN || 'http://localhost:3000')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);

  return res.status(200).json({
    success: true,
    data: {
      allowedOrigins,
      localDevOriginRegex: '^https?://(localhost|127.0.0.1)(:\\d+)?$',
      incomingOrigin: req.get('origin') || 'no origin header',
      incomingReferer: req.get('referer') || 'no referer header',
      note: 'Localhost and 127.0.0.1 with any port are always allowed',
    },
  });
});

/**
 * Debug endpoint to check user status
 * Usage: GET /debug/user-status?phone=2222222222
 */
router.get('/user-status', async (req, res) => {
  try {
    const { phone } = req.query;

    if (!phone) {
      return res.status(400).json({
        success: false,
        message: 'phone query parameter required',
      });
    }

    const user = await User.findOne({ phone });

    if (!user) {
      return res.status(200).json({
        success: true,
        data: {
          phone,
          exists: false,
          message: 'User does not exist',
        },
      });
    }

    return res.status(200).json({
      success: true,
      data: {
        phone,
        exists: true,
        id: user._id,
        name: user.name || 'N/A',
        email: user.email || 'N/A',
        role: user.role || 'user',
        status: user.status || 'active',
        isActive: user.isActive,
        isBlocked: user.isBlocked,
        blockReason: user.blockReason,
        hasPassword: !!user.password,
        createdAt: user.createdAt,
        lastLogin: user.lastLogin,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error checking user status',
      error: error.message,
    });
  }
});

/**
 * Debug endpoint to unblock a user (FOR TESTING ONLY)
 * Usage: POST /debug/unblock-user
 * Body: { phone: "2222222222" }
 */
router.post('/unblock-user', async (req, res) => {
  try {
    const { phone } = req.body;

    if (!phone) {
      return res.status(400).json({
        success: false,
        message: 'phone in body is required',
      });
    }

    const user = await User.findOneAndUpdate(
      { phone },
      {
        isBlocked: false,
        blockReason: null,
      },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    return res.status(200).json({
      success: true,
      message: `User ${phone} unblocked`,
      data: {
        phone: user.phone,
        isBlocked: user.isBlocked,
        blockReason: user.blockReason,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error unblocking user',
      error: error.message,
    });
  }
});

/**
 * Debug endpoint to create and immediately verify a test user
 * Usage: POST /debug/create-test-user
 * Body: { phone: "1234567890", password: "Test@1234" }
 */
router.post('/create-test-user', async (req, res) => {
  try {
    const { phone, password = 'Test@1234' } = req.body;

    if (!phone) {
      return res.status(400).json({
        success: false,
        message: 'phone in body is required',
      });
    }

    // Delete existing user to start fresh
    await User.deleteOne({ phone });

    // Create new user
    const user = await User.create({
      phone,
      password,
      name: `Test User ${phone}`,
      email: `test-${phone}@example.com`,
      status: 'active',
      isActive: true,
      isBlocked: false,
    });

    console.info(`✅ User created: ${phone}, userId=${user._id}, hasPassword=${!!user.password}`);

    // Immediately test password comparison
    const isMatch = await user.comparePassword(password);
    console.info(`🔐 Password comparison result: ${isMatch}`);

    if (!isMatch) {
      return res.status(500).json({
        success: false,
        message: 'Password comparison failed after creation',
        data: { phone, passwordStored: !!user.password, passwordMatches: isMatch },
      });
    }

    // Generate token (simulate login)
    const jwt = require('jsonwebtoken');
    const token = jwt.sign(
      { userId: user._id, phone: user.phone },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    return res.status(201).json({
      success: true,
      message: `User created and verified. Use these credentials to login:`,
      data: {
        phone,
        password: password,
        userId: user._id,
        token: token.substring(0, 30) + '...',
        passwordMatches: true,
      },
    });
  } catch (error) {
    console.error(`❌ Setup error: ${error.message}`);
    return res.status(500).json({
      success: false,
      message: 'Error creating test user',
      error: error.message,
    });
  }
});

module.exports = router;
