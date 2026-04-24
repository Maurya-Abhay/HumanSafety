const sendSMS = async (phone, message) => {
  try {
    console.log(`\n📨 SMS TO: ${phone}`);
    console.log(`📝 MESSAGE: ${message}\n`);
    return { success: true, phone };
  } catch (error) {
    console.error('❌ SMS error:', error.message);
    return { success: false, error: error.message };
  }
};

module.exports = { sendSMS };
