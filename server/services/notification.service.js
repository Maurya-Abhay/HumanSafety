const admin = require('firebase-admin');
const Notification = require('../models/notification.model');
const User = require('../models/user.model');
const logger = require('../config/logger');
const { getRealtimeService } = require('./realtime_event_service');

// Initialize Firebase Admin SDK if credentials are available
let firebaseInitialized = false;
try {
  if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY) {
    const serviceAccount = {
      type: 'service_account',
      project_id: process.env.FIREBASE_PROJECT_ID,
      private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
      private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      client_email: process.env.FIREBASE_CLIENT_EMAIL,
      client_id: process.env.FIREBASE_CLIENT_ID,
      auth_uri: 'https://accounts.google.com/o/oauth2/auth',
      token_uri: 'https://oauth2.googleapis.com/token',
    };

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      databaseURL: `https://${process.env.FIREBASE_PROJECT_ID}.firebaseio.com`
    });

    firebaseInitialized = true;
    logger.info('Firebase Admin SDK initialized successfully');
  }
} catch (error) {
  logger.warn('Firebase not initialized - push notifications will use fallback methods', {
    error: error.message
  });
}

/**
 * Send push notification to a user
 * @param {string} userId - User ID
 * @param {string} title - Notification title
 * @param {string} message - Notification message
 * @param {string} type - Notification type (alert, case_update, etc.)
 * @param {string} caseId - Associated case ID (optional)
 * @param {Object} data - Additional data to send
 * @returns {Promise<{success: boolean, userId: string, notificationId: string, method?: string, error?: string}>}
 */
const sendNotification = async (userId, title, message, type = 'alert', caseId = null, data = {}) => {
  try {
    // Input validation
    if (!userId || !title || !message) {
      throw new Error('Missing required fields: userId, title, message');
    }

    if (title.length > 200) {
      logger.warn('Notification title truncated', { length: title.length });
      title = title.substring(0, 200);
    }

    if (message.length > 4000) {
      logger.warn('Notification message truncated', { length: message.length });
      message = message.substring(0, 4000);
    }

    const notificationId = `NOTIF_${Date.now()}_${Math.random().toString(36).slice(2)}`;
    
    // 1. Save to database first (persistent)
    let savedNotification = null;
    try {
      savedNotification = new Notification({
        userId,
        title,
        message,
        type,
        caseId,
        data,
        isRead: false,
        timestamp: new Date(),
        notificationId,
        deliveryStatus: 'pending',
        deliveryMethods: []
      });
      await savedNotification.save();
      logger.debug('Notification saved to database', { userId, notificationId });
    } catch (dbError) {
      logger.error('Failed to save notification to database', {
        userId,
        error: dbError.message
      });
      // Continue - we can still try to send via other methods
    }

    const deliveryMethods = [];
    const errors = [];

    // 2. Try to send via FCM (if Firebase is configured)
    if (firebaseInitialized) {
      try {
        const result = await sendViaFCM(userId, title, message, type, caseId, data);
        if (result.success) {
          deliveryMethods.push('fcm');
          logger.info('Notification sent via FCM', { userId, notificationId, messageId: result.messageId });
        } else {
          errors.push(`FCM: ${result.error}`);
        }
      } catch (fcmError) {
        logger.warn('FCM delivery failed', { userId, error: fcmError.message });
        errors.push(`FCM: ${fcmError.message}`);
      }
    }

    // 3. Try to send via WebSocket (real-time)
    try {
      const wsResult = await sendViaWebSocket(userId, title, message, type, caseId, data);
      if (wsResult.success) {
        deliveryMethods.push('websocket');
        logger.info('Notification sent via WebSocket', { userId, notificationId });
      }
    } catch (wsError) {
      logger.warn('WebSocket delivery failed', { userId, error: wsError.message });
    }

    // 4. Update notification with delivery status
    if (savedNotification) {
      const allMethodsFailed = deliveryMethods.length === 0;
      savedNotification.deliveryStatus = allMethodsFailed ? 'failed' : 'delivered';
      savedNotification.deliveryMethods = deliveryMethods;
      try {
        await savedNotification.save();
      } catch (updateError) {
        logger.error('Failed to update notification status', { error: updateError.message });
      }
    }

    // If we couldn't deliver via any method, log error but still return
    if (deliveryMethods.length === 0) {
      logger.error('Notification could not be delivered via any method', {
        userId,
        notificationId,
        errors
      });
      return {
        success: false,
        userId,
        notificationId,
        error: 'Notification saved to database but could not be delivered via push methods',
        methods: []
      };
    }

    return {
      success: true,
      userId,
      notificationId,
      title,
      message,
      methods: deliveryMethods
    };
  } catch (error) {
    logger.error('Notification service error', {
      userId,
      error: error.message,
      stack: error.stack
    });

    return {
      success: false,
      userId,
      error: error.message
    };
  }
};

