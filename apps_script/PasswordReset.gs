/**
 * Hostel Student Wallet — forgot-password backend (free Google Apps Script).
 *
 * Actions (JSON POST to the web app /exec URL):
 *   { "action": "send",  "email": "..." }
 *   { "action": "reset", "email": "...", "code": "123456", "newPassword": "..." }
 *
 * Script Properties (Project Settings → Script properties):
 *   FIREBASE_SERVICE_ACCOUNT  = full service-account JSON (one line or pretty)
 *   OTP_PEPPER                = optional; created automatically if missing
 *
 * Deploy: Deploy → New deployment → Web app
 *   Execute as: Me
 *   Who has access: Anyone
 */

var TTL_MS = 10 * 60 * 1000;
var COOLDOWN_MS = 60 * 1000;
var MAX_ATTEMPTS = 5;
var MAX_SENDS_PER_HOUR = 8;
var FROM_NAME = 'Hostel Student Wallet';

function doGet(e) {
  return json_({ ok: true, service: 'hostel-password-reset' });
}

function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      return json_({ ok: false, error: 'empty' });
    }
    var body = JSON.parse(e.postData.contents);
    var action = String(body.action || '').toLowerCase();
    if (action === 'send') {
      return json_(handleSend_(body.email));
    }
    if (action === 'reset') {
      return json_(handleReset_(body.email, body.code, body.newPassword));
    }
    return json_({ ok: false, error: 'unknown_action' });
  } catch (err) {
    return json_({ ok: false, error: 'server' });
  }
}

function handleSend_(rawEmail) {
  var email = normalizeEmail_(rawEmail);
  if (!isEmail_(email)) {
    return { ok: false, error: 'invalid_email' };
  }

  var lock = LockService.getScriptLock();
  lock.waitLock(15000);
  try {
    var now = Date.now();
    var rec = readRecord_(email) || {};
    if (rec.lastSentAt && now - Number(rec.lastSentAt) < COOLDOWN_MS) {
      var wait = Math.ceil((COOLDOWN_MS - (now - Number(rec.lastSentAt))) / 1000);
      return { ok: false, error: 'cooldown', waitSec: wait };
    }

    var sends = Number(rec.sendsInWindow || 0);
    var windowStart = Number(rec.windowStart || 0);
    if (!windowStart || now - windowStart > 60 * 60 * 1000) {
      windowStart = now;
      sends = 0;
    }
    if (sends >= MAX_SENDS_PER_HOUR) {
      return { ok: true };
    }

    var code = pad6_(Math.floor(Math.random() * 1000000));
    var localId = lookupLocalId_(email);
    var hash;
    if (localId) {
      hash = hashCode_(email, code);
      sendMail_(email, code);
    } else {
      hash = hashCode_(email, 'dummy-' + Math.random());
    }

    writeRecord_(email, {
      hash: hash,
      expiresAt: now + TTL_MS,
      attempts: 0,
      lastSentAt: now,
      used: false,
      sendsInWindow: sends + 1,
      windowStart: windowStart,
    });
    return { ok: true };
  } finally {
    lock.releaseLock();
  }
}

function handleReset_(rawEmail, rawCode, newPassword) {
  var email = normalizeEmail_(rawEmail);
  var code = String(rawCode || '').replace(/\D/g, '');
  if (!isEmail_(email) || code.length !== 6) {
    return { ok: false, error: 'invalid' };
  }
  if (!isStrongPassword_(newPassword)) {
    return { ok: false, error: 'weak' };
  }

  var lock = LockService.getScriptLock();
  lock.waitLock(15000);
  try {
    var rec = readRecord_(email);
    if (!rec || rec.used === true) {
      return { ok: false, error: 'invalid' };
    }
    var now = Date.now();
    if (!rec.expiresAt || Number(rec.expiresAt) <= now) {
      return { ok: false, error: 'invalid' };
    }
    var attempts = Number(rec.attempts || 0);
    if (attempts >= MAX_ATTEMPTS) {
      return { ok: false, error: 'too_many' };
    }
    if (hashCode_(email, code) !== rec.hash) {
      rec.attempts = attempts + 1;
      writeRecord_(email, rec);
      if (rec.attempts >= MAX_ATTEMPTS) {
        return { ok: false, error: 'too_many' };
      }
      return { ok: false, error: 'invalid', left: MAX_ATTEMPTS - rec.attempts };
    }

    var localId = lookupLocalId_(email);
    if (!localId) {
      rec.used = true;
      writeRecord_(email, rec);
      return { ok: false, error: 'invalid' };
    }

    updatePassword_(localId, String(newPassword));
    rec.used = true;
    rec.hash = '';
    writeRecord_(email, rec);
    return { ok: true };
  } finally {
    lock.releaseLock();
  }
}

function sendMail_(email, code) {
  MailApp.sendEmail({
    to: email,
    name: FROM_NAME,
    subject: 'Your Hostel Student Wallet code',
    body:
      'Your 6-digit code is:\n\n' +
      code +
      '\n\nIt expires in 10 minutes.\nThis message has no link.',
  });
}

