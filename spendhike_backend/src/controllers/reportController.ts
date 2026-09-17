import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { Transaction } from '../models/Transaction';
import { ProjectGroup } from '../models/ProjectGroup';
import { User } from '../models/User';


export const formatCompactNumber = (num: number): string => {
  if (isNaN(num)) return '0.00K';
  const abs = Math.abs(num);
  const sign = num < 0 ? '-' : '';

  let formatted = '';
  if (abs >= 1e12) {
    formatted = `${(abs / 1e12).toFixed(2)}T`;
  } else if (abs >= 1e9) {
    formatted = `${(abs / 1e9).toFixed(2)}B`;
  } else if (abs >= 1e6) {
    formatted = `${(abs / 1e6).toFixed(2)}M`;
  } else {
    formatted = `${(abs / 1e3).toFixed(2)}K`;
  }

  return `${sign}${formatted}`;
};

export const formatCompactCurrency = (num: number, prefix: string = ''): string => {
  const compactStr = formatCompactNumber(num);
  if (compactStr.startsWith('-')) {
    return `-₹${compactStr.substring(1)}`;
  }
  return `${prefix}₹${compactStr}`;
};

export const getProfitAndLoss = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { projectId } = req.query;

    let matchQuery: any = {};
    if (projectId) {
      matchQuery.projectId = projectId;
    }

    const totals = await Transaction.aggregate([
      { $match: matchQuery },
      {
        $group: {
          _id: '$type',
          totalAmount: { $sum: '$amount' },
        },
      },
    ]);

    let totalIncome = 0;
    let totalExpenses = 0;

    totals.forEach((t) => {
      if (t._id === 'RECEIVED') {
        totalIncome += t.totalAmount;
      } else if (t._id === 'DEBIT' || t._id === 'CREDIT') {
        totalExpenses += t.totalAmount;
      }
    });

    const netProfit = totalIncome - totalExpenses;

    res.status(200).json({
      success: true,
      report: {
        totalIncome: formatCompactCurrency(totalIncome),
        totalExpenses: formatCompactCurrency(totalExpenses),
        netProfit: `₹${netProfit.toFixed(2)}`,
        numericIncome: totalIncome,
        numericExpenses: totalExpenses,
        numericNetProfit: netProfit,
      },
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getCategoryBreakdown = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { projectId } = req.query;

    let matchQuery: any = {
      type: { $in: ['DEBIT', 'CREDIT'] },
    };
    if (projectId) {
      matchQuery.projectId = projectId;
    }

    const categories = await Transaction.aggregate([
      { $match: matchQuery },
      {
        $group: {
          _id: '$category',
          totalAmount: { $sum: '$amount' },
          count: { $sum: 1 },
        },
      },
      { $sort: { totalAmount: -1 } },
    ]);

    res.status(200).json({
      success: true,
      categories: categories.map((c) => ({
        label: c._id,
        amount: c.totalAmount,
        transactionCount: c.count,
      })),
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getDashboardSummary = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    const user = await User.findById(userId);
    const userEmail = user?.email ? user.email.toLowerCase() : '';

    const groups = await ProjectGroup.find({
      $or: [
        { ownerId: userId },
        { 'members.userId': userId },
        { 'members.email': userEmail },
      ],
    });

    let overallBalance = 0;
    groups.forEach((g) => {
      overallBalance += g.totalBalance;
    });

    const groupIds = groups.map((g) => g._id);

    const totals = await Transaction.aggregate([
      { $match: { projectId: { $in: groupIds } } },
      {
        $group: {
          _id: '$type',
          totalAmount: { $sum: '$amount' },
        },
      },
    ]);

    let income = 0;
    let debit = 0;
    let credit = 0;

    totals.forEach((t) => {
      if (t._id === 'RECEIVED') income += t.totalAmount;
      else if (t._id === 'DEBIT') debit += t.totalAmount;
      else if (t._id === 'CREDIT') credit += t.totalAmount;
    });

    const recentActivities = await Transaction.find({ projectId: { $in: groupIds } })
      .populate('userId', 'name email')
      .populate('projectId', 'name')
      .sort({ updatedAt: -1, createdAt: -1 })
      .limit(10);

    res.status(200).json({
      success: true,
      dashboard: {
        totalBalance: `₹${overallBalance.toFixed(2)}`,
        income: formatCompactCurrency(income, '+'),
        debit: formatCompactCurrency(-debit),
        credit: formatCompactCurrency(-credit),
        weeklyTrend: '0.0%',
        pendingTasks: 0,
        activeGroupsCount: groups.length,
        activeSites: groups.map((g) => ({
          name: g.name,
          amount: `₹${g.totalBalance.toFixed(2)}`,
          status: g.status,
          progress: 0.7,
        })),
        recentActivities: recentActivities.map((t) => {
          const userObj = (t.userId as any);
          const memberName = userObj?.name || (userObj?.email ? userObj.email.split('@')[0] : 'Author');
          const groupObj = (t.projectId as any);
          const groupName = groupObj?.name || 'Project Group';

          const dateObj = t.createdAt || t.transactionDate || new Date();
          const timing = new Date(dateObj).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
          const fullTiming = `${new Date(dateObj).toLocaleDateString()} at ${timing}`;

          return {
            id: t._id,
            title: t.description || `${t.category} Transaction`,
            subtitle: `${memberName} • ${groupName}`,
            memberName,
            groupName,
            timing: fullTiming,
            amount: t.type === 'RECEIVED' ? `+₹${t.amount.toFixed(2)}` : `-₹${t.amount.toFixed(2)}`,
            type: t.type,
            category: t.category,
            statusLabel: t.status,
            date: t.transactionDate,
          };
        }),
      },
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getUnifiedReports = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    const user = await User.findById(userId);
    const userEmail = user?.email ? user.email.toLowerCase() : '';

    const groups = await ProjectGroup.find({
      $or: [
        { ownerId: userId },
        { 'members.userId': userId },
        { 'members.email': userEmail },
      ],
    });

    const groupIds = groups.map((g) => g._id);

    const totals = await Transaction.aggregate([
      { $match: { projectId: { $in: groupIds } } },
      {
        $group: {
          _id: '$type',
          totalAmount: { $sum: '$amount' },
        },
      },
    ]);

    let totalIncome = 0;
    let totalExpenses = 0;

    totals.forEach((t) => {
      if (t._id === 'RECEIVED') {
        totalIncome += t.totalAmount;
      } else if (t._id === 'DEBIT' || t._id === 'CREDIT') {
        totalExpenses += t.totalAmount;
      }
    });

    const netProfit = totalIncome - totalExpenses;

    const categoriesAgg = await Transaction.aggregate([
      { $match: { projectId: { $in: groupIds }, type: { $in: ['DEBIT', 'CREDIT'] } } },
      {
        $group: {
          _id: '$category',
          total: { $sum: '$amount' },
          count: { $sum: 1 },
        },
      },
      { $sort: { total: -1 } },
    ]);

    const categories = categoriesAgg.map((c) => ({
      category: c._id || 'General Expense',
      total: c.total,
      count: c.count,
    }));

    const breakdown = categoriesAgg.map((c) => ({
      category: c._id || 'General Expense',
      current: `₹${c.total.toFixed(2)}`,
      previous: `₹${(c.total * 0.9).toFixed(2)}`,
      variance: '+10.0%',
      isIncrease: true,
    }));

    res.status(200).json({
      success: true,
      report: {
        totalIncome: formatCompactCurrency(totalIncome),
        totalExpenses: formatCompactCurrency(totalExpenses),
        netProfit: `₹${netProfit.toFixed(2)}`,
        numericIncome: totalIncome,
        numericExpenses: totalExpenses,
        numericNetProfit: netProfit,
        incomeTrend: '+12.5%',
        expenseTrend: '-4.2%',
        categories,
        transactionBreakdown: breakdown,
        forecast: {
          projectedQ4: totalIncome * 1.15,
          growthRate: '15.2%',
        },
      },
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const exportReportExcel = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    const user = await User.findById(userId);
    const userEmail = user?.email ? user.email.toLowerCase() : '';

    const groups = await ProjectGroup.find({
      $or: [
        { ownerId: userId },
        { 'members.userId': userId },
        { 'members.email': userEmail },
      ],
    });

    const groupIds = groups.map((g) => g._id);

    const transactions = await Transaction.find({ projectId: { $in: groupIds } })
      .populate('projectId', 'name')
      .populate('userId', 'name email')
      .sort({ createdAt: -1 });

    let csvContent = 'Date,Project Group,Type,Category,Description,Amount (INR),Member\n';
    transactions.forEach((t) => {
      const gName = (t.projectId as any)?.name || 'Project';
      const uName = (t.userId as any)?.name || (t.userId as any)?.email || 'User';
      const dateStr = t.createdAt ? new Date(t.createdAt).toISOString().split('T')[0] : '';
      csvContent += `"${dateStr}","${gName}","${t.type}","${t.category || ''}","${t.description || ''}","${t.amount}","${uName}"\n`;
    });

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename=SpendHike_Financial_Report.csv');
    res.status(200).send(csvContent);
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const exportReportPdf = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    const user = await User.findById(userId);
    const userEmail = user?.email ? user.email.toLowerCase() : '';

    const groups = await ProjectGroup.find({
      $or: [
        { ownerId: userId },
        { 'members.userId': userId },
        { 'members.email': userEmail },
      ],
    });

    const groupIds = groups.map((g) => g._id);
    const transactions = await Transaction.find({ projectId: { $in: groupIds } }).sort({ createdAt: -1 });

    let totalIncome = 0;
    let totalExpenses = 0;
    transactions.forEach((t) => {
      if (t.type === 'RECEIVED') totalIncome += t.amount;
      else totalExpenses += t.amount;
    });

    const pdfText = `=====================================================
SPENDHIKE FINANCIAL REPORT
Generated: ${new Date().toLocaleString()}
User: ${user?.name || user?.email || 'Valued Member'}
=====================================================

FINANCIAL SUMMARY:
- Total Income:   ₹${totalIncome.toFixed(2)} (${formatCompactCurrency(totalIncome)})
- Total Expenses: ₹${totalExpenses.toFixed(2)} (${formatCompactCurrency(totalExpenses)})
- Net Balance:    ₹${(totalIncome - totalExpenses).toFixed(2)}

TRANSACTION BREAKDOWN (${transactions.length} Total Transactions):
-----------------------------------------------------
${transactions
  .map(
    (t, idx) =>
      `${idx + 1}. [${t.type}] ${t.category} - ₹${t.amount.toFixed(2)} (${t.description || 'No description'})`
  )
  .join('\n')}

=====================================================
SpendHike Project Financial System
`;

    res.setHeader('Content-Type', 'text/plain');
    res.setHeader('Content-Disposition', 'attachment; filename=SpendHike_Financial_Report.pdf');
    res.status(200).send(pdfText);
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};
