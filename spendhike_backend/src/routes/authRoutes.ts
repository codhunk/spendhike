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

export default router;
