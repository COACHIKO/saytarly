'use strict';

require('dotenv').config();
const crypto = require('crypto');
const path = require('path');
const express = require('express');

const github = require('./lib/github');

const app = express();
const PORT = Number(process.env.PORT) || 4600;
const PUBLIC_DIR = path.join(__dirname, 'public');
const ADMIN_DIR = path.join(__dirname, 'admin');
const VIEWS_DIR = path.join(__dirname, 'views');

/* ── Admin authentication ─────────────────────────────────────
 * The dashboard credentials are hardcoded here and NEVER shipped to the
 * browser. `ADMIN_USERNAME` / `ADMIN_PASSWORD` can override them from the
 * server environment if needed.
 * ────────────────────────────────────────────────────────────── */
const ADMIN_USERNAME = process.env.ADMIN_USERNAME || 'admin';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'Saytar123';
const SESSION_SECRET =
  process.env.SESSION_SECRET || crypto.randomBytes(32).toString('hex');
const SESSION_COOKIE = 'saytarly_admin_session';
const SESSION_TTL_MS = 8 * 60 * 60 * 1000; // 8 hours

if (process.env.TRUST_PROXY === '1') {
  app.set('trust proxy', 1);
}

app.disable('x-powered-by');
app.use(express.json({ limit: '1mb' }));

// Basic hardening headers for every response.
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('Referrer-Policy', 'same-origin');
  next();
});

// Never cache API responses (they contain device/license data).
app.use('/api', (req, res, next) => {
  res.setHeader('Cache-Control', 'no-store');
  next();
});

// Public marketing site (the dashboard is deliberately NOT in /public).
app.use(express.static(PUBLIC_DIR));

/* ── Session helpers ─────────────────────────────────────────── */

function hmac(payload) {
  return crypto.createHmac('sha256', SESSION_SECRET).update(payload).digest('base64url');
}

function readCookie(req, name) {
  const header = req.headers.cookie || '';
  for (const part of header.split(';')) {
    const index = part.indexOf('=');
    if (index === -1) continue;
    if (part.slice(0, index).trim() === name) {
      try {
        return decodeURIComponent(part.slice(index + 1).trim());
      } catch {
        return part.slice(index + 1).trim();
      }
    }
  }
  return '';
}

function safeEqual(a, b) {
  const left = crypto.createHash('sha256').update(String(a)).digest();
  const right = crypto.createHash('sha256').update(String(b)).digest();
  return crypto.timingSafeEqual(left, right);
}

function createSessionToken() {
  const expiresAt = Date.now() + SESSION_TTL_MS;
  const payload = String(expiresAt);
  return `${payload}.${hmac(payload)}`;
}

function verifySession(req) {
  const token = readCookie(req, SESSION_COOKIE);
  if (!token) return false;
  const dot = token.lastIndexOf('.');
  if (dot <= 0) return false;
  const payload = token.slice(0, dot);
  const signature = token.slice(dot + 1);
  const expected = hmac(payload);
  const sigBuffer = Buffer.from(signature);
  const expBuffer = Buffer.from(expected);
  if (sigBuffer.length !== expBuffer.length) return false;
  if (!crypto.timingSafeEqual(sigBuffer, expBuffer)) return false;
  const expiresAt = Number(payload);
  return Number.isFinite(expiresAt) && Date.now() < expiresAt;
}

function sessionCookieOptions(req) {
  return {
    httpOnly: true,
    sameSite: 'strict',
    secure: req.secure,
    path: '/',
    maxAge: SESSION_TTL_MS,
  };
}

function requireAdminApi(req, res, next) {
  if (verifySession(req)) return next();
  return res.status(401).json({ ok: false, error: 'unauthorized' });
}

/* ── Login rate limiting (in-memory, per IP) ─────────────────── */
const LOGIN_WINDOW_MS = 10 * 60 * 1000;
const LOGIN_MAX_ATTEMPTS = 8;
const loginAttempts = new Map();

function getAttempt(req) {
  const key = req.ip || req.socket.remoteAddress || 'unknown';
  const now = Date.now();
  let entry = loginAttempts.get(key);
  if (!entry || now - entry.firstAt > LOGIN_WINDOW_MS) {
    entry = { count: 0, firstAt: now };
    loginAttempts.set(key, entry);
  }
  return { key, entry };
}

function pruneAttempts() {
  if (loginAttempts.size < 5000) return;
  const now = Date.now();
  for (const [key, entry] of loginAttempts) {
    if (now - entry.firstAt > LOGIN_WINDOW_MS) loginAttempts.delete(key);
  }
}

/* ── Auth routes ─────────────────────────────────────────────── */

