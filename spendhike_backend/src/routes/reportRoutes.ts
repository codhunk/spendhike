import { Router } from 'express';
import {
  getProfitAndLoss,
  getCategoryBreakdown,
  getDashboardSummary,
  getUnifiedReports,
  exportReportExcel,
  exportReportPdf,
} from '../controllers/reportController';
import { authenticateToken } from '../middleware/auth';

const router = Router();

router.use(authenticateToken);

router.get('/', getUnifiedReports);
router.get('/profit-loss', getProfitAndLoss);
router.get('/categories', getCategoryBreakdown);
router.get('/dashboard', getDashboardSummary);
router.get('/export/excel', exportReportExcel);
router.get('/export/pdf', exportReportPdf);

export default router;