/**
 * Send notification via FCM
 */
const sendViaFCM = async (userId, title, message, type, caseId, data) => {
  if (!firebaseInitialized) {
    throw new Error('Firebase not initialized');
  }

  // Get user's FCM token from database
  const user = await User.findById(userId);
  if (!user || !user.fcmToken) {
    throw new Error(`User ${userId} has no FCM token`);
  }

  const payload = {
    notification: {
      title: title.substring(0, 200),
      body: message.substring(0, 200)
    },
    data: {
      type,
      caseId: caseId || '',
      notificationId: `NOTIF_${Date.now()}`,
      ...data
    },
    android: {
      ttl: 3600,
      priority: 'high',
      notification: {
        sound: 'default',
        color: '#FF0000'
      }
    },
    apns: {
      headers: {
        'apns-priority': '10'
      },
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
          alert: {
            title,
            body: message
          }
        }
      }
    }
  };

  try {
    const messageId = await admin.messaging().send({
      token: user.fcmToken,
      ...payload
    });

    return {
      success: true,
      messageId,
      provider: 'fcm'
    };
  } catch (error) {
    // If token is invalid, update user record
    if (error.code === 'messaging/invalid-registration-token' ||
        error.code === 'messaging/registration-token-not-registered') {
      logger.info('FCM token invalid, clearing from user record', { userId });
      await User.findByIdAndUpdate(userId, { fcmToken: null });
    }
    throw error;
  }
};

/**
 * Send notification via WebSocket
 */
const sendViaWebSocket = async (userId, title, message, type, caseId, data) => {
  try {
    const rtService = getRealtimeService();
    if (rtService) {
      rtService.broadcast({
        type: 'notification',
        userId,
        title,
        message,
        notificationType: type,
        caseId,
        data,
        timestamp: new Date().toISOString()
      });

      return {
        success: true,
        provider: 'websocket'
      };
    }
    throw new Error('Realtime service not available');
  } catch (error) {
    throw error;
  }
};

/**
 * Send notification to multiple users
 */
const sendBroadcastNotification = async (userIds, title, message, type = 'alert', data = {}) => {
  const results = [];

  for (const userId of userIds) {
    try {
      const result = await sendNotification(userId, title, message, type, null, data);
      results.push({
        userId,
        ...result
      });
    } catch (error) {
      results.push({
        userId,
        success: false,
        error: error.message
      });
    }
  }

  const successful = results.filter(r => r.success).length;
  logger.info(`Broadcast notification sent to ${successful}/${userIds.length} users`, {
    title,
    successful,
    total: userIds.length
  });

  return results;
};

/**
 * Get notifications for user
 */
const getUserNotifications = async (userId, limit = 50, offset = 0) => {
  try {
    const notifications = await Notification.find({ userId })
      .sort({ timestamp: -1 })
      .limit(limit)
      .skip(offset);

    const total = await Notification.countDocuments({ userId });

    return {
      success: true,
      notifications,
      total,
      limit,
      offset
    };
  } catch (error) {
    logger.error('Failed to fetch notifications', { userId, error: error.message });
    throw error;
  }
};

/**
 * Mark notification as read
 */
const markAsRead = async (notificationId) => {
  try {
    await Notification.findByIdAndUpdate(notificationId, { isRead: true });
    return { success: true };
  } catch (error) {
    logger.error('Failed to mark notification as read', { notificationId, error: error.message });
    throw error;
  }
};

/**
 * Delete notification
 */
const deleteNotification = async (notificationId) => {
  try {
    await Notification.findByIdAndDelete(notificationId);
    return { success: true };
  } catch (error) {
    logger.error('Failed to delete notification', { notificationId, error: error.message });
    throw error;
  }
};

module.exports = {
  sendNotification,
  sendBroadcastNotification,
  getUserNotifications,
  markAsRead,
  deleteNotification,
  firebaseInitialized
};
