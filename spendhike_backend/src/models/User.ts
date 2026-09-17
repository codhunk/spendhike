import { Schema, model, Document } from 'mongoose';

export interface IUser extends Document {
  name: string;
  email: string;
  passwordHash: string;
  mobile?: string;
  company?: string;
  gst?: string;
  address?: string;
  avatarUrl?: string;
  biometricId?: string;
  biometricEnabled?: boolean;
  pinEnabled?: boolean;
  pinCode?: string;
  darkMode?: boolean;
  language?: string;
  createdAt: Date;
  updatedAt: Date;
}

const UserSchema = new Schema<IUser>(
  {
    name: { type: String, required: true, trim: true },
    email: { type: String, default: '', lowercase: true, trim: true },
    passwordHash: { type: String, default: '' },
    mobile: { type: String, default: '', trim: true },
    company: { type: String, default: '' },
    gst: { type: String, default: '' },
    address: { type: String, default: '' },
    avatarUrl: { type: String, default: '' },
    biometricId: { type: String, default: '' },
    biometricEnabled: { type: Boolean, default: false },
    pinEnabled: { type: Boolean, default: false },
    pinCode: { type: String, default: '' },
    darkMode: { type: Boolean, default: false },
    language: { type: String, default: 'English' },
  },
  { timestamps: true }
);

export const User = model<IUser>('User', UserSchema);
