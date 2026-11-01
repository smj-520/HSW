const crypto = require('crypto');
const admin = require('firebase-admin');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { setGlobalOptions } = require('firebase-functions/v2');
const nodemailer = require('nodemailer');

admin.initializeApp();
setGlobalOptions({ region: 'us-central1', maxInstances: 10 });

const db = admin.database();
const OTP_TTL_MS = 10 * 60 * 1000;
const RESEND_COOLDOWN_MS = 60 * 1000;
const TOKEN_TTL_MS = 10 * 60 * 1000;
const MAX_ATTEMPTS = 5;
const EMAIL_WINDOW_MS = 10 * 60 * 1000;
const EMAIL_MAX = 3;
const IP_WINDOW_MS = 10 * 60 * 1000;
const IP_MAX = 8;

function pepper() {
  return process.env.OTP_PEPPER || 'set-OTP_PEPPER-before-production';
}

function sha256(value) {
  return crypto.createHmac('sha256', pepper()).update(String(value)).digest('hex');
}

function clientSha(value) {
  return crypto.createHash('sha256').update('otp:' + String(value)).digest('hex');
}

function emailKey(email) {
  return crypto.createHash('sha256').update(String(email).trim().toLowerCase()).digest('hex');
}

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function clientIp(request) {
  const raw = request.rawRequest || {};
  const forwarded = raw.headers && (raw.headers['x-forwarded-for'] || raw.headers['X-Forwarded-For']);
  if (typeof forwarded === 'string' && forwarded.trim()) {
    return forwarded.split(',')[0].trim();
  }
  return raw.ip || 'unknown';
}

function randomOtp() {
  return String(crypto.randomInt(0, 1000000)).padStart(6, '0');
}

function randomToken() {
  return crypto.randomBytes(32).toString('hex');
}

async function bumpRateLimit(path, windowMs, max) {
  const ref = db.ref(path);
  const snap = await ref.get();
  const now = Date.now();
  const row = snap.val() || {};
  const start = Number(row.windowStart) || 0;
  let count = Number(row.count) || 0;
  if (now - start > windowMs) {
    count = 0;
  }
  if (count >= max) {
    throw new HttpsError('resource-exhausted', 'Too many requests. Try again later.');
  }
  await ref.set({
    windowStart: count === 0 || now - start > windowMs ? now : start,
    count: count + 1,
  });
}

function mailer() {
  const user = process.env.MAIL_USER;
  const pass = process.env.MAIL_PASS;
  if (!user || !pass) {
    throw new HttpsError(
      'failed-precondition',
      'Email is not configured. Set MAIL_USER and MAIL_PASS.',
    );
  }
  return nodemailer.createTransport({
    service: 'gmail',
    auth: { user, pass },
  });
}

async function sendOtpEmail(to, code, { minutes, subject }) {
  const from = process.env.MAIL_FROM || process.env.MAIL_USER;
  const transporter = mailer();
  const mins = minutes || 10;
  const title = subject || 'Your verification code';
  const text =
    `Your Hostel Student Wallet verification code is ${code}.\n` +
    `This code expires in ${mins} minutes.\n\n` +
    'If you did not request this code, you can ignore this email. Never share the code with anyone.';
  const html = `
    <div style="font-family:Arial,sans-serif;max-width:520px;line-height:1.5;color:#212529">
      <h2 style="color:#27AE60;margin-bottom:12px">Hostel Student Wallet</h2>
      <p>Use this one-time code to verify your email:</p>
      <p style="font-size:28px;letter-spacing:6px;font-weight:bold;color:#1F4D3D">${code}</p>
      <p>This code expires in <strong>${mins} minutes</strong> and can be used only once.</p>
      <p style="color:#6c757d;font-size:13px">If you did not create an account, ignore this email. Never share this code.</p>
    </div>
  `;
  await transporter.sendMail({
    from,
    to,
    subject: title,
    text,
    html,
  });
}

async function lookupUid(email) {
  try {
    const user = await admin.auth().getUserByEmail(email);
    return user.uid;
  } catch (e) {
    if (e && e.code === 'auth/user-not-found') return null;
    throw e;
  }
}

