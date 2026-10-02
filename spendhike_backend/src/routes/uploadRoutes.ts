import { Router, Request, Response } from 'express';
import { authenticateToken } from '../middleware/auth';

const router = Router();

const CLOUDINARY_CLOUD_NAME = process.env.CLOUDINARY_CLOUD_NAME || 'dcbmy6vtg';
const CLOUDINARY_API_KEY = process.env.CLOUDINARY_API_KEY || '286528494914523';
const CLOUDINARY_API_SECRET = process.env.CLOUDINARY_API_SECRET || 'DJhArCgx_4E7XeSAS6VL3clbuJI';

/**
 * POST /api/v1/upload/image
 * Uploads a base64 / binary image to Cloudinary and returns secure URL.
 */
router.post('/image', authenticateToken, async (req: Request, res: Response) => {
  try {
    const { image, folder } = req.body; // base64 string "data:image/png;base64,..." or raw base64
    if (!image) {
      res.status(400).json({ error: 'Image data is required' });
      return;
    }

    const uploadFolder = folder || 'spendhike_attachments';
    const timestamp = Math.floor(Date.now() / 1000);

    // Compute SHA-1 signature for Cloudinary upload
    const crypto = await import('crypto');
    const signatureStr = `folder=${uploadFolder}&timestamp=${timestamp}${CLOUDINARY_API_SECRET}`;
    const signature = crypto.createHash('sha1').update(signatureStr).digest('hex');

    const formData = new URLSearchParams();
    formData.append('file', image);
    formData.append('api_key', CLOUDINARY_API_KEY);
    formData.append('timestamp', timestamp.toString());
    formData.append('folder', uploadFolder);
    formData.append('signature', signature);

    const cloudinaryUrl = `https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD_NAME}/image/upload`;
    const response = await fetch(cloudinaryUrl, {
      method: 'POST',
      body: formData,
    });

    const data: any = await response.json();

    if (!response.ok || data.error) {
      res.status(500).json({
        error: data.error?.message || 'Cloudinary upload failed',
      });
      return;
    }

    res.status(200).json({
      url: data.secure_url,
      public_id: data.public_id,
      format: data.format,
      bytes: data.bytes,
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message || 'Internal upload error' });
  }
});

export default router;
