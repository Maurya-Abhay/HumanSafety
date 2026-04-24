const Contact = require('../models/contact.model');
const User = require('../models/user.model');

const addContact = async (req, res) => {
  try {
    const { name, phone, relation, priority } = req.body;
    if (!name || !phone) return res.status(400).json({ message: 'Name and phone required' });
    
    const contact = await Contact.create({
      userId: req.user.userId,
      name,
      phone,
      relation: relation || 'Friend',
      priority: priority || 1,
    });
    
    await User.findByIdAndUpdate(req.user.userId, {
      $push: { emergencyContacts: contact._id },
    });
    
    res.status(201).json({
      message: 'Contact added',
      contact: { id: contact._id, name: contact.name, phone: contact.phone },
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to add contact', error: error.message });
  }
};

const getContacts = async (req, res) => {
  try {
    const contacts = await Contact.find({
      userId: req.user.userId,
      isActive: true,
    }).sort({ priority: 1 });
    
    res.status(200).json({
      message: 'Contacts retrieved',
      count: contacts.length,
      contacts: contacts.map(c => ({
        id: c._id,
        name: c.name,
        phone: c.phone,
        relation: c.relation,
        priority: c.priority,
      })),
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch contacts', error: error.message });
  }
};

const deleteContact = async (req, res) => {
  try {
    const { contactId } = req.params;
    await Contact.findOneAndUpdate(
      { _id: contactId, userId: req.user.userId },
      { isActive: false }
    );
    
    await User.findByIdAndUpdate(req.user.userId, {
      $pull: { emergencyContacts: contactId },
    });
    
    res.status(200).json({ message: 'Contact deleted' });
  } catch (error) {
    res.status(500).json({ message: 'Failed to delete contact', error: error.message });
  }
};

module.exports = { addContact, getContacts, deleteContact };
