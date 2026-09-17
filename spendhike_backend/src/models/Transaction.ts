import { Schema, model, Document, Types } from 'mongoose';

export type TransactionType = 'RECEIVED' | 'DEBIT' | 'CREDIT';
export type TransactionCategory =
  | 'LABOUR'
  | 'MATERIAL'
  | 'FUEL'
  | 'UTILITIES'
  | 'RENT'
  | 'OTHER';
export type TransactionStatus = 'SETTLED' | 'PENDING' | 'SCHEDULED';

export interface ITransaction extends Document {
  projectId: Types.ObjectId;
  userId: Types.ObjectId;
  type: TransactionType;
  category: TransactionCategory;
  amount: number;
  description: string;
  transactionDate: Date;
  attachmentUrl?: string;
  status: TransactionStatus;
  paymentMethod: string;
  createdAt: Date;
  updatedAt: Date;
}

const TransactionSchema = new Schema<ITransaction>(
  {
    projectId: { type: Schema.Types.ObjectId, ref: 'ProjectGroup', required: true },
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    type: {
      type: String,
      enum: ['RECEIVED', 'DEBIT', 'CREDIT'],
      required: true,
    },
    category: {
      type: String,
      enum: ['LABOUR', 'MATERIAL', 'FUEL', 'UTILITIES', 'RENT', 'OTHER'],
      default: 'OTHER',
    },
    amount: { type: Number, required: true },
    description: { type: String, default: '' },
    transactionDate: { type: Date, default: Date.now },
    attachmentUrl: { type: String, default: '' },
    status: {
      type: String,
      enum: ['SETTLED', 'PENDING', 'SCHEDULED'],
      default: 'SETTLED',
    },
    paymentMethod: { type: String, default: 'Cash' },
  },
  { timestamps: true }
);

export const Transaction = model<ITransaction>('Transaction', TransactionSchema);
