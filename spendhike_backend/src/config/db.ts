import mongoose from 'mongoose';

export const connectDB = async (): Promise<void> => {
  try {
    const connStr = process.env.MONGODB_URI || '';
    if (!connStr) {
      throw new Error('MONGODB_URI environment variable is not defined.');
    }

    const conn = await mongoose.connect(connStr, {
      family: 4,
    });
    console.log(`[MongoDB] Connected to Host: ${conn.connection.host}`);
  } catch (error) {
    console.error(`[MongoDB Error] Connection Failed:`, error);
    process.exit(1);
  }
};