app.post('/api/auth/login', (req, res) => {
  const { key, entry } = getAttempt(req);
  if (entry.count >= LOGIN_MAX_ATTEMPTS) {
    return res.status(429).json({ ok: false, error: 'too_many_attempts' });
  }

  const body = req.body || {};
  const username = typeof body.username === 'string' ? body.username : '';
  const password = typeof body.password === 'string' ? body.password : '';

  const usernameOk = safeEqual(username, ADMIN_USERNAME);
  const passwordOk = safeEqual(password, ADMIN_PASSWORD);

  if (!usernameOk || !passwordOk) {
    entry.count += 1;
    pruneAttempts();
    return res.status(401).json({ ok: false, error: 'invalid_credentials' });
  }

  loginAttempts.delete(key);
  res.cookie(SESSION_COOKIE, createSessionToken(), sessionCookieOptions(req));
  res.json({ ok: true });
});

app.post('/api/auth/logout', (req, res) => {
  res.clearCookie(SESSION_COOKIE, {
    httpOnly: true,
    sameSite: 'strict',
    secure: req.secure,
    path: '/',
  });
  res.json({ ok: true });
});

app.get('/api/auth/session', (req, res) => {
  if (!verifySession(req)) {
    return res.status(401).json({ ok: false, error: 'unauthorized' });
  }
  res.json({ ok: true });
});

/* ── Pages ───────────────────────────────────────────────────── */

app.get('/', (req, res) => res.sendFile(path.join(PUBLIC_DIR, 'index.html')));

// Contact page (also served directly by express.static as /contact.html).
app.get('/contact', (req, res) =>
  res.sendFile(path.join(PUBLIC_DIR, 'contact.html')),
);

// Free 7-day demo request page (static handler serves /demo.html too).
app.get('/demo', (req, res) =>
  res.sendFile(path.join(PUBLIC_DIR, 'demo.html')),
);

// The dashboard is served only after a valid admin session. Unauthenticated
// visitors get the login page (no dashboard markup is ever sent to them).
app.get('/dashboard', (req, res) => {
  res.setHeader('Cache-Control', 'no-store');
  if (!verifySession(req)) {
    return res.sendFile(path.join(VIEWS_DIR, 'login.html'));
  }
  return res.sendFile(path.join(ADMIN_DIR, 'dashboard.html'));
});

// Protected admin assets (dashboard script). These live outside /public so
// they are not part of the static GitHub Pages deployment.
app.use(
  '/admin',
  requireAdminApi,
  express.static(ADMIN_DIR, { index: false, dotfiles: 'deny' }),
);

// Old links keep working, but always go through the auth gate.
app.get(['/dashboard.html', '/saytarly/dashboard'], (req, res) => {
  res.redirect(301, '/dashboard');
});

app.get('/login', (req, res) => res.redirect('/dashboard'));

/* ── Protected API ───────────────────────────────────────────── */

app.get('/api/health', (req, res) =>
  res.json({ ok: true, repo: github.REPO, token: github.hasToken }),
);

app.use('/api/devices', requireAdminApi);

// كل الأجهزة + حالتها المحسوبة
app.get('/api/devices', async (req, res) => {
  try {
    const devices = await github.listDevices();
    res.json({ ok: true, devices });
  } catch (error) {
    console.error('[api] GET /api/devices failed:', error.message);
    res.status(502).json({ ok: false, error: error.message });
  }
});

// تفعيل / تعديل ترخيص جهاز
app.post('/api/devices/:code/license', async (req, res) => {
  try {
    const { type, value } = req.body || {};
    const device = await github.setLicense(
      decodeURIComponent(req.params.code),
      type,
      value,
    );
    res.json({ ok: true, device });
  } catch (error) {
    console.error('[api] POST license failed:', error.message);
    res.status(400).json({ ok: false, error: error.message });
  }
});

// حظر الجهاز / فك الحظر
app.post('/api/devices/:code/block', async (req, res) => {
  try {
    const { blocked } = req.body || {};
    const device = await github.setBlocked(
      decodeURIComponent(req.params.code),
      blocked === true,
    );
    res.json({ ok: true, device });
  } catch (error) {
    console.error('[api] POST block failed:', error.message);
    res.status(400).json({ ok: false, error: error.message });
  }
});

/* ── 404 & errors ────────────────────────────────────────────── */

app.use((req, res) => {
  if (req.path.startsWith('/api/')) {
    return res.status(404).json({ ok: false, error: 'not_found' });
  }
  res.status(404).sendFile(path.join(PUBLIC_DIR, '404.html'));
});

app.use((error, req, res, next) => {
  if (res.headersSent) return next(error);
  if (error && error.type === 'entity.parse.failed') {
    return res.status(400).json({ ok: false, error: 'invalid_json' });
  }
  console.error('[server] unhandled error:', error);
  res.status(500).json({ ok: false, error: 'internal_error' });
});

app.listen(PORT, () => {
  console.log('──────────────────────────────────────────────');
  console.log('  SAYTARLY website');
  console.log(`  Home:      http://localhost:${PORT}`);
  console.log(`  Dashboard: http://localhost:${PORT}/dashboard (password protected)`);
  console.log(`  Repo:      ${github.REPO} (token: ${github.hasToken ? 'OK' : 'MISSING'})`);
  console.log('──────────────────────────────────────────────');
});
