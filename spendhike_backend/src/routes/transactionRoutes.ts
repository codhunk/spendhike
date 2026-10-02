import { Router } from 'express';
import { createTransaction, getTransactions, updateTransaction } from '../controllers/transactionController';
import { authenticateToken } from '../middleware/auth';

const router = Router();

router.use(authenticateToken);

router.get('/', getTransactions);
router.post('/', createTransaction);
router.put('/:id', updateTransaction);

export default router;
