const axios = require('axios');
const twilio = require('twilio');
const logger = require('../config/logger');

// Initialize Twilio client (optional, if SMS_PROVIDER=twilio)
let twilioClient = null;
if (process.env.SMS_PROVIDER === 'twilio' && process.env.TWILIO_ACCOUNT_SID) {
  twilioClient = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
}

/**
 * Send SMS via multiple providers
 * @param {string} phone - Recipient phone number (international format: +1234567890)
 * @param {string} message - SMS content
 * @returns {Promise<{success: boolean, phone: string, messageId?: string, provider?: string, error?: string}>}
 */
const sendSMS = async (phone, message) => {
  const provider = process.env.SMS_PROVIDER || 'mock';
  
  try {
    // Validate phone number
    if (!phone || !/^\+?[1-9]\d{1,14}$/.test(phone.replace(/\s/g, ''))) {
      throw new Error(`Invalid phone number: ${phone}`);
    }

    // Validate message length
    if (!message || message.length === 0) {
      throw new Error('Message cannot be empty');
    }

    if (message.length > 160) {
      logger.warn(`Message exceeds 160 characters, will be split into ${Math.ceil(message.length / 160)} parts`);
    }

    let result;

    switch (provider) {
      case 'twilio':
        result = await sendViatwilio(phone, message);
        break;
      case 'msg91':
        result = await sendViaMsg91(phone, message);
        break;
      case 'aws-sns':
        result = await sendViaAwsSNS(phone, message);
        break;
      case 'mock':
        result = sendViaMock(phone, message);
        break;
      default:
        throw new Error(`Unknown SMS provider: ${provider}`);
    }

    logger.info(`SMS sent successfully via ${provider}`, {
      phone,
      messageId: result.messageId,
      provider: result.provider
    });

    return {
      success: true,
      phone,
      messageId: result.messageId,
      provider: result.provider
    };
  } catch (error) {
    logger.error(`SMS delivery failed for ${phone}`, {
      provider,
      error: error.message,
      stack: error.stack
    });

    return {
      success: false,
      phone,
      error: error.message,
      provider
    };
  }
};

/**
 * Send SMS via Twilio
 */
const sendViatwilio = async (phone, message) => {
  if (!twilioClient) {
    throw new Error('Twilio client not initialized. Set TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN');
  }

  const result = await twilioClient.messages.create({
    body: message,
    from: process.env.TWILIO_PHONE_NUMBER,
    to: phone
  });

  return {
    messageId: result.sid,
    provider: 'twilio'
  };
};

/**
 * Send SMS via MSG91 (popular in India)
 */
const sendViaMsg91 = async (phone, message) => {
  if (!process.env.MSG91_AUTH_KEY) {
    throw new Error('MSG91_AUTH_KEY not configured');
  }

  // Ensure phone number is in correct format (10 digits for India)
  let formattedPhone = phone.replace(/\D/g, '');
  if (formattedPhone.length === 10) {
    formattedPhone = '91' + formattedPhone; // Add country code for India
  }

  const response = await axios.get('https://api.msg91.com/apiv5/flow/', {
    params: {
      authkey: process.env.MSG91_AUTH_KEY,
      mobiles: formattedPhone,
      message: message,
      sender: process.env.MSG91_SENDER_ID || 'SAFETY'
    },
    timeout: 10000
  });

  if (response.data.type === 'error') {
    throw new Error(`MSG91 Error: ${response.data.message}`);
  }

  return {
    messageId: response.data.request_id,
    provider: 'msg91'
  };
};

/**
 * Send SMS via AWS SNS (if available)
 */
const sendViaAwsSNS = async (phone, message) => {
  const AWS = require('aws-sdk');
  const sns = new AWS.SNS({
    region: process.env.AWS_REGION || 'us-east-1'
  });

  const params = {
    Message: message,
    PhoneNumber: phone,
    MessageAttributes: {
      'AWS.SNS.SMS.SenderID': {
        DataType: 'String',
        StringValue: 'HumanSafety'
      },
      'AWS.SNS.SMS.SMSType': {
        DataType: 'String',
        StringValue: 'Transactional'
      }
    }
  };

  const result = await sns.publish(params).promise();

  return {
    messageId: result.MessageId,
    provider: 'aws-sns'
  };
};

/**
 * Mock SMS delivery (for development/testing)
 */
const sendViaMock = (phone, message) => {
  console.log(`\n📨 [MOCK SMS] TO: ${phone}`);
  console.log(`📝 [MOCK SMS] MESSAGE: ${message}`);
  console.log(`🔑 [MOCK SMS] ID: SMS_${Date.now()}\n`);

  return {
    messageId: 'SMS_MOCK_' + Date.now(),
    provider: 'mock'
  };
};

/**
 * Send bulk SMS to multiple recipients
 */
const sendBulkSMS = async (recipients, message) => {
  const results = [];

  for (const phone of recipients) {
    try {
      const result = await sendSMS(phone, message);
      results.push(result);
    } catch (error) {
      results.push({
        success: false,
        phone,
        error: error.message
      });
    }
  }

  return results;
};

module.exports = {
  sendSMS,
  sendBulkSMS
};
