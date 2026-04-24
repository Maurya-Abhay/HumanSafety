const express = require('express');
const { addContact, getContacts, deleteContact } = require('../controllers/contact.controller');
const { verifyToken } = require('../middleware/auth.middleware');
const { validateAddContact, validateRemoveContact } = require('../middleware/validation.middleware');

const router = express.Router();

// POST /contact/add - Add emergency contact
router.post('/add', verifyToken, validateAddContact, addContact);

// GET /contact/list - Get all contacts
router.get('/list', verifyToken, getContacts);

// DELETE /contact/remove/:contactId - Delete contact
router.delete('/remove/:contactId', verifyToken, validateRemoveContact, deleteContact);

module.exports = router;
