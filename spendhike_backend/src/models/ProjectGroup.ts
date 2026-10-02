import { Schema, model, Document, Types } from 'mongoose';

export type MemberRole = 'Admin' | 'Manager' | 'Editor' | 'Viewer';

export interface IMember {
  email: string;
  name?: string;
  userId?: Types.ObjectId;
  role: MemberRole;
  addedAt: Date;
}

export interface IProjectGroup extends Document {
  ownerId: Types.ObjectId;
  name: string;
  description: string;
  totalBalance: number;
  status: string;
  icon: string;
  isPrimary: boolean;
  members: IMember[];
  createdAt: Date;
  updatedAt: Date;
}

const MemberSchema = new Schema<IMember>({
  email: { type: String, default: '', lowercase: true, trim: true },
  name: { type: String, default: '' },
  userId: { type: Schema.Types.ObjectId, ref: 'User' },
  role: {
    type: String,
    enum: ['Admin', 'Manager', 'Editor', 'Viewer'],
    default: 'Editor',
  },
  addedAt: { type: Date, default: Date.now },
});

const ProjectGroupSchema = new Schema<IProjectGroup>(
  {
    ownerId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    name: { type: String, required: true, trim: true },
    description: { type: String, default: '' },
    totalBalance: { type: Number, default: 0 },
    status: { type: String, default: 'Active' },
    icon: { type: String, default: 'construction' },
    isPrimary: { type: Boolean, default: false },
    members: [MemberSchema],
  },
  { timestamps: true }
);

export const ProjectGroup = model<IProjectGroup>('ProjectGroup', ProjectGroupSchema);
