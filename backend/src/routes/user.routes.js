const express   = require('express');
const router    = express.Router();
const userCtrl  = require('../controllers/user.controller');
const { authenticate } = require('../middleware/auth.middleware');

router.use(authenticate);

// GET    /api/v1/users/profile    — get own profile
router.get('/profile',    userCtrl.getProfile);

// PUT    /api/v1/users/profile    — update profile fields
router.put('/profile',    userCtrl.updateProfile);

// DELETE /api/v1/users/account   — delete own account
router.delete('/account', userCtrl.deleteAccount);

module.exports = router;
