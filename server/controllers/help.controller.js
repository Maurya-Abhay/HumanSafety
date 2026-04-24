const HelpRequest = require('../models/help.model');
const User = require('../models/user.model');
const { getNearbyUsers, validateLocation } = require('../services/location.service');
const { sendNotification } = require('../services/notification.service');

const requestHelp = async (req, res) => {
  try {
    const { latitude, longitude, description } = req.body;
    
    const locCheck = validateLocation(latitude, longitude);
    if (!locCheck.valid) return res.status(400).json({ message: locCheck.message });
    
    const radius = parseInt(process.env.DEFAULT_RADIUS_KM) || 5;
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);
    
    const helpRequest = await HelpRequest.create({
      requesterId: req.user.userId,
      location: { latitude, longitude },
      radius,
      description: description || 'User needs help',
      expiresAt,
    });
    
    const allUsers = await User.find({ _id: { $ne: req.user.userId }, isActive: true });
    const nearby = getNearbyUsers(allUsers, latitude, longitude, radius);
    
    helpRequest.nearbyUsers = nearby;
    await helpRequest.save();
    
    for (const user of nearby.slice(0, 10)) {
      await sendNotification(user.userId.toString(), 'Help Needed', 
        'Someone needs help near you. Distance: ' + user.distance.toFixed(1) + ' km');
    }
    
    res.status(201).json({
      message: 'Help request created',
      request: {
        id: helpRequest._id,
        nearbyUsersCount: nearby.length,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to request help', error: error.message });
  }
};

const acceptHelp = async (req, res) => {
  try {
    const { helpRequestId } = req.body;
    
    const helpRequest = await HelpRequest.findById(helpRequestId);
    if (!helpRequest) return res.status(404).json({ message: 'Help request not found' });
    if (helpRequest.status !== 'pending') return res.status(400).json({ message: 'Request already handled' });
    
    helpRequest.helperId = req.user.userId;
    helpRequest.status = 'accepted';
    await helpRequest.save();
    
    await sendNotification(helpRequest.requesterId.toString(), 'Help Accepted', 
      'Someone has accepted your help request!');
    
    res.status(200).json({
      message: 'Help request accepted',
      request: { id: helpRequest._id, status: 'accepted' },
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to accept help', error: error.message });
  }
};

const rejectHelp = async (req, res) => {
  try {
    const { helpRequestId } = req.body;
    const helpRequest = await HelpRequest.findById(helpRequestId);
    if (!helpRequest) return res.status(404).json({ message: 'Help request not found' });
    
    helpRequest.status = 'rejected';
    await helpRequest.save();
    
    res.status(200).json({ message: 'Help request rejected' });
  } catch (error) {
    res.status(500).json({ message: 'Failed to reject help', error: error.message });
  }
};

const completeHelp = async (req, res) => {
  try {
    const { helpRequestId } = req.body;
    const helpRequest = await HelpRequest.findById(helpRequestId);
    if (!helpRequest) return res.status(404).json({ message: 'Help request not found' });
    
    helpRequest.status = 'completed';
    await helpRequest.save();
    
    res.status(200).json({ message: 'Help completed' });
  } catch (error) {
    res.status(500).json({ message: 'Failed to complete help', error: error.message });
  }
};

module.exports = { requestHelp, acceptHelp, rejectHelp, completeHelp };
