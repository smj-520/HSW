const titleEl = document.getElementById('title');
const subtitleEl = document.getElementById('subtitle');
const messageEl = document.getElementById('message');
const otpSection = document.getElementById('otpSection');
const otpCodeEl = document.getElementById('otpCode');
const otpBtn = document.getElementById('otpBtn');
const resetSection = document.getElementById('resetSection');
const saveBtn = document.getElementById('saveBtn');
const brandName = document.getElementById('brandName');

const query = new URLSearchParams(window.location.search);
const mode = query.get('mode');
const oobCode = query.get('oobCode');
const continueUrl = query.get('continueUrl');

let apiKey = '';
let databaseURL = '';
let appName = 'Hostel Student Wallet';
let configuredContinueUrl = '';
let recoveredEmail = '';

function setMessage(type, text) {
  messageEl.className = `alert ${type}`;
  messageEl.textContent = text;
}

function mapError(code) {
  switch (code) {
    case 'INVALID_OOB_CODE':
      return 'This link is invalid or already used.';
    case 'EXPIRED_OOB_CODE':
      return 'This link has expired. Please request a new one.';
    case 'USER_DISABLED':
      return 'This account is disabled. Contact support.';
    case 'WEAK_PASSWORD':
      return 'Password does not meet requirements: at least 8 characters with uppercase, lowercase, a number, and a symbol.';
    default:
      return code || 'Unexpected error. Please try again.';
  }
}

