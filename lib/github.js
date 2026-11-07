'use strict';

/**
 * GitHub Contents API helpers — نفس الريبو اللي بيستخدمه التطبيق للتحديثات
 * وملفات الأجهزة (`devices/<deviceCode>.json`).
 *
 * التوكن بيتقري من بيئة السيرفر بس — عمره ما بيوصل للعميل.
 */

const REPO = process.env.RELEASES_REPO || 'COACHIKO/saytarly_releases';
const TOKEN = process.env.RELEASES_TOKEN || '';

const API = 'https://api.github.com';

function ghHeaders(extra = {}) {
  return {
    Authorization: `Bearer ${TOKEN}`,
    Accept: 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
    'User-Agent': 'saytarly-website',
    ...extra,
  };
}

async function gh(pathname, options = {}) {
  const res = await fetch(`${API}${pathname}`, {
    ...options,
    headers: ghHeaders(options.headers || {}),
  });
  const text = await res.text();
  let data = null;
  try {
    data = JSON.parse(text);
  } catch {
    /* non-JSON body */
  }
  if (!res.ok) {
    const msg = (data && data.message) || text.slice(0, 200) || res.statusText;
    throw new Error(`GitHub API ${res.status}: ${msg}`);
  }
  return data;
}

function decodeBase64(value) {
  return Buffer.from(value, 'base64').toString('utf8');
}

function encodeBase64(value) {
  return Buffer.from(value, 'utf8').toString('base64');
}

/**
 * حالة الجهاز — مطابقة لمنطق التطبيق (DeviceLicense.statusAt):
 * المحظور أولًا (blocked)، وبعدين unlimited => unlimited،
 * من غير تاريخ انتهاء => pending، لو التاريخ عدّى => expired،
 * غير كده active.
 */
function computeStatus(record, now = new Date()) {
  if (record && record.blocked) return 'blocked';
  const license = record && record.license;
  if (!license) return 'pending';
  if (license.type === 'unlimited') return 'unlimited';
  const expires = license.expiresAt ? new Date(license.expiresAt) : null;
  if (!expires || Number.isNaN(expires.getTime())) return 'pending';
  return now.getTime() < expires.getTime() ? 'active' : 'expired';
}

/** حساب تاريخ الانتهاء من نوع الترخيص وقيمته (UTC). */
function computeExpiry(type, value, from = new Date()) {
  if (type === 'unlimited') return null;
  const d = new Date(from);
  if (type === 'days') d.setUTCDate(d.getUTCDate() + value);
  else if (type === 'months') d.setUTCMonth(d.getUTCMonth() + value);
  else if (type === 'years') d.setUTCFullYear(d.getUTCFullYear() + value);
  else return null;
  return d;
}

/** كل ملفات الأجهزة مع الحالة المحسوبة، مرتبة بآخر ظهور. */
async function listDevices() {
  const entries = await gh(`/repos/${REPO}/contents/devices`);
  const files = (Array.isArray(entries) ? entries : []).filter(
    (e) => e.type === 'file' && e.name.endsWith('.json'),
  );
  const devices = [];
  for (const file of files) {
    try {
      const raw = await gh(`/repos/${REPO}/contents/${file.path}`);
      const record = JSON.parse(decodeBase64(raw.content));
      devices.push({
        ...record,
        status: computeStatus(record),
        sha: raw.sha,
        path: file.path,
      });
    } catch (error) {
      console.warn(`[github] skip ${file.path}: ${error.message}`);
    }
  }
  devices.sort(
    (a, b) =>
      new Date(b.lastSeenAt || 0).getTime() -
      new Date(a.lastSeenAt || 0).getTime(),
  );
  return devices;
}

async function getDevice(code) {
  const raw = await gh(`/repos/${REPO}/contents/devices/${code}.json`);
  const record = JSON.parse(decodeBase64(raw.content));
  return {
    ...record,
    status: computeStatus(record),
    sha: raw.sha,
    path: `devices/${code}.json`,
  };
}

/**
 * تفعيل / تعديل ترخيص جهاز:
 * type ∈ days | months | years | unlimited
 * value = العدد (أو 0 للـ unlimited)
 */
async function setLicense(code, type, value) {
  const allowed = ['days', 'months', 'years', 'unlimited'];
  if (!allowed.includes(type)) {
    throw new Error(`نوع ترخيص غير صالح: ${type}`);
  }
  const num = Number(value);
  if (type !== 'unlimited' && (!Number.isInteger(num) || num < 0)) {
    throw new Error('قيمة الترخيص لازم تكون رقم صحيح موجب');
  }
  const raw = await gh(`/repos/${REPO}/contents/devices/${code}.json`);
  const record = JSON.parse(decodeBase64(raw.content));
  const now = new Date();
  // value === 0 مع نوع مؤقت => ترخيص مبدئي (pending) من غير تاريخ انتهاء.
  const pending = type !== 'unlimited' && num === 0;
  record.license = {
    type,
    value: type === 'unlimited' ? 0 : num,
    issuedAt: pending ? null : now.toISOString(),
    expiresAt: pending ? null : (computeExpiry(type, num, now)?.toISOString() ?? null),
  };
  const body = {
    message: pending
      ? `License: ${record.pcName || code} -> pending (revoked)`
      : `License: ${record.pcName || code} -> ${type}${
          type === 'unlimited' ? '' : ` ${num}`
        }`,
    content: encodeBase64(JSON.stringify(record, null, 2)),
    sha: raw.sha,
  };
  await gh(`/repos/${REPO}/contents/devices/${code}.json`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  return { ...record, status: computeStatus(record), sha: raw.sha };
}

/** حظر الجهاز أو فك الحظر — الحظر بيقفل التطبيق فورًا مهما كان الترخيص. */
async function setBlocked(code, blocked) {
  const raw = await gh(`/repos/${REPO}/contents/devices/${code}.json`);
  const record = JSON.parse(decodeBase64(raw.content));
  record.blocked = blocked === true;
  if (record.blocked) {
    record.blockedAt = new Date().toISOString();
  } else {
    delete record.blockedAt;
  }
  const body = {
    message: record.blocked
      ? `Block device: ${record.pcName || code}`
      : `Unblock device: ${record.pcName || code}`,
    content: encodeBase64(JSON.stringify(record, null, 2)),
    sha: raw.sha,
  };
  await gh(`/repos/${REPO}/contents/devices/${code}.json`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  return { ...record, status: computeStatus(record), sha: raw.sha };
}

module.exports = {
  REPO,
  hasToken: TOKEN.trim().length > 0,
  listDevices,
  getDevice,
  setLicense,
  setBlocked,
  computeStatus,
};
