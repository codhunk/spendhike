import { Router } from 'express';
import {
  createInvitation,
  getUserInvitations,
  acceptInvitation,
  rejectInvitation,
} from '../controllers/invitationController';
import { authenticateToken } from '../middleware/auth';

const router = Router();

router.use(authenticateToken);

router.post('/', createInvitation);
router.get('/', getUserInvitations);
router.post('/accept', acceptInvitation);
router.post('/:id/accept', acceptInvitation);
router.post('/:id/reject', rejectInvitation);

export default router;