function lookupLocalId_(email) {
  var token = getAccessToken_();
  var projectId = serviceAccount_().project_id;
  var url =
    'https://identitytoolkit.googleapis.com/v1/projects/' +
    encodeURIComponent(projectId) +
    '/accounts:lookup';
  var resp = UrlFetchApp.fetch(url, {
    method: 'post',
    contentType: 'application/json',
    headers: { Authorization: 'Bearer ' + token },
    payload: JSON.stringify({ email: [email] }),
    muteHttpExceptions: true,
  });
  if (resp.getResponseCode() >= 400) {
    throw new Error('lookup_failed');
  }
  var json = JSON.parse(resp.getContentText() || '{}');
  var users = json.users || [];
  if (!users.length) return null;
  return users[0].localId || null;
}

function updatePassword_(localId, password) {
  var token = getAccessToken_();
  var projectId = serviceAccount_().project_id;
  var url =
    'https://identitytoolkit.googleapis.com/v1/projects/' +
    encodeURIComponent(projectId) +
    '/accounts:update';
  var resp = UrlFetchApp.fetch(url, {
    method: 'post',
    contentType: 'application/json',
    headers: { Authorization: 'Bearer ' + token },
    payload: JSON.stringify({ localId: localId, password: password }),
    muteHttpExceptions: true,
  });
  if (resp.getResponseCode() >= 400) {
    throw new Error('update_failed');
  }
}

function getAccessToken_() {
  var sa = serviceAccount_();
  var now = Math.floor(Date.now() / 1000);
  var header = encodeJwtPart_({ alg: 'RS256', typ: 'JWT' });
  var claim = encodeJwtPart_({
    iss: sa.client_email,
    sub: sa.client_email,
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
    scope: 'https://www.googleapis.com/auth/identitytoolkit',
  });
  var unsigned = header + '.' + claim;
  var sigBytes = Utilities.computeRsaSha256Signature(unsigned, sa.private_key);
  var jwt = unsigned + '.' + encodeJwtBytes_(sigBytes);
  var tokenResp = UrlFetchApp.fetch('https://oauth2.googleapis.com/token', {
    method: 'post',
    payload: {
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    },
    muteHttpExceptions: true,
  });
  var tokenJson = JSON.parse(tokenResp.getContentText() || '{}');
  if (!tokenJson.access_token) {
    throw new Error('token_failed');
  }
  return tokenJson.access_token;
}

function serviceAccount_() {
  var raw = PropertiesService.getScriptProperties().getProperty(
    'FIREBASE_SERVICE_ACCOUNT'
  );
  if (!raw) {
    throw new Error('missing_service_account');
  }
  return JSON.parse(raw);
}

function pepper_() {
  var props = PropertiesService.getScriptProperties();
  var pepper = props.getProperty('OTP_PEPPER');
  if (!pepper) {
    pepper = Utilities.getUuid() + Utilities.getUuid();
    props.setProperty('OTP_PEPPER', pepper);
  }
  return pepper;
}

function hashCode_(email, code) {
  var material = 'reset|' + email + '|' + code + '|' + pepper_();
  var bytes = Utilities.computeDigest(
    Utilities.DigestAlgorithm.SHA_256,
    material,
    Utilities.Charset.UTF_8
  );
  return toHex_(bytes);
}

function recKey_(email) {
  return 'otp_' + toHex_(
    Utilities.computeDigest(
      Utilities.DigestAlgorithm.SHA_256,
      email,
      Utilities.Charset.UTF_8
    )
  );
}

function readRecord_(email) {
  var raw = PropertiesService.getScriptProperties().getProperty(recKey_(email));
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch (e) {
    return null;
  }
}

function writeRecord_(email, rec) {
  PropertiesService.getScriptProperties().setProperty(
    recKey_(email),
    JSON.stringify(rec)
  );
}

function normalizeEmail_(v) {
  return String(v || '')
    .trim()
    .toLowerCase()
    .replace(/\s/g, '');
}

function isEmail_(v) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
}

function isStrongPassword_(v) {
  var s = String(v || '');
  if (s.length < 8) return false;
  if (!/[A-Z]/.test(s)) return false;
  if (!/[a-z]/.test(s)) return false;
  if (!/\d/.test(s)) return false;
  if (!/[^A-Za-z0-9\s]/.test(s)) return false;
  return true;
}

function pad6_(n) {
  var s = String(n);
  while (s.length < 6) s = '0' + s;
  return s;
}

function toHex_(bytes) {
  var out = '';
  for (var i = 0; i < bytes.length; i++) {
    var b = bytes[i];
    if (b < 0) b += 256;
    var h = b.toString(16);
    if (h.length === 1) h = '0' + h;
    out += h;
  }
  return out;
}

function encodeJwtPart_(obj) {
  return encodeJwtBytes_(Utilities.newBlob(JSON.stringify(obj)).getBytes());
}

function encodeJwtBytes_(bytes) {
  return Utilities.base64EncodeWebSafe(bytes).replace(/=+$/, '');
}

function json_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(
    ContentService.MimeType.JSON
  );
}
