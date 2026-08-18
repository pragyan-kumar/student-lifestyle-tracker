const express    = require('express');
const { body }   = require('express-validator');
const router     = express.Router();
const authCtrl   = require('../controllers/auth.controller');
const { authenticate } = require('../middleware/auth.middleware');
const validate   = require('../middleware/validate.middleware');

// POST /api/v1/auth/register
router.post('/register',
  [
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  ],
  validate,
  authCtrl.register,
);

// POST /api/v1/auth/login
router.post('/login',
  [
    body('email').isEmail().normalizeEmail(),
    body('password').notEmpty(),
  ],
  validate,
  authCtrl.login,
);

// POST /api/v1/auth/google  — Firebase ID token exchange
router.post('/google', authCtrl.googleAuth);

// POST /api/v1/auth/refresh
router.post('/refresh', authCtrl.refreshToken);

// POST /api/v1/auth/logout  (protected)
router.post('/logout', authenticate, authCtrl.logout);

// GET /api/v1/auth/me  (protected)
router.get('/me', authenticate, authCtrl.getMe);

module.exports = router;
