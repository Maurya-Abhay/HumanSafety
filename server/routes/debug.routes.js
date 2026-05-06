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
 * Debug endpoint to create a test user (FOR TESTING ONLY)
 * Usage: POST /debug/create-test-user
 * Body: { phone: "2222222222", password: "Test@1234", name: "Test User" }
 */
router.post('/create-test-user', async (req, res) => {
  try {
    const { phone, password = 'Test@1234', name = 'Test User' } = req.body;

    if (!phone) {
      return res.status(400).json({
        success: false,
        message: 'phone in body is required',
      });
    }

    let user = await User.findOne({ phone });

    if (user) {
      return res.status(409).json({
        success: false,
        message: 'User already exists',
        data: { phone, userId: user._id },
      });
    }

    user = await User.create({
      phone,
      password,
      name,
      email: `test-${phone}@example.com`,
      status: 'active',
      isActive: true,
      isBlocked: false,
    });

    return res.status(201).json({
      success: true,
      message: `Test user created`,
      data: {
        phone: user.phone,
        userId: user._id,
        name: user.name,
        password: password, // ⚠️ For testing only!
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error creating test user',
      error: error.message,
    });
  }
});

module.exports = router;
