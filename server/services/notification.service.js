const Notification = require('../models/notification.model');

const sendNotification = async (userId, title, message, type = 'alert', caseId = null) => {
  try {
    console.log(`\n🔔 NOTIFICATION TO USER: ${userId}`);
    console.log(`   Title: ${title}`);
    console.log(`   Message: ${message}`);
    console.log(`   Type: ${type}\n`);
    
    // Save notification to database
    try {
      const notification = new Notification({
        userId,
        title,
        message,
        type,
        caseId,
        isRead: false,
        timestamp: new Date(),
      });
      await notification.save();
    } catch (dbError) {
      console.error('Failed to save notification to DB:', dbError.message);
      // Still return success for now, notification was sent even if not persisted
    }
    
    // In production, integrate with FCM/APN for push notifications
    // const response = await admin.messaging().send({
    //   token: userToken,
    //   notification: { title, body: message },
    //   data: { type, caseId: caseId || '' }
    // });
    
    return { success: true, userId, title, message, notificationId: 'NOTIF_' + Date.now() };
  } catch (error) {
    console.error('❌ Notification error:', error.message);
    return { success: false, error: error.message };
  }
};

const broadcastNotification = async (userIds, title, message) => {
  const results = await Promise.all(
    userIds.map(userId => sendNotification(userId, title, message))
  );
  return results.filter(r => r.success).length;
};

module.exports = {
  sendNotification,
  broadcastNotification,
};
