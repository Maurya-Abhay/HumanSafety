const sendNotification = async (userId, title, message, type = 'alert') => {
  try {
    console.log(`\n🔔 NOTIFICATION TO USER: ${userId}`);
    console.log(`   Title: ${title}`);
    console.log(`   Message: ${message}`);
    console.log(`   Type: ${type}\n`);
    
    return { success: true, userId, title, message };
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
