const Alert = require('../models/alert.model');
const User = require('../models/user.model');
const Contact = require('../models/contact.model');
const Settings = require('../models/settings.model');
const Hospital = require('../models/hospital.model');
const AIEngineClient = require('../services/ai-engine.service');
const { sendSMS } = require('../services/sms.service');
const { sendNotification } = require('../services/notification.service');

/**
 * POST /accident/analyze
 * Analyze sensor data for accident detection via AI Engine
 */
const analyzeAccident = async (req, res) => {
  try {
    const userId = req.user.id || req.user.userId;
    const sensorData = req.body;

    // Validate user exists
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Call AI Engine for comprehensive analysis
    const aiResult = await AIEngineClient.analyzeAccident(sensorData);

    // If no accident detected, return analysis
    if (!aiResult.triggerAlert) {
      return res.status(200).json({
        success: true,
        message: 'No accident detected',
        analysis: {
          riskScore: aiResult.riskScore,
          riskLevel: aiResult.riskLevel,
          confidence: aiResult.confidence,
          triggerAlert: false,
          checkAIStatus: aiResult.success ? 'ok' : 'degraded'
        }
      });
    }

    // ============== ACCIDENT DETECTED ==============

    // 1. Create Alert Record
    const alert = new Alert({
      userId,
      type: 'accident',
      status: 'active',
      location: {
        type: 'Point',
        coordinates: [sensorData.longitude || 0, sensorData.latitude || 0]
      },
      sensorData: {
        accelerometerData: sensorData.accelerometerData,
        gyroscopeData: sensorData.gyroscopeData,
        speed: sensorData.speed,
        audioLevel: sensorData.audioLevel
      },
      aiAnalysis: {
        riskScore: aiResult.riskScore,
        riskLevel: aiResult.riskLevel,
        confidence: aiResult.confidence,
        factors: aiResult.data?.engines?.accident?.factors || []
      },
      timestamp: new Date()
    });

    await alert.save();

    // 2. Get Emergency Contacts
    const contacts = await Contact.find({ userId, isEmergency: true });
    const emergencyPhones = contacts.map(c => c.phone);

    // 3. Send SMS Alerts
    let smsNotified = 0;
    if (emergencyPhones.length > 0) {
      const message = `🚑 EMERGENCY: ${user.name} may have been in an accident at ${new Date().toLocaleTimeString()}. Location: https://maps.google.com/?q=${sensorData.latitude},${sensorData.longitude}. Risk Level: ${aiResult.riskLevel}`;
      
      for (const phone of emergencyPhones) {
        const smResult = await sendSMS(phone, message);
        if (smResult.success) smsNotified++;
      }
    }

    // 4. Send Push Notification to User
    await sendNotification(userId, {
      title: '🚨 Accident Detected',
      body: `Risk level: ${aiResult.riskLevel}. Emergency services notified.`,
      data: { alertId: alert._id, type: 'accident' }
    });

    // 5. Find Nearby Hospitals (if using geospatial)
    let nearbyHospitals = [];
    try {
      nearbyHospitals = await Hospital.find({
        location: {
          $near: {
            $geometry: {
              type: 'Point',
              coordinates: [sensorData.longitude || 0, sensorData.latitude || 0]
            },
            $maxDistance: 5000 // 5km
          }
        }
      }).limit(3);
    } catch (err) {
      console.warn('⚠️ Hospital search failed:', err.message);
    }

    res.status(200).json({
      success: true,
      message: 'Accident detected - Emergency alert activated',
      alert: {
        id: alert._id,
        riskScore: aiResult.riskScore,
        riskLevel: aiResult.riskLevel,
        confidence: aiResult.confidence,
        emergencyContactsNotified: smsNotified,
        nearbyHospitals: nearbyHospitals.map(h => ({
          name: h.name,
          phone: h.phone,
          address: h.address
        })),
        userLocation: {
          latitude: sensorData.latitude,
          longitude: sensorData.longitude
        }
      }
    });

  } catch (error) {
    console.error('❌ Accident Analysis Error:', error);
    res.status(500).json({
      success: false,
      message: 'Error analyzing accident',
      error: error.message
    });
  }
};

module.exports = { analyzeAccident };
