const validateLocation = (latitude, longitude) => {
  if (typeof latitude !== 'number' || typeof longitude !== 'number') {
    return { valid: false, message: 'Invalid coordinates' };
  }
  if (latitude < -90 || latitude > 90) {
    return { valid: false, message: 'Invalid latitude' };
  }
  if (longitude < -180 || longitude > 180) {
    return { valid: false, message: 'Invalid longitude' };
  }
  return { valid: true };
};

const calculateDistance = (lat1, lon1, lat2, lon2) => {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
};

const formatLocation = (latitude, longitude) => {
  return `https://maps.google.com/?q=${latitude},${longitude}`;
};

const getNearbyUsers = (users, userLat, userLon, radiusKm) => {
  return users
    .map(user => ({
      userId: user._id,
      distance: calculateDistance(userLat, userLon, user.currentLocation.latitude, user.currentLocation.longitude),
    }))
    .filter(u => u.distance <= radiusKm)
    .sort((a, b) => a.distance - b.distance);
};

module.exports = {
  validateLocation,
  calculateDistance,
  formatLocation,
  getNearbyUsers,
};
