const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const User = require('../models/user.model');
const Ambulance = require('../models/ambulance.model');

const MONGO_URI = process.env.MONGODB_URI || process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/human-safety';

async function seedAmbulance() {
  try {
    // Connect to MongoDB
    await mongoose.connect(MONGO_URI);
    console.log('Connected to MongoDB');

    // Check if ambulance user already exists
    let ambulanceUser = await User.findOne({ email: 'ambulance@hospital.com' });

    if (!ambulanceUser) {
      // Create ambulance driver user
      const hashedPassword = await bcrypt.hash('ambulance123', 10);
      
      ambulanceUser = new User({
        name: 'Rajesh Kumar',
        email: 'ambulance@hospital.com',
        phone: '+91-9876543210',
        password: hashedPassword,
        role: 'ambulance',
        status: 'active',
        location: {
          latitude: 28.6139,
          longitude: 77.2090,
        },
      });

      await ambulanceUser.save();
      console.log('✓ Ambulance user created:', ambulanceUser.email);
    } else {
      console.log('✓ Ambulance user already exists:', ambulanceUser.email);
    }

    // Check if ambulance record exists for this driver
    let ambulance = await Ambulance.findOne({ driverId: ambulanceUser._id });

    if (!ambulance) {
      // Create a test hospital (or use existing one)
      let hospital = await User.findOne({ role: 'hospital' });

      if (!hospital) {
        const hospitalPassword = await bcrypt.hash('hospital123', 10);
        hospital = new User({
          name: 'City Hospital',
          email: 'admin@cityhospital.com',
          phone: '+91-9999999999',
          password: hospitalPassword,
          role: 'hospital',
          status: 'active',
          location: {
            latitude: 28.6200,
            longitude: 77.2300,
          },
        });
        await hospital.save();
        console.log('✓ Test hospital created:', hospital.email);
      }

      // Create ambulance record
      ambulance = new Ambulance({
        hospitalId: hospital._id,
        driverId: ambulanceUser._id,
        licenseNumber: 'HR-26-AB-1234',
        driverName: ambulanceUser.name,
        driverPhone: ambulanceUser.phone,
        status: 'available',
        currentLocation: {
          latitude: 28.6139,
          longitude: 77.2090,
          address: 'New Delhi',
        },
        isOnline: true,
        lastHeartbeat: new Date(),
      });

      await ambulance.save();
      console.log('✓ Ambulance record created:', ambulance.licenseNumber);
    } else {
      console.log('✓ Ambulance record already exists');
    }

    console.log('\n✓ Seed completed successfully!');
    console.log('\nAmbulance Login Credentials:');
    console.log('Email:', ambulanceUser.email);
    console.log('Password: ambulance123');
    console.log('Role: ambulance');

    await mongoose.disconnect();
  } catch (error) {
    console.error('Error seeding ambulance:', error);
    process.exit(1);
  }
}

// Run the seed
seedAmbulance();