async function firebasePost(endpoint, payload) {
  const url = `https://identitytoolkit.googleapis.com/v1/${endpoint}?key=${encodeURIComponent(apiKey)}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  const data = await res.json();
  if (!res.ok) {
    const code = data?.error?.message;
    throw new Error(mapError(code));
  }
  return data;
}

function setStaticNav() {
  void continueUrl;
  void configuredContinueUrl;
}

const MIN_PASSWORD_LEN = 8;

function validatePassword(pass) {
  if (!pass || pass.length < MIN_PASSWORD_LEN) {
    return `Use at least ${MIN_PASSWORD_LEN} characters.`;
  }
  if (!/[A-Z]/.test(pass)) {
    return 'Include at least one uppercase letter (A–Z).';
  }
  if (!/[a-z]/.test(pass)) {
    return 'Include at least one lowercase letter (a–z).';
  }
  if (!/\d/.test(pass)) {
    return 'Include at least one number (0–9).';
  }
  if (!/[^A-Za-z0-9\s]/.test(pass)) {
    return 'Include at least one symbol (e.g. ! @ # $ % ^ & *).';
  }
  return null;
}

function otpFromLink() {
  const direct = (query.get('otp') || '').trim();
  if (/^\d{6}$/.test(direct)) return direct;
  if (!continueUrl) return '';
  try {
    const nested = new URL(continueUrl).searchParams.get('otp') || '';
    return /^\d{6}$/.test(nested.trim()) ? nested.trim() : '';
  } catch (e) {
    return '';
  }
}

async function sha256Hex(text) {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

async function otpMatchesDatabase(email, digits) {
  if (!databaseURL || !email) return false;
  const key = await sha256Hex(String(email).trim().toLowerCase());
  const url = `${databaseURL.replace(/\/$/, '')}/passwordResetOtps/${key}.json`;
  const res = await fetch(url);
  if (!res.ok) return false;
  const row = await res.json();
  if (!row || !row.otpHash) return false;
  if (Number(row.expiresAt) < Date.now()) return false;
  const hash = await sha256Hex(`otp:${digits}`);
  return hash === row.otpHash;
}

async function checkEnteredOtp() {
  const digits = (otpCodeEl.value || '').replace(/\D/g, '');
  if (digits.length !== 6) {
    throw new Error('Enter the 6-digit code from the email link.');
  }
  const fromLink = otpFromLink();
  if (fromLink && digits === fromLink) return true;
  const ok = await otpMatchesDatabase(recoveredEmail, digits);
  if (!ok) {
    throw new Error('Invalid or expired code.');
  }
  return true;
}

function showOtpStep(onVerified) {
  otpSection.classList.remove('hidden');
  setMessage('info', 'Enter the 6-digit code from the email link (otp=), then continue.');
  otpBtn.onclick = async () => {
    otpBtn.disabled = true;
    try {
      await checkEnteredOtp();
      otpSection.classList.add('hidden');
      await onVerified();
    } catch (e) {
      setMessage('error', e.message || 'Invalid code.');
      otpBtn.disabled = false;
    }
  };
}

async function handleVerifyEmail() {
  titleEl.textContent = 'Verify your email';
  subtitleEl.textContent = 'Enter the 6-digit code, then we will verify your email';
  recoveredEmail = '';
  showOtpStep(async () => {
    await firebasePost('accounts:update', { oobCode });
    subtitleEl.textContent = 'Email verified';
    setMessage('success', 'Your email is verified successfully. You can sign in now.');
  });
}

async function handleRecoverEmail() {
  titleEl.textContent = 'Recover email';
  subtitleEl.textContent = 'Restoring your account email…';
  await firebasePost('accounts:update', { oobCode });
  subtitleEl.textContent = 'Email recovered';
  setMessage('success', 'Your previous email has been restored.');
}

async function handleResetPassword() {
  titleEl.textContent = 'Reset password';
  subtitleEl.textContent = 'Verify the 6-digit code, then create a new password';
  try {
    const data = await firebasePost('accounts:resetPassword', { oobCode });
    recoveredEmail = data.email || '';
  } catch (e) {
    throw e;
  }
  showOtpStep(async () => {
    setMessage('info', 'Choose a new password for your Hostel Student Wallet account.');
    resetSection.classList.remove('hidden');
  });

  saveBtn.addEventListener('click', async () => {
    const pass = document.getElementById('newPassword').value.trim();
    const confirm = document.getElementById('confirmPassword').value.trim();

    const passErr = validatePassword(pass);
    if (passErr) {
      setMessage('error', passErr);
      return;
    }
    if (pass !== confirm) {
      setMessage('error', 'Passwords do not match.');
      return;
    }

    saveBtn.disabled = true;
    saveBtn.innerHTML = '<span class="spinner"></span>Saving…';
    try {
      await firebasePost('accounts:resetPassword', { oobCode });
      await firebasePost('accounts:resetPassword', {
        oobCode,
        newPassword: pass,
      });
      setMessage('success', 'Password updated successfully. You can log in now.');
      resetSection.classList.add('hidden');
      saveBtn.innerHTML = 'Save password';
    } catch (e) {
      setMessage('error', e.message);
      saveBtn.disabled = false;
      saveBtn.innerHTML = 'Save password';
    }
  });
}

async function bootstrap() {
  setStaticNav();
  try {
    const cfgRes = await fetch('./config.json', { cache: 'no-store' });
    const cfg = await cfgRes.json();
    apiKey = cfg.apiKey || '';
    databaseURL = cfg.databaseURL || '';
    appName = cfg.appName || appName;
    configuredContinueUrl = cfg.continueUrl || configuredContinueUrl;
    brandName.textContent = appName;
    setStaticNav();
  } catch (e) {
    setMessage('error', 'Missing config.json. Add Firebase API key first.');
    return;
  }

  if (!apiKey) {
    setMessage('error', 'config.json is missing apiKey.');
    return;
  }
  if (!mode || !oobCode) {
    titleEl.textContent = 'Invalid action link';
    subtitleEl.textContent = 'Missing required parameters';
    setMessage('error', 'This link is incomplete. Open the latest email and retry.');
    return;
  }

  try {
    if (mode === 'verifyEmail') {
      await handleVerifyEmail();
      return;
    }
    if (mode === 'resetPassword') {
      await handleResetPassword();
      return;
    }
    if (mode === 'recoverEmail') {
      await handleRecoverEmail();
      return;
    }
    titleEl.textContent = 'Unsupported action';
    subtitleEl.textContent = mode;
    setMessage('error', `Unsupported mode: ${mode}`);
  } catch (e) {
    setMessage('error', e.message || 'Action failed.');
  }
}

bootstrap();
