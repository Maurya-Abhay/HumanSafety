const axios = require('axios');

const sendSMS = async (phone, message) => {
  try {
    // For production, integrate with SMS gateway (Twilio, MSG91, etc.)
    // For now, log and simulate successful delivery
    console.log(`\n📨 SMS TO: ${phone}`);
    console.log(`📝 MESSAGE: ${message}\n`);
    
    // In production, uncomment and configure:
    // const response = await axios.post('https://api.sms-provider.com/send', {
    //   to: phone,
    //   message: message,
    //   apiKey: process.env.SMS_API_KEY
    // });
    // return { success: true, phone, messageId: response.data.id };
    
    return { success: true, phone, messageId: 'SMS_' + Date.now() };
  } catch (error) {
    console.error('❌ SMS error:', error.message);
    return { success: false, error: error.message };
  }
};

module.exports = { sendSMS };
