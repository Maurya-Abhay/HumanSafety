const Hospital = require('../models/hospital.model');
const { calculateDistance } = require('./location.service');

const findNearestHospitals = async (latitude, longitude, radiusKm = 10) => {
  try {
    const hospitals = await Hospital.find({ isActive: true });
    
    const nearby = hospitals
      .map(h => ({
        ...h.toObject(),
        distance: calculateDistance(latitude, longitude, h.location.latitude, h.location.longitude),
      }))
      .filter(h => h.distance <= radiusKm)
      .sort((a, b) => a.distance - b.distance);
    
    return nearby;
  } catch (error) {
    console.error('Hospital search error:', error.message);
    return [];
  }
};

const requestAmbulance = async (hospital, userLocation, userName) => {
  try {
    const { sendSMS } = require('./sms.service');
    const { sendNotification } = require('./notification.service');
    
    console.log(`\n🚑 AMBULANCE REQUEST`);
    console.log(`   Hospital: ${hospital.name}`);
    console.log(`   Phone: ${hospital.phone}`);
    console.log(`   User Location: ${userLocation.latitude}, ${userLocation.longitude}`);
    console.log(`   User: ${userName}\n`);
    
    // Send SMS to hospital
    const smsMessage = `🚨 URGENT: Ambulance needed for ${userName} at coordinates ${userLocation.latitude}, ${userLocation.longitude}. App: HumanSafety. Respond ASAP.`;
    
    try {
      await sendSMS(hospital.phone, smsMessage);
      console.log(`✅ SMS sent to hospital: ${hospital.phone}`);
    } catch (smsError) {
      console.warn(`⚠️ SMS to hospital failed: ${smsError.message}`);
    }
    
    // Send push notification to hospital staff
    try {
      if (hospital.adminTokens && hospital.adminTokens.length > 0) {
        await sendNotification(
          hospital.adminTokens,
          {
            title: '🚨 Emergency Ambulance Request',
            body: `Patient ${userName} needs assistance at ${userLocation.latitude}, ${userLocation.longitude}`,
            data: {
              emergencyType: 'ambulance_request',
              patientName: userName,
              latitude: userLocation.latitude,
              longitude: userLocation.longitude,
              hospitalId: hospital._id
            }
          }
        );
        console.log(`✅ Push notifications sent to hospital staff`);
      }
    } catch (notifError) {
      console.warn(`⚠️ Notification to hospital failed: ${notifError.message}`);
    }
    
    // Log to realtime event service
    const realtimeService = require('./realtime_event_service');
    realtimeService.recordEvent('AMBULANCE_REQUESTED', {
      hospitalId: hospital._id,
      hospitalName: hospital.name,
      patientName: userName,
      location: userLocation,
      timestamp: new Date().toISOString()
    });
    
    return { success: true, hospital: hospital.name, notificationsSent: true };
  } catch (error) {
    console.error('Ambulance request error:', error.message);
    return { success: false, error: error.message };
  }
};

module.exports = {
  findNearestHospitals,
  requestAmbulance,
};
