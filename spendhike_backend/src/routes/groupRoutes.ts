import { Router } from 'express';
import { getGroups, createGroup, getGroupById, addMember, getMembers, removeMember } from '../controllers/groupController';
import { authenticateToken } from '../middleware/auth';

const router = Router();

router.use(authenticateToken);

router.get('/', getGroups);
router.post('/', createGroup);
router.get('/:id', getGroupById);
router.post('/:id/members', addMember);
router.get('/:id/members', getMembers);
router.delete('/:id/members/:memberId', removeMember);

export default router;
