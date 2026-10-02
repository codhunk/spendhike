import nodemailer from 'nodemailer';

const DEFAULT_FROM = process.env.EMAIL_FROM || 'SpendHike <noreply@spendhike.com>';

/**
 * Creates and returns a Nodemailer transporter.
 * Uses environment variables for SMTP if provided; otherwise logs to console gracefully in dev.
 */
const getTransporter = () => {
  const host = process.env.SMTP_HOST;
  const port = parseInt(process.env.SMTP_PORT || '587', 10);
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;

  if (host && user && pass) {
    return nodemailer.createTransport({
      host,
      port,
      secure: port === 465,
      auth: { user, pass },
    });
  }

  // Dev fallback: stream transporter or log-to-console transporter
  return nodemailer.createTransport({
    jsonTransport: true,
  });
};

export const sendPasswordResetEmail = async (
  toEmail: string,
  resetTokenOrLink?: string
): Promise<boolean> => {
  try {
    const transporter = getTransporter();
    const fromAddress = DEFAULT_FROM;
    const backendUrl = process.env.BACKEND_SERVER || 'http://localhost:5000';
    const resetUrl = resetTokenOrLink || `${backendUrl}/auth/reset-password`;

    const htmlContent = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e2e8f0; border-radius: 12px; background-color: #ffffff;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h2 style="color: #0453CD; margin: 0;">SpendHike</h2>
          <p style="color: #64748b; font-size: 14px; margin-top: 4px;">Smart Expense & Budget Manager</p>
        </div>
        <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;" />
        <h3 style="color: #1e293b;">Password Reset Request</h3>
        <p style="color: #475569; line-height: 1.6;">
          Hello,
        </p>
        <p style="color: #475569; line-height: 1.6;">
          We received a request to reset your password for your SpendHike account (<strong>${toEmail}</strong>).
        </p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="${resetUrl}" style="background-color: #0453CD; color: #ffffff; padding: 12px 28px; text-decoration: none; border-radius: 8px; font-weight: bold; display: inline-block;">
            Reset Password
          </a>
        </div>
        <p style="color: #64748b; font-size: 13px; line-height: 1.5;">
          If you did not request a password reset, please ignore this email or contact support if you have security concerns.
        </p>
        <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 24px 0;" />
        <p style="color: #94a3b8; font-size: 12px; text-align: center;">
          This is an automated message from SpendHike. Please do not reply to this email.<br/>
          &copy; ${new Date().getFullYear()} SpendHike. All rights reserved.
        </p>
      </div>
    `;

    const mailOptions = {
      from: fromAddress,
      to: toEmail,
      subject: 'SpendHike - Password Reset Request',
      text: `Hello,\n\nWe received a request to reset your password for your SpendHike account (${toEmail}).\n\nPlease use the following link to reset your password:\n${resetUrl}\n\nIf you did not request this, please ignore this email.`,
      html: htmlContent,
    };

    const info = await transporter.sendMail(mailOptions);
    console.log(`[EmailService] Password reset email sent from ${fromAddress} to ${toEmail}:`, info.messageId || info);
    return true;
  } catch (error: any) {
    console.error(`[EmailService] Error sending password reset email to ${toEmail}:`, error.message);
    return false;
  }
};

export const sendPasswordResetSuccessEmail = async (toEmail: string): Promise<boolean> => {
  try {
    const transporter = getTransporter();
    const fromAddress = DEFAULT_FROM;

    const htmlContent = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e2e8f0; border-radius: 12px; background-color: #ffffff;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h2 style="color: #0453CD; margin: 0;">SpendHike</h2>
        </div>
        <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;" />
        <h3 style="color: #10b981;">Password Reset Successful</h3>
        <p style="color: #475569; line-height: 1.6;">
          Your SpendHike password for <strong>${toEmail}</strong> was successfully updated.
        </p>
        <p style="color: #475569; line-height: 1.6;">
          You can now log in to your SpendHike account using your new password.
        </p>
        <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 24px 0;" />
        <p style="color: #94a3b8; font-size: 12px; text-align: center;">
          This is an automated notification from SpendHike. Please do not reply to this email.
        </p>
      </div>
    `;

    const mailOptions = {
      from: fromAddress,
      to: toEmail,
      subject: 'SpendHike - Password Changed Successfully',
      text: `Your SpendHike password for ${toEmail} was successfully updated. You can now log in using your new password.`,
      html: htmlContent,
    };

    const info = await transporter.sendMail(mailOptions);
    console.log(`[EmailService] Password success confirmation sent from ${fromAddress} to ${toEmail}:`, info.messageId || info);
    return true;
  } catch (error: any) {
    console.error(`[EmailService] Error sending password reset success email to ${toEmail}:`, error.message);
    return false;
  }
};
