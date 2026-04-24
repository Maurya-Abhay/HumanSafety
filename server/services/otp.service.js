const otpStore = new Map();

// Test phone numbers that use demo OTP
const DEMO_PHONES = ['9876543210', '9999999999', '1111111111'];
const DEMO_OTP = '123456';

const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

const storeOTP = (phone, otp) => {
  const expiresAt = Date.now() + 5 * 60 * 1000;
  otpStore.set(phone, { otp, expiresAt });
  console.log(`📱 OTP for ${phone}: ${otp}${DEMO_PHONES.includes(phone) ? ' (DEMO MODE)' : ''}`);
};

const verifyOTP = (phone, otp) => {
  // For demo phones, accept either the stored OTP or the demo OTP
  if (DEMO_PHONES.includes(phone) && otp === DEMO_OTP) {
    return { valid: true, message: 'OTP verified (demo mode)' };
  }
  
  const stored = otpStore.get(phone);
  
  if (!stored) return { valid: false, message: 'OTP not found' };
  if (Date.now() > stored.expiresAt) {
    otpStore.delete(phone);
    return { valid: false, message: 'OTP expired' };
  }
  if (stored.otp !== otp) return { valid: false, message: 'Invalid OTP' };
  
  otpStore.delete(phone);
  return { valid: true, message: 'OTP verified' };
};

module.exports = { generateOTP, storeOTP, verifyOTP };
