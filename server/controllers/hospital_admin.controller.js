// Hospital registration and management controller
const User = require('../models/user.model');
const { sendSMS } = require('../services/sms.service');

// Hospital requests account (registration request)
const requestHospitalAccount = async (req, res) => {
  try {
    const {
      phone,
      contactPerson,
      hospitalName,
      licenseProof,
      latitude,
      longitude,
      address,
      totalBeds,
      specializations,
    } = req.body;

    if (!phone || !contactPerson || !hospitalName || !licenseProof || !address) {
      return res.status(400).json({
        message: 'Missing required fields: phone, contactPerson, hospitalName, licenseProof, address',
      });
    }

    let user = await User.findOne({ phone });

    if (user && user.role !== 'user') {
      return res.status(400).json({ message: 'Account already registered with different role' });
    }

    if (!user) {
      user = await User.create({
        phone,
        name: hospitalName,
        role: 'hospital',
        status: 'pending',
        hospitalDetails: {
          hospitalName,
          licenseProof,
          location: {
            latitude: latitude || 0,
            longitude: longitude || 0,
            address,
          },
          totalBeds: totalBeds || 0,
          availableBeds: totalBeds || 0,
          specializations: specializations || [],
          contactPerson,
        },
      });
    } else {
      user.name = hospitalName;
      user.role = 'hospital';
      user.status = 'pending';
      user.hospitalDetails = {
        hospitalName,
        licenseProof,
        location: {
          latitude: latitude || 0,
          longitude: longitude || 0,
          address,
        },
        totalBeds: totalBeds || 0,
        availableBeds: totalBeds || 0,
        specializations: specializations || [],
        contactPerson,
      };
      await user.save();
    }

    res.status(201).json({
      message: 'Hospital registration request submitted. Awaiting admin approval.',
      hospitalId: user._id,
      status: 'pending',
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to submit hospital request', error: error.message });
  }
};

// Get pending hospital requests (Admin only)
const getPendingHospitalRequests = async (req, res) => {
  try {
    const requests = await User.find({
      role: 'hospital',
      status: 'pending',
    }).select('-password');

    res.status(200).json({
      count: requests.length,
      requests,
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch requests', error: error.message });
  }
};

// Admin approves hospital account
const approveHospitalRequest = async (req, res) => {
  try {
    const { hospitalId } = req.params;
    const { adminNotes } = req.body;

    const hospital = await User.findById(hospitalId);
    if (!hospital || hospital.role !== 'hospital') {
      return res.status(404).json({ message: 'Hospital account not found' });
    }

    hospital.status = 'active';
    hospital.approvedBy = req.user._id;
    hospital.approvedAt = new Date();
    hospital.adminNotes = adminNotes || '';
    await hospital.save();

    // Send approval SMS
    await sendSMS(
      hospital.phone,
      `🏥 Your HumanSafety Hospital account has been APPROVED! Hospital: ${hospital.hospitalDetails.hospitalName}`
    );

    res.status(200).json({
      message: 'Hospital account approved',
      hospital: {
        id: hospital._id,
        phone: hospital.phone,
        name: hospital.hospitalDetails.hospitalName,
        totalBeds: hospital.hospitalDetails.totalBeds,
        status: 'active',
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Approval failed', error: error.message });
  }
};

// Admin rejects hospital account
const rejectHospitalRequest = async (req, res) => {
  try {
    const { hospitalId } = req.params;
    const { rejectionReason } = req.body;

    if (!rejectionReason) {
      return res.status(400).json({ message: 'Rejection reason required' });
    }

    const hospital = await User.findById(hospitalId);
    if (!hospital || hospital.role !== 'hospital') {
      return res.status(404).json({ message: 'Hospital account not found' });
    }

    hospital.status = 'rejected';
    hospital.rejectionReason = rejectionReason;
    await hospital.save();

    // Send rejection SMS
    await sendSMS(
      hospital.phone,
      `❌ Your Hospital registration request was rejected. Reason: ${rejectionReason}`
    );

    res.status(200).json({
      message: 'Hospital account rejected',
    });
  } catch (error) {
    res.status(500).json({ message: 'Rejection failed', error: error.message });
  }
};

// Get all active hospitals
const getAllActiveHospitals = async (req, res) => {
  try {
    const hospitals = await User.find({
      role: 'hospital',
      status: 'active',
      isBlocked: false,
    }).select('name phone hospitalDetails.location hospitalDetails.availableBeds hospitalDetails.specializations');

    res.status(200).json({
      count: hospitals.length,
      hospitals: hospitals.map(h => ({
        id: h._id,
        name: h.hospitalDetails.hospitalName,
        phone: h.phone,
        location: h.hospitalDetails.location,
        availableBeds: h.hospitalDetails.availableBeds,
        specializations: h.hospitalDetails.specializations,
      })),
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch hospitals', error: error.message });
  }
};

// Hospital updates bed availability (Hospital role only)
const updateBedAvailability = async (req, res) => {
  try {
    const { availableBeds } = req.body;

    if (typeof availableBeds !== 'number') {
      return res.status(400).json({ message: 'Available beds must be a number' });
    }

    const hospital = await User.findById(req.user._id);
    if (!hospital || hospital.role !== 'hospital') {
      return res.status(403).json({ message: 'Only hospital accounts can update beds' });
    }

    hospital.hospitalDetails.availableBeds = Math.max(0, Math.min(availableBeds, hospital.hospitalDetails.totalBeds));
    await hospital.save();

    res.status(200).json({
      message: 'Bed availability updated',
      availableBeds: hospital.hospitalDetails.availableBeds,
    });
  } catch (error) {
    res.status(500).json({ message: 'Update failed', error: error.message });
  }
};

// Hospital updates its profile (name, phone, address, specializations, etc.)
const updateHospitalProfile = async (req, res) => {
  try {
    const { hospitalName, phone, address, specializations, contactPerson } = req.body;

    const hospital = await User.findById(req.user._id);
    if (!hospital || hospital.role !== 'hospital') {
      return res.status(403).json({ message: 'Only hospital accounts can update profile' });
    }

    // Update allowed fields
    if (hospitalName) hospital.hospitalDetails.hospitalName = hospitalName;
    if (phone) hospital.phone = phone;
    if (address) hospital.hospitalDetails.location.address = address;
    if (specializations && Array.isArray(specializations)) {
      hospital.hospitalDetails.specializations = specializations;
    }
    if (contactPerson) hospital.hospitalDetails.contactPerson = contactPerson;
    if (hospitalName) hospital.name = hospitalName; // Keep name in sync

    await hospital.save();

    res.status(200).json({
      message: 'Hospital profile updated',
      hospital: {
        id: hospital._id,
        name: hospital.hospitalDetails.hospitalName,
        phone: hospital.phone,
        address: hospital.hospitalDetails.location.address,
        specializations: hospital.hospitalDetails.specializations,
        contactPerson: hospital.hospitalDetails.contactPerson,
        totalBeds: hospital.hospitalDetails.totalBeds,
        availableBeds: hospital.hospitalDetails.availableBeds,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Profile update failed', error: error.message });
  }
};

module.exports = {
  requestHospitalAccount,
  getPendingHospitalRequests,
  approveHospitalRequest,
  rejectHospitalRequest,
  getAllActiveHospitals,
  updateBedAvailability,
  updateHospitalProfile,
};
