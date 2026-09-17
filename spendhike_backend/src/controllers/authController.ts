import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { User } from '../models/User';
import { Invitation } from '../models/Invitation';
import { AuthRequest } from '../middleware/auth';
import { sendPasswordResetEmail, sendPasswordResetSuccessEmail } from '../services/emailService';

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const generateToken = (userId: string, email: string): string => {
  const secret = process.env.JWT_SECRET || 'spendhike_secret_jwt_key_2026_x99a';
  return jwt.sign({ userId, email }, secret, { expiresIn: '24h' });
};

export const signup = async (req: Request, res: Response): Promise<void> => {
  try {
    let { name, email, password, mobile, company } = req.body;

    name = (name || '').trim();
    email = (email || '').trim().toLowerCase();
    password = (password || '').trim();

    if (!name || name.length < 2) {
      res.status(400).json({ success: false, message: 'Name must be at least 2 characters long' });
      return;
    }

    if (!email || !EMAIL_REGEX.test(email)) {
      res.status(400).json({ success: false, message: 'Please enter a valid email address' });
      return;
    }

    if (!password || password.length < 6) {
      res.status(400).json({ success: false, message: 'Password must be at least 6 characters long' });
      return;
    }

    const cleanMobile = (mobile || '').toString().replace(/\D/g, '');
    if (cleanMobile.length > 0 && cleanMobile.length !== 10) {
      res.status(400).json({ success: false, message: 'Mobile number must be a valid 10-digit number' });
      return;
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      res.status(409).json({ success: false, message: 'This email address is already registered. Please sign in instead.' });
      return;
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    const user = await User.create({
      name,
      email,
      passwordHash,
      mobile: (mobile || '').trim(),
      company: (company || '').trim(),
    });

    // Auto-link pending invitations for new user
    await Invitation.updateMany(
      {
        recipientEmailOrPhone: { $in: [email, mobile || ''] },
        status: 'PENDING',
      },
      { recipientUserId: user._id }
    );

    const token = generateToken(user._id.toString(), user.email);

    res.status(201).json({
      success: true,
      message: 'Account created successfully',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        mobile: user.mobile,
        company: user.company,
        gst: user.gst,
        address: user.address,
        avatarUrl: user.avatarUrl,
        biometricEnabled: user.biometricEnabled,
        pinEnabled: user.pinEnabled,
        darkMode: user.darkMode,
        language: user.language,
      },
    });
  } catch (error: any) {
    if (error.code === 11000 || error.message?.includes('duplicate key')) {
      res.status(409).json({ success: false, message: 'This email address is already registered. Please sign in instead.' });
      return;
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    let { email, password } = req.body;

    email = (email || '').trim().toLowerCase();
    password = (password || '').trim();

    if (!email || !EMAIL_REGEX.test(email)) {
      res.status(400).json({ success: false, message: 'Please enter a valid email address' });
      return;
    }

    if (!password) {
      res.status(400).json({ success: false, message: 'Please enter your password' });
      return;
    }

    const user = await User.findOne({ email });
    if (!user) {
      res.status(401).json({ success: false, message: 'No account found with this email address. Please check your email or sign up.' });
      return;
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      res.status(401).json({ success: false, message: 'Incorrect password. Please try again.' });
      return;
    }

    const token = generateToken(user._id.toString(), user.email);

    res.status(200).json({
      success: true,
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        mobile: user.mobile,
        company: user.company,
        gst: user.gst,
        address: user.address,
        avatarUrl: user.avatarUrl,
        biometricEnabled: user.biometricEnabled,
        pinEnabled: user.pinEnabled,
        darkMode: user.darkMode,
        language: user.language,
      },
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getProfile = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    const user = await User.findById(userId).select('-passwordHash -pinCode');

    if (!user) {
      res.status(404).json({ success: false, message: 'User not found' });
      return;
    }

    res.status(200).json({ success: true, user });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const updateProfile = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    const {
      name,
      mobile,
      company,
      gst,
      address,
      avatarUrl,
      biometricEnabled,
      pinEnabled,
      pinCode,
      darkMode,
      language,
    } = req.body;

    const updates: any = {};
    if (name !== undefined) updates.name = name;
    if (mobile !== undefined) updates.mobile = mobile;
    if (company !== undefined) updates.company = company;
    if (gst !== undefined) updates.gst = gst;
    if (address !== undefined) updates.address = address;
    if (avatarUrl !== undefined) updates.avatarUrl = avatarUrl;
    if (biometricEnabled !== undefined) updates.biometricEnabled = biometricEnabled;
    if (pinEnabled !== undefined) updates.pinEnabled = pinEnabled;
    if (pinCode !== undefined) updates.pinCode = pinCode;
    if (darkMode !== undefined) updates.darkMode = darkMode;
    if (language !== undefined) updates.language = language;

    const updatedUser = await User.findByIdAndUpdate(userId, { $set: updates }, { new: true }).select('-passwordHash -pinCode');

    if (!updatedUser) {
      res.status(404).json({ success: false, message: 'User not found' });
      return;
    }

    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      user: updatedUser,
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const forgotPassword = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, newPassword } = req.body;
    if (!email) {
      res.status(400).json({ success: false, message: 'Email is required' });
      return;
    }

    const user = await User.findOne({ email: email.trim().toLowerCase() });
    if (!user) {
      res.status(404).json({ success: false, message: 'User with this email not found' });
      return;
    }

    if (newPassword) {
      const salt = await bcrypt.genSalt(10);
      user.passwordHash = await bcrypt.hash(newPassword, salt);
      await user.save();

      // Send confirmation email asynchronously
      await sendPasswordResetSuccessEmail(user.email);

      res.status(200).json({
        success: true,
        message: 'Password reset successfully! You can now log in with your new password.',
      });
      return;
    }

    // Send password reset email from noreply@spendhike.com
    await sendPasswordResetEmail(user.email);

    res.status(200).json({
      success: true,
      message: 'Password reset link sent to your email from noreply@spendhike.com.',
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const changePassword = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    const { oldPassword, newPassword } = req.body;

    if (!oldPassword || !newPassword) {
      res.status(400).json({ success: false, message: 'Both current and new passwords are required' });
      return;
    }

    const user = await User.findById(userId);
    if (!user) {
      res.status(404).json({ success: false, message: 'User not found' });
      return;
    }

    const isMatch = await bcrypt.compare(oldPassword, user.passwordHash);
    if (!isMatch) {
      res.status(400).json({ success: false, message: 'Current password is incorrect' });
      return;
    }

    const salt = await bcrypt.genSalt(10);
    user.passwordHash = await bcrypt.hash(newPassword, salt);
    await user.save();

    res.status(200).json({
      success: true,
      message: 'Password changed successfully',
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const searchUsers = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { query } = req.query;
    if (!query || typeof query !== 'string' || query.trim().length === 0) {
      res.status(200).json({ success: true, users: [] });
      return;
    }

    const searchParam = query.trim();
    const searchRegex = new RegExp(searchParam, 'i');
    const users = await User.find({
      $or: [
        { email: searchRegex },
        { name: searchRegex },
        { mobile: searchRegex },
      ],
    })
      .select('name email mobile company avatarUrl')
      .limit(10);

    res.status(200).json({
      success: true,
      users: users.map((u) => ({
        id: u._id,
        name: u.name,
        email: u.email,
        mobile: u.mobile,
        company: u.company,
        avatarUrl: u.avatarUrl,
      })),
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const otpStore = new Map<string, { otp: string; expiresAt: number }>();

export const sendOtp = async (req: Request, res: Response): Promise<void> => {
  try {
    let { mobile } = req.body;
    const cleanMobile = (mobile || '').toString().replace(/\D/g, '');

    if (!cleanMobile || cleanMobile.length < 10) {
      res.status(400).json({ success: false, message: 'Please enter a valid 10-digit mobile number' });
      return;
    }

    const generatedOtp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 5 * 60 * 1000;

    otpStore.set(cleanMobile, { otp: generatedOtp, expiresAt });

    const smsApiKey = process.env.FAST2SMS_API_KEY || process.env.SMS_GATEWAY_API_KEY;
    let liveSmsSent = false;

    if (smsApiKey) {
      try {
        // Fast2SMS / HTTP SMS Gateway integration
        const response = await fetch(
          `https://www.fast2sms.com/dev/bulkV2?authorization=${smsApiKey}&route=otp&variables_values=${generatedOtp}&numbers=${cleanMobile}`
        );
        liveSmsSent = response.ok;
      } catch (err) {
        console.error('[SMS Gateway Error]:', err);
      }
    }

    const messageText = liveSmsSent
      ? `OTP sent to +91 ${cleanMobile} via SMS.`
      : `OTP sent successfully to +91 ${cleanMobile}. (Demo OTP: ${generatedOtp})`;

    res.status(200).json({
      success: true,
      message: messageText,
      otp: generatedOtp,
      mobile: cleanMobile,
      liveSmsSent,
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const verifyOtp = async (req: Request, res: Response): Promise<void> => {
  try {
    let { mobile, otp, name } = req.body;
    const cleanMobile = (mobile || '').toString().replace(/\D/g, '');
    const cleanOtp = (otp || '').toString().trim();

    if (!cleanMobile || cleanMobile.length < 10) {
      res.status(400).json({ success: false, message: 'Valid 10-digit mobile number is required' });
      return;
    }

    if (!cleanOtp || cleanOtp.length !== 6) {
      res.status(400).json({ success: false, message: 'Please enter a 6-digit verification OTP' });
      return;
    }

    const storedData = otpStore.get(cleanMobile);
    const isTestOtp = cleanOtp === '123456';
    const isValidStoredOtp = storedData && storedData.otp === cleanOtp && storedData.expiresAt > Date.now();

    if (!isTestOtp && !isValidStoredOtp) {
      res.status(400).json({ success: false, message: 'Invalid or expired OTP. Please enter 123456 or request a new OTP.' });
      return;
    }

    otpStore.delete(cleanMobile);

    const defaultEmail = `user_${cleanMobile}@spendhike.app`;
    let user = await User.findOne({
      $or: [{ mobile: cleanMobile }, { email: defaultEmail }],
    });

    if (!user) {
      const salt = await bcrypt.genSalt(10);
      const passwordHash = await bcrypt.hash(`otp_${cleanMobile}`, salt);
      const userName = (name || '').trim() || `Member ${cleanMobile.slice(-4)}`;

      user = await User.create({
        name: userName,
        email: defaultEmail,
        passwordHash,
        mobile: cleanMobile,
      });

      await Invitation.updateMany(
        {
          recipientEmailOrPhone: { $in: [cleanMobile, defaultEmail] },
          status: 'PENDING',
        },
        { recipientUserId: user._id }
      );
    }

    const token = generateToken(user._id.toString(), user.email);

    res.status(200).json({
      success: true,
      message: 'Mobile OTP authentication successful',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        mobile: user.mobile,
        company: user.company,
        gst: user.gst,
        address: user.address,
        avatarUrl: user.avatarUrl,
        biometricEnabled: user.biometricEnabled,
        pinEnabled: user.pinEnabled,
        darkMode: user.darkMode,
        language: user.language,
      },
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};
