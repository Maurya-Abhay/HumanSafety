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
    console.log(`\n🚑 AMBULANCE REQUEST`);
    console.log(`   Hospital: ${hospital.name}`);
    console.log(`   Phone: ${hospital.phone}`);
    console.log(`   User Location: ${userLocation.latitude}, ${userLocation.longitude}`);
    console.log(`   User: ${userName}\n`);
    
    return { success: true, hospital: hospital.name };
  } catch (error) {
    console.error('Ambulance request error:', error.message);
    return { success: false };
  }
};

module.exports = {
  findNearestHospitals,
  requestAmbulance,
};
