const Alert = require('../models/alert.model');
const User = require('../models/user.model');
const { findNearestHospitals, requestAmbulance } = require('../services/hospital.service');
const { validateLocation } = require('../services/location.service');

const requestHospital = async (req, res) => {
  try {
    const { latitude, longitude, emergency } = req.body;
    
    const locCheck = validateLocation(latitude, longitude);
    if (!locCheck.valid) return res.status(400).json({ message: locCheck.message });
    
    const userId = req.user._id || req.user.userId;
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'User not found' });
    
    const hospitals = await findNearestHospitals(latitude, longitude, 10);
    if (hospitals.length === 0) {
      return res.status(404).json({ message: 'No hospitals found nearby' });
    }
    
    const alert = await Alert.create({
      userId,
      type: 'hospital',
      location: { latitude, longitude },
      status: 'pending',
      description: 'Hospital request',
      metadata: {
        emergency: emergency || false,
        hospitalCount: hospitals.length,
      },
    });
    
    let successCount = 0;
    for (let i = 0; i < Math.min(hospitals.length, 3); i++) {
      const result = await requestAmbulance(hospitals[i], { latitude, longitude }, user.name);
      if (result.success) successCount++;
    }
    
    res.status(200).json({
      message: 'Hospital request sent',
      hospitals: hospitals.slice(0, 3).map(h => ({
        name: h.name,
        phone: h.phone,
        distance: h.distance.toFixed(1),
      })),
      requestsSent: successCount,
    });
  } catch (error) {
    res.status(500).json({ message: 'Hospital request failed', error: error.message });
  }
};

const getNearbyHospitals = async (req, res) => {
  try {
    const { latitude, longitude } = req.query;
    
    const locCheck = validateLocation(parseFloat(latitude), parseFloat(longitude));
    if (!locCheck.valid) return res.status(400).json({ message: locCheck.message });
    
    const hospitals = await findNearestHospitals(parseFloat(latitude), parseFloat(longitude), 15);
    
    res.status(200).json({
      message: 'Hospitals retrieved',
      count: hospitals.length,
      hospitals: hospitals.map(h => ({
        id: h._id,
        name: h.name,
        phone: h.phone,
        distance: h.distance.toFixed(1),
        ambulance: h.ambulance,
        rating: h.rating,
      })),
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to get hospitals', error: error.message });
  }
};

module.exports = { requestHospital, getNearbyHospitals };
