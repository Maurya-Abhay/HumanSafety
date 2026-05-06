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
      return res.apiError('Phone number is required', error, 400, 'VALIDATION_FAILED');
    }

    const otp = generateOTP();
    storeOTP(phone, otp);

    await sendSMS(phone, `Your HumanSafety OTP is: ${otp}`);

    return res.apiSuccess({ phone, message: 'OTP sent to your phone' }, 'OTP sent successfully', 200);

  } catch (error) {
    return res.apiError('Failed to send OTP', error, 500, 'OTP_SEND_FAILED');
  }
};


const verifyOTPAndLogin = async (req, res) => {
  try {
    const { phone, otp } = req.body;

    if (!phone || !otp) {
      return res.apiError('Phone and OTP are required', null, 400, 'VALIDATION_FAILED');
    }

    const check = verifyOTP(phone, otp);
    if (!check.valid) {
      return res.apiError(check.message || 'Invalid OTP', null, 400, 'INVALID_OTP');
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

    return res.apiSuccess({
      token,
      user: {
        id: user._id,
        phone: user.phone,
        name: user.name,
        email: user.email,
        role: user.role || 'user',
        status: user.status || 'active',
      },
    }, 'Login successful', 200);

  } catch (error) {
    return res.apiError('OTP verification failed', error, 500, 'OTP_LOGIN_FAILED');
  }
};


// ================== PASSWORD LOGIN (MAIN) ==================

const loginWithPassword = async (req, res) => {
  try {
    // Helpful debug logs to diagnose 4xx responses during integration
    console.info(`LOGIN_ATTEMPT: origin=${req.get('origin') || req.get('referer') || 'unknown'} body=${JSON.stringify(req.body)}`);

    const { phone, password } = req.body;

    if (!phone || !password) {
      return res.apiError('Phone and password are required', null, 400, 'VALIDATION_FAILED');
    }

    const user = await User.findOne({ phone });
    console.info(`LOGIN_DEBUG: userFound=${!!user}`);

    if (!user) {
      return res.apiError('User not found', null, 404, 'USER_NOT_FOUND');
    }

    if (!user.password) {
      return res.apiError('Please signup with password first', null, 400, 'NO_PASSWORD_SET');
    }

    if (user.isBlocked) {
      console.warn(`LOGIN_BLOCKED: phone=${phone} blocked=${user.isBlocked} reason=${user.blockReason}`);
      return res.apiError('User account is blocked', null, 403, 'USER_BLOCKED');
    }

    const isMatch = await user.comparePassword(password);

    if (!isMatch) {
      return res.apiError('Invalid password', null, 401, 'INVALID_PASSWORD');
    }

    user.lastLogin = new Date();
    await user.save();

    const token = jwt.sign(
      { userId: user._id, phone: user.phone },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    const response = {
      token,
      user: {
        id: user._id,
        phone: user.phone,
        name: user.name,
        email: user.email,
        role: user.role,
        status: user.status,
      },
    };

    console.info(`LOGIN_SUCCESS: phone=${phone} token=${token.substring(0, 20)}... response=${JSON.stringify(response)}`);

    return res.apiSuccess(response, 'Login successful', 200);

  } catch (error) {
    return res.apiError('Login failed', error, 500, 'LOGIN_FAILED');
  }
};


// ================== SIGNUP ==================

const signup = async (req, res) => {
  try {
    const { fullName, phone, email, password } = req.body;

    if (!fullName || !phone || !email || !password) {
      return res.apiError('Name, phone, email and password are required', null, 400, 'VALIDATION_FAILED');
    }

    const existingUser = await User.findOne({ phone });

    if (existingUser) {
      return res.apiError('User with this phone already exists', null, 409, 'DUPLICATE_ENTRY');
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

    return res.apiSuccess({
      token,
      user: {
        id: user._id,
        phone: user.phone,
        name: user.name,
        email: user.email,
      },
    }, 'Account created successfully', 201);

  } catch (error) {
    return res.apiError(
      'Failed to create account', error, 500, 'SIGNUP_FAILED');
  }
};


// ================== LOGOUT ==================

const logout = async (req, res) => {
  try {
    return res.apiSuccess({}, 'Logout successful', 200);
  } catch (error) {
    return res.apiError('Logout failed', error, 500, 'LOGOUT_FAILED');
  }
};


// ================== REFRESH TOKEN ==================

/**
 * Refresh JWT token before expiry
 * Usage: Call this when token is about to expire (< 5 minutes left)
 */
const refreshToken = async (req, res) => {
  try {
    const { token } = req.body;

    if (!token) {
      return res.apiError('Token is required', null, 400, 'NO_TOKEN');
    }

    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (err) {
      try {
        decoded = jwt.decode(token);
        if (!decoded) {
          return res.apiError('Invalid token', null, 401, 'INVALID_TOKEN');
        }
      } catch (e) {
        return res.apiError('Invalid token format', null, 401, 'INVALID_TOKEN');
      }
    }

    const user = await User.findById(decoded.userId);

    if (!user || !user.isActive) {
      return res.apiError('User not found or inactive', null, 401, 'USER_NOT_FOUND');
    }

    const newToken = jwt.sign(
      { userId: user._id, phone: user.phone },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    return res.apiSuccess({
      token: newToken,
      expiresIn: process.env.JWT_EXPIRE || '7d',
      user: {
        id: user._id,
        phone: user.phone,
        name: user.name,
        role: user.role,
      }
    }, 'Token refreshed successfully', 200);

  } catch (error) {
    return res.apiError('Token refresh failed', error, 500, 'TOKEN_REFRESH_FAILED');
  }
};


// ================== EXPORT ==================

module.exports = {
  sendOTP,
  verifyOTPAndLogin,
  loginWithPassword, // 👈 MAIN LOGIN
  signup,
  refreshToken,      // 👈 NEW
  logout,
};