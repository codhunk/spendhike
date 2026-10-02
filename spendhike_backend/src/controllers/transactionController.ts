import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { Transaction } from '../models/Transaction';
import { ProjectGroup } from '../models/ProjectGroup';

export const createTransaction = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    const { projectId, type, category, amount, description, transactionDate, attachmentUrl, paymentMethod, status } = req.body;

    if (!projectId || !type || amount === undefined) {
      res.status(400).json({ success: false, message: 'projectId, type, and amount are required' });
      return;
    }

    const numericAmount = Number(amount);
    if (isNaN(numericAmount)) {
      res.status(400).json({ success: false, message: 'Amount must be a valid number' });
      return;
    }

    const project = await ProjectGroup.findById(projectId);
    if (!project) {
      res.status(404).json({ success: false, message: 'Target project group not found' });
      return;
    }

    const transaction = await Transaction.create({
      projectId,
      userId,
      type,
      category: category || 'OTHER',
      amount: numericAmount,
      description: description || '',
      transactionDate: transactionDate ? new Date(transactionDate) : new Date(),
      attachmentUrl: attachmentUrl || '',
      paymentMethod: paymentMethod || 'Cash',
      status: status || 'SETTLED',
    });

    // ── Real-time Balancing Key Logic ──────────────────────────────────────
    const delta = type === 'RECEIVED' ? numericAmount : -numericAmount;
    project.totalBalance += delta;
    await project.save();

    res.status(201).json({
      success: true,
      message: 'Transaction saved and project balance updated successfully',
      transaction,
      newBalance: project.totalBalance,
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getTransactions = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { projectId, type, category, limit = 50 } = req.query;

    let query: any = {};
    if (projectId) query.projectId = projectId;
    
    if (type) {
      const typeStr = String(type).toUpperCase();
      if (typeStr === 'RECEIVED') {
        query.type = 'RECEIVED';
      } else if (typeStr === 'SPENT') {
        query.type = { $in: ['DEBIT', 'CREDIT'] };
      } else {
        query.type = typeStr;
      }
    }

    if (category) query.category = category;

    const transactions = await Transaction.find(query)
      .populate('userId', 'name email')
      .populate('projectId', 'name')
      .sort({ transactionDate: -1 })
      .limit(Number(limit));

    res.status(200).json({ success: true, count: transactions.length, transactions });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const updateTransaction = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { type, category, amount, description, paymentMethod, status } = req.body;

    const existingTx = await Transaction.findById(id);
    if (!existingTx) {
      res.status(404).json({ success: false, message: 'Transaction not found' });
      return;
    }

    const project = await ProjectGroup.findById(existingTx.projectId);

    // Revert old transaction effect on project balance
    if (project) {
      const oldDelta = existingTx.type === 'RECEIVED' ? existingTx.amount : -existingTx.amount;
      project.totalBalance -= oldDelta;
    }

    // Apply updates
    if (type) existingTx.type = type;
    if (category) existingTx.category = category;
    if (amount !== undefined) existingTx.amount = Number(amount);
    if (description !== undefined) existingTx.description = description;
    if (paymentMethod) existingTx.paymentMethod = paymentMethod;
    if (status) existingTx.status = status;

    await existingTx.save();

    // Re-apply new transaction effect on project balance
    if (project) {
      const newDelta = existingTx.type === 'RECEIVED' ? existingTx.amount : -existingTx.amount;
      project.totalBalance += newDelta;
      await project.save();
    }

    res.status(200).json({
      success: true,
      message: 'Transaction updated successfully',
      transaction: existingTx,
      newBalance: project ? project.totalBalance : 0,
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};
