import { Router } from 'express';
import {
  signup,
  login,
  getProfile,
  updateProfile,
  forgotPassword,
  changePassword,
  searchUsers,
  sendOtp,
  verifyOtp,
  setPasscode,
  verifyPasscode,
  changePasscode,
  verifyPasswordForReset,
  removePasscode,
} from '../controllers/authController';
import { authenticateToken } from '../middleware/auth';

const router = Router();

router.post('/signup', signup);
router.post('/login', login);
router.post('/send-otp', sendOtp);
router.post('/verify-otp', verifyOtp);
router.get('/me', authenticateToken, getProfile);
router.put('/profile', authenticateToken, updateProfile);
router.post('/forgot-password', forgotPassword);
router.post('/change-password', authenticateToken, changePassword);
router.get('/users/search', authenticateToken, searchUsers);

// Passcode Endpoints
router.post('/passcode/set', authenticateToken, setPasscode);
router.post('/passcode/verify', authenticateToken, verifyPasscode);
router.post('/passcode/change', authenticateToken, changePasscode);
router.post('/passcode/verify-password', authenticateToken, verifyPasswordForReset);
router.delete('/passcode', authenticateToken, removePasscode);

export default router;

