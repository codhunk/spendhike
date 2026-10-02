import { Schema, model, Document, Types } from 'mongoose';

export type InvitationStatus = 'PENDING' | 'ACCEPTED' | 'REJECTED';

export interface IInvitation extends Document {
  groupId: Types.ObjectId;
  invitedBy: Types.ObjectId;
  recipientEmailOrPhone: string;
  recipientUserId?: Types.ObjectId;
  role: string;
  status: InvitationStatus;
  invitationCode: string;
  createdAt: Date;
  updatedAt: Date;
}

const InvitationSchema = new Schema<IInvitation>(
  {
    groupId: { type: Schema.Types.ObjectId, ref: 'ProjectGroup', required: true },
    invitedBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    recipientEmailOrPhone: { type: String, required: true, lowercase: true, trim: true },
    recipientUserId: { type: Schema.Types.ObjectId, ref: 'User' },
    role: { type: String, default: 'Editor' },
    status: { type: String, enum: ['PENDING', 'ACCEPTED', 'REJECTED'], default: 'PENDING' },
    invitationCode: { type: String, required: true, unique: true },
  },
  { timestamps: true }
);

export const Invitation = model<IInvitation>('Invitation', InvitationSchema);
