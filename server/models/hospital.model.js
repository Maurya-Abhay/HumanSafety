const mongoose = require('mongoose');

const hospitalSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    phone: { type: String, required: true },
    email: { type: String, default: '' },
    
    // GeoJSON format for geospatial queries (required for $near, $nearSphere)
    location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number], // [longitude, latitude] - NOTE: GeoJSON uses [lon, lat] order!
        required: true,
        validate: {
          validator: function(v) {
            return Array.isArray(v) && v.length === 2 && 
                   v[0] >= -180 && v[0] <= 180 && // longitude
                   v[1] >= -90 && v[1] <= 90;      // latitude
          },
          message: 'Invalid GeoJSON coordinates [longitude, latitude]'
        }
      }
    },
    
    address: { type: String, default: '' },
    beds: { type: Number, default: 0 },
    ambulance: { type: Boolean, default: true },
    emergencyDept: { type: Boolean, default: true },
    rating: { type: Number, default: 4.5 },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

// Create 2dsphere index for geospatial queries
hospitalSchema.index({ 'location': '2dsphere' });

// Helper method to create location from latitude/longitude
hospitalSchema.methods.setLocation = function(latitude, longitude) {
  this.location = {
    type: 'Point',
    coordinates: [longitude, latitude] // [lon, lat] for GeoJSON
  };
};

// Helper method to get latitude (convenience method)
hospitalSchema.methods.getLatitude = function() {
  return this.location?.coordinates[1] || 0;
};

// Helper method to get longitude (convenience method)
hospitalSchema.methods.getLongitude = function() {
  return this.location?.coordinates[0] || 0;
};

module.exports = mongoose.model('Hospital', hospitalSchema);