exports.sendResetOtp = onCall(
  { cors: true, invoker: 'public', secrets: ['MAIL_USER', 'MAIL_PASS', 'OTP_PEPPER'] },
  async (request) => {
    const email = normalizeEmail(request.data && request.data.email);
    if (!email || !email.includes('@')) {
      throw new HttpsError('invalid-argument', 'Enter a valid email address.');
    }
    const ip = clientIp(request);
    await bumpRateLimit(`rateLimits/resetOtp/email/${emailKey(email)}`, EMAIL_WINDOW_MS, EMAIL_MAX);
    await bumpRateLimit(
      `rateLimits/resetOtp/ip/${sha256(ip).slice(0, 32)}`,
      IP_WINDOW_MS,
      IP_MAX,
    );

    const uid = await lookupUid(email);
    if (!uid) {
      return { ok: true };
    }

    const code = randomOtp();
    const now = Date.now();
    const otpRef = db.ref(`passwordResetOtps/${emailKey(email)}`);
    await otpRef.set({
      uid,
      otpHash: sha256(code),
      expiresAt: now + OTP_TTL_MS,
      attempts: 0,
      tokenHash: null,
      tokenExpiresAt: null,
    });
    try {
      await sendOtpEmail(email, code, {
        minutes: 10,
        subject: 'Your password reset code',
      });
    } catch (e) {
      await otpRef.remove();
      throw new HttpsError('internal', 'Could not send the code. Try again later.');
    }
    return { ok: true };
  },
);

exports.verifyResetOtp = onCall(
  { cors: true, invoker: 'public', secrets: ['OTP_PEPPER'] },
  async (request) => {
    const email = normalizeEmail(request.data && request.data.email);
    const code = String((request.data && request.data.code) || '').replace(/\D/g, '');
    if (!email || code.length !== 6) {
      throw new HttpsError('invalid-argument', 'Enter the 6-digit code.');
    }
    const ref = db.ref(`passwordResetOtps/${emailKey(email)}`);
    const snap = await ref.get();
    const row = snap.val();
    if (!row || !row.otpHash) {
      throw new HttpsError('failed-precondition', 'Invalid or expired code.');
    }
    if (Number(row.expiresAt) < Date.now()) {
      await ref.remove();
      throw new HttpsError('failed-precondition', 'Invalid or expired code.');
    }
    const attempts = Number(row.attempts) || 0;
    if (attempts >= MAX_ATTEMPTS) {
      await ref.remove();
      throw new HttpsError('failed-precondition', 'Too many attempts. Request a new code.');
    }
    if (row.otpHash !== sha256(code)) {
      const next = attempts + 1;
      if (next >= MAX_ATTEMPTS) {
        await ref.remove();
        throw new HttpsError('failed-precondition', 'Too many attempts. Request a new code.');
      }
      await ref.update({ attempts: next });
      throw new HttpsError('failed-precondition', 'Invalid or expired code.');
    }
    const resetToken = randomToken();
    await ref.update({
      tokenHash: sha256(resetToken),
      tokenExpiresAt: Date.now() + TOKEN_TTL_MS,
      otpHash: null,
      attempts: 0,
    });
    return { resetToken };
  },
);

exports.confirmResetPassword = onCall(
  { cors: true, invoker: 'public' },
  async (request) => {
    const email = normalizeEmail(request.data && request.data.email);
    const resetToken = String((request.data && request.data.resetToken) || '');
    const password = String((request.data && request.data.password) || '');
    if (!email || !resetToken) {
      throw new HttpsError('invalid-argument', 'Reset session is missing.');
    }
    if (password.length < 8) {
      throw new HttpsError('invalid-argument', 'Use at least 8 characters.');
    }
    const ref = db.ref(`passwordResetOtps/${emailKey(email)}`);
    const snap = await ref.get();
    const row = snap.val();
    if (!row) {
      throw new HttpsError('failed-precondition', 'Invalid or expired reset session.');
    }
    const isOtp = /^\d{6}$/.test(resetToken);
    const expiresAt = Number(isOtp ? row.expiresAt : row.tokenExpiresAt);
    const expected = isOtp ? row.otpHash : row.tokenHash;
    if (!expected || expiresAt < Date.now()) {
      await ref.remove();
      throw new HttpsError('failed-precondition', 'Invalid or expired reset session.');
    }
    const tokenOk = expected === sha256(resetToken) || expected === clientSha(resetToken);
    if (!tokenOk) {
      await ref.remove();
      throw new HttpsError('failed-precondition', 'Invalid or expired reset session.');
    }
    let user;
    try {
      user = await admin.auth().getUserByEmail(email);
    } catch (e) {
      await ref.remove();
      throw new HttpsError('failed-precondition', 'Invalid or expired reset session.');
    }
    await admin.auth().updateUser(user.uid, { password });
    await ref.remove();
    return { ok: true };
  },
);
