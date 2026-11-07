'use strict';

require('dotenv').config();
const path = require('path');
const express = require('express');

const github = require('./lib/github');

const app = express();
const PORT = Number(process.env.PORT) || 4600;
const PUBLIC_DIR = path.join(__dirname, 'public');

app.disable('x-powered-by');
app.use(express.json({ limit: '1mb' }));
app.use(express.static(PUBLIC_DIR));

// ── صفحات ──────────────────────────────────────────────────────────────────
app.get('/', (req, res) => res.sendFile(path.join(PUBLIC_DIR, 'index.html')));

app.get('/dashboard', (req, res) =>
  res.sendFile(path.join(PUBLIC_DIR, 'dashboard.html')),
);

// الرابط القديم — يفضل شغال ويحوّل للجديد
app.get('/saytarly/dashboard', (req, res) =>
  res.redirect(301, '/dashboard'),
);

// ── API ────────────────────────────────────────────────────────────────────
app.get('/api/health', (req, res) =>
  res.json({ ok: true, repo: github.REPO, token: github.hasToken }),
);

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

app.use((req, res) => {
  res.status(404).sendFile(path.join(PUBLIC_DIR, '404.html'));
});

app.listen(PORT, () => {
  console.log('──────────────────────────────────────────────');
  console.log('  SAYTARLY website');
  console.log(`  Home:      http://localhost:${PORT}`);
  console.log(`  Dashboard: http://localhost:${PORT}/dashboard`);
  console.log(`  Devices:   http://localhost:${PORT}/api/devices`);
  console.log(`  Repo:      ${github.REPO} (token: ${github.hasToken ? 'OK' : 'MISSING'})`);
  console.log('──────────────────────────────────────────────');
});
