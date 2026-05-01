const Alert = require('../models/alert.model');
const Contact = require('../models/contact.model');
const User = require('../models/user.model');
const Hospital = require('../models/hospital.model');
const logger = require('../config/logger');
const { validateLocation, formatLocation } = require('../services/location.service');
const { sendSMS } = require('../services/sms.service');
const { sendNotification } = require('../services/notification.service');
const AIEngineClient = require('../services/ai-engine.service');

/**
 * POST /emergency/panic
 * CRITICAL FLOW: User triggers panic button
 * 1. Get location
 * 2. Call AI for risk assessment
 * 3. Send alerts to contacts
 * 4. Notify nearby hospitals
 */
const triggerPanic = async (req, res) => {
  try {
    const userId = req.user.id || req.user.userId;
    const { latitude, longitude, sensorData } = req.body;
    
    // Validate location
    const locCheck = validateLocation(latitude, longitude);
    if (!locCheck.valid) {
      return res.status(400).json({
        success: false,
        message: locCheck.message
      });
    }
    
    // Get user
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // ============== RISK ASSESSMENT VIA AI ENGINE ==============
    
    let riskScore = 100; // Manual panic = max risk
    let riskLevel = 'critical';
    let aiAnalysis = {};

    // If sensor data provided, get AI assessment
    if (sensorData) {
      try {
        const aiResult = await AIEngineClient.analyzeAccident({
          ...sensorData,
          latitude,
          longitude
        });

        if (aiResult.success) {
          riskScore = aiResult.riskScore;
          riskLevel = aiResult.riskLevel;
          aiAnalysis = aiResult.data;
        }
      } catch (aiError) {
        console.warn('⚠️ AI Engine unavailable, using manual assessment:', aiError.message);
        // Continue with manual assessment
      }
    }

    // ============== CREATE ALERT ==============

    const alert = new Alert({
      userId,
      type: 'panic',
      status: 'pending',
      location: {
        latitude,
        longitude
      },
      description: `Panic alert activated - Risk Level: ${riskLevel}`,
      metadata: {
        riskScore,
        riskLevel,
        aiAnalysis: aiAnalysis
      }
    });

    await alert.save();

    // ============== NOTIFY EMERGENCY CONTACTS ==============

    // Get contacts marked as emergency
    const contacts = await Contact.find({
      userId,
      isEmergency: true
    }).sort({ priority: 1 });

    const emergencyPhones = contacts.map(c => c.phone);
    let smsNotified = 0;

    if (emergencyPhones.length > 0) {
      const locationLink = `https://maps.google.com/?q=${latitude},${longitude}`;
      const message = `🚨 CRITICAL EMERGENCY: ${user.name} needs IMMEDIATE help!\n⏰ Time: ${new Date().toLocaleString()}\n📍 Location: ${locationLink}\n🚑 Risk Level: ${riskLevel}\nPlease call emergency services and the user immediately.`;

      for (const phone of emergencyPhones) {
        const smsResult = await sendSMS(phone, message);
        if (smsResult.success) smsNotified++;
      }
    }

    // ============== PUSH NOTIFICATION TO USER ==============

    await sendNotification(userId, '🚨 Panic Alert Sent', `Your emergency contacts have been notified. Help is on the way.`, 'alert', alert._id);

    // ============== FIND NEARBY HOSPITALS ==============

    let nearbyHospitals = [];
    try {
      // Use GeoJSON $near query with 2dsphere index
      // Note: coordinates are [longitude, latitude] in GeoJSON format
      const maxDistanceMeters = 10000; // 10km radius
      
      nearbyHospitals = await Hospital.find({
        location: {
          $near: {
            $geometry: {
              type: 'Point',
              coordinates: [longitude, latitude] // [lon, lat] order for GeoJSON
            },
            $maxDistance: maxDistanceMeters // in meters
          }
        },
        isActive: true
      }).limit(5);

      logger.info('Found nearby hospitals', {
        userId,
        latitude,
        longitude,
        hospitalsFound: nearbyHospitals.length
      });

      // Auto-call nearest hospital if critical
      if (nearbyHospitals.length > 0 && riskLevel === 'critical') {
        const nearestHospital = nearbyHospitals[0];
        const hospitalMessage = `Emergency Alert: Patient ${user.name} (${user.phone}) at location ${latitude},${longitude}. Risk level: ${riskLevel}. ETA: Unknown`;
        
        try {
          await sendSMS(nearestHospital.phone, hospitalMessage);
          logger.info('Hospital notification sent', {
            hospitalId: nearestHospital._id,
            hospitalPhone: nearestHospital.phone
          });
        } catch (smsError) {
          logger.error('Failed to send SMS to hospital', {
            hospitalId: nearestHospital._id,
            error: smsError.message
          });
        }
      }
    } catch (err) {
      logger.error('Hospital geospatial query failed', {
        error: err.message,
        userId,
        coordinates: [longitude, latitude]
      });
      // Continue without hospital notification if query fails
    }

    // ============== RESPONSE ==============

    res.status(200).json({
      success: true,
      message: 'Panic alert activated successfully',
      alert: {
        id: alert._id,
        timestamp: alert.timestamp,
        location: {
          latitude,
          longitude,
          mapLink: `https://maps.google.com/?q=${latitude},${longitude}`
        },
        emergencyContactsNotified: smsNotified,
        nearbyHospitals: nearbyHospitals.map(h => ({
          name: h.name,
          phone: h.phone,
          address: h.address,
          distance: 'calculated'
        })),
        riskAssessment: {
          riskScore,
          riskLevel
        }
      }
    });

  } catch (error) {
    logger.error('Panic trigger error', {
      userId,
      latitude,
      longitude,
      error: error.message,
      stack: error.stack
    });
    res.status(500).json({
      success: false,
      message: 'Error triggering panic alert',
      error: error.message
    });
  }
};

/**
 * GET /emergency/alerts
 * Get user's recent alerts
 */
const getAlerts = async (req, res) => {
  try {
    const userId = req.user.id || req.user.userId;
    
    const alerts = await Alert.find({ userId })
      .sort({ timestamp: -1 })
      .limit(50);
    
    res.status(200).json({
      success: true,
      count: alerts.length,
      alerts: alerts.map(a => ({
        id: a._id,
        type: a.type,
        status: a.status,
        location: {
          latitude: a.location?.coordinates?.[1],
          longitude: a.location?.coordinates?.[0]
        },
        riskLevel: a.aiAnalysis?.riskLevel,
        contactsNotified: a.userInfo?.emergencyPhones?.length || 0,
        timestamp: a.timestamp
      }))
    });
  } catch (error) {
    console.error('❌ Get Alerts Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch alerts',
      error: error.message
    });
  }
};

/**
 * PATCH /emergency/alerts/:alertId
 * Dismiss or update alert status
 */
const dismissAlert = async (req, res) => {
  try {
    const { alertId } = req.params;
    const userId = req.user.id || req.user.userId;
    const { status } = req.body;

    const alert = await Alert.findOneAndUpdate(
      { _id: alertId, userId },
      { status: status || 'dismissed' },
      { new: true }
    );
    
    if (!alert) {
      return res.status(404).json({
        success: false,
        message: 'Alert not found'
      });
    }
    
    res.status(200).json({
      success: true,
      message: 'Alert updated',
      alert: {
        id: alert._id,
        status: alert.status
      }
    });
  } catch (error) {
    console.error('❌ Dismiss Alert Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update alert',
      error: error.message
    });
  }
};

module.exports = { triggerPanic, getAlerts, dismissAlert };
