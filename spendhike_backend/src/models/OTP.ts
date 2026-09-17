import { Schema, model, Document } from 'mongoose';

export interface IOTP extends Document {
  mobile: string;
  otp: string;
  expiresAt: Date;
}

const OTPSchema = new Schema<IOTP>(
  {
    mobile: { type: String, required: true, trim: true },
    otp: { type: String, required: true },
    expiresAt: { type: Date, required: true, expires: 600 },
  },
  { timestamps: true }
);

export const OTP = model<IOTP>('OTP', OTPSchema);
