import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { connectDB } from './config/db';

import authRoutes from './routes/authRoutes';
import groupRoutes from './routes/groupRoutes';
import transactionRoutes from './routes/transactionRoutes';
import reportRoutes from './routes/reportRoutes';
import invitationRoutes from './routes/invitationRoutes';
import uploadRoutes from './routes/uploadRoutes';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;
const BACKEND_SERVER = process.env.BACKEND_SERVER || `http://localhost:${PORT}`;

// ── Middleware ─────────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// ── Database Connection ────────────────────────────────────────────────────
connectDB();

// ── Health Check ───────────────────────────────────────────────────────────
app.get('/health', (req: Request, res: Response) => {
  res.status(200).json({
    status: 'OK',
    service: 'SpendHike Backend API',
    timestamp: new Date().toISOString(),
  });
});

// ── API Routes ─────────────────────────────────────────────────────────────
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/groups', groupRoutes);
app.use('/api/v1/transactions', transactionRoutes);
app.use('/api/v1/reports', reportRoutes);
app.use('/api/v1/invitations', invitationRoutes);
app.use('/api/v1/upload', uploadRoutes);

// ── Start Server ───────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`[SpendHike Backend] Server running on ${BACKEND_SERVER}`);
});
