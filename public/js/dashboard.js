/* Saytarly — لوحة الأجهزة والتراخيص (GitHub Pages version)
 *
 * البيانات بتتقرا وتتكتب مباشرة من GitHub API باستخدام توكن (PAT)
 * بتدخله مرة واحدة وبيتخزن في المتصفح بتاعك بس — مش بيتنشر في الموقع.
 */

(() => {
  'use strict';

  // ── Config ─────────────────────────────────────────────────
  const REPO = 'COACHIKO/saytarly_releases'; // ريبو الأجهزة (خاص)
  const ALLOWED_USERS = ['COACHIKO']; // الحسابات المسموح ليها بالدخول
  const API = 'https://api.github.com';
  const TOKEN_KEY = 'saytarly_gh_token';

  // ── State ──────────────────────────────────────────────────
  const state = {
    devices: [],
    filter: 'all',
    query: '',
    sort: 'lastSeen',
    loading: true,
    error: null,
    opened: null, // الجهاز المفتوح في الحوار
    user: null,   // { login } بعد التحقق من التوكن
  };

  const $ = (id) => document.getElementById(id);
  const grid = $('grid');
  const statsEl = $('stats');
  const searchInput = $('searchInput');
  const sortSel = $('sort');
  const refreshBtn = $('refreshBtn');
  const logoutBtn = $('logoutBtn');
  const toolbar = $('toolbar');
  const modalBackdrop = $('modalBackdrop');
  const modalBody = $('modalBody');
  const modalTitle = $('modalTitle');

  const STATUS_LABEL = {
    active: 'مفعّل',
    unlimited: 'مدى الحياة',
    pending: 'بانتظار التفعيل',
    expired: 'منتهي',
    blocked: 'محظور',
  };
  const TYPE_LABEL = {
    days: 'أيام',
    months: 'شهور',
    years: 'سنين',
    unlimited: 'مدى الحياة',
  };

  const rtf = new Intl.RelativeTimeFormat('ar', { numeric: 'auto' });
  const dtf = new Intl.DateTimeFormat('ar-EG', {
    dateStyle: 'medium',
    timeStyle: 'short',
  });

  function rel(dateStr) {
    if (!dateStr) return '—';
    const diff = new Date(dateStr) - Date.now();
    const abs = Math.abs(diff);
    const units = [
      [1000 * 60 * 60 * 24 * 365, 'year'],
      [1000 * 60 * 60 * 24 * 30, 'month'],
      [1000 * 60 * 60 * 24, 'day'],
      [1000 * 60 * 60, 'hour'],
      [1000 * 60, 'minute'],
      [1000, 'second'],
    ];
    for (const [ms, unit] of units) {
      if (abs >= ms) return rtf.format(Math.round(diff / ms), unit);
    }
    return 'الآن';
  }

  function fmt(dateStr) {
    if (!dateStr) return '—';
    return dtf.format(new Date(dateStr));
  }

  function countdown(device) {
    if (device.status === 'blocked') return 'محظور ⛔';
    if (device.status === 'unlimited') return '∞ مدى الحياة';
    if (!device.license || !device.license.expiresAt) return '—';
    if (device.status === 'expired') return `منتهي ${rel(device.license.expiresAt)}`;
    return `ينتهي ${rel(device.license.expiresAt)}`;
  }

  /* ── Toasts ── */
  function toast(msg, kind = 'ok') {
    const wrap = $('toasts');
    const el = document.createElement('div');
    el.className = `toast ${kind}`;
    el.innerHTML =
      kind === 'err'
        ? `⚠️ ${escapeHtml(msg)}`
        : `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" width="16" height="16"><path d="M20 6 9 17l-5-5"/></svg> ${escapeHtml(msg)}`;
    wrap.appendChild(el);
    setTimeout(() => {
      el.classList.add('hide');
      setTimeout(() => el.remove(), 320);
    }, 2600);
  }

  function escapeHtml(s) {
    return String(s)
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
  }

  /* ── GitHub API client ───────────────────────────────────── */
  function token() {
    return (localStorage.getItem(TOKEN_KEY) || '').trim();
  }

  function ghHeaders(extra = {}) {
    return {
      Authorization: `Bearer ${token()}`,
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
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
      const err = new Error(`GitHub API ${res.status}: ${msg}`);
      err.status = res.status;
      throw err;
    }
    return data;
  }

  function decodeBase64(value) {
    const bin = atob(value.replace(/\s/g, ''));
    return new TextDecoder().decode(
      Uint8Array.from(bin, (c) => c.charCodeAt(0)),
    );
  }

  function encodeBase64(value) {
    const bytes = new TextEncoder().encode(value);
    let bin = '';
    for (const b of bytes) bin += String.fromCharCode(b);
    return btoa(bin);
  }

  // حالة الجهاز — نفس منطق التطبيق (DeviceLicense.statusAt)
  function computeStatus(record, now = new Date()) {
    if (record && record.blocked) return 'blocked';
    const license = record && record.license;
    if (!license) return 'pending';
    if (license.type === 'unlimited') return 'unlimited';
    const expires = license.expiresAt ? new Date(license.expiresAt) : null;
    if (!expires || Number.isNaN(expires.getTime())) return 'pending';
    return now.getTime() < expires.getTime() ? 'active' : 'expired';
  }

  function computeExpiry(type, value, from = new Date()) {
    if (type === 'unlimited') return null;
    const d = new Date(from);
    if (type === 'days') d.setUTCDate(d.getUTCDate() + value);
    else if (type === 'months') d.setUTCMonth(d.getUTCMonth() + value);
    else if (type === 'years') d.setUTCFullYear(d.getUTCFullYear() + value);
    else return null;
    return d;
  }

  /* ── Auth ── */
  async function verifyUser() {
    const user = await gh('/user');
    if (!user || !user.login) throw new Error('استجابة غير متوقعة من GitHub');
    if (!ALLOWED_USERS.includes(user.login)) {
      throw new Error(`الحساب ${user.login} مش مصرّح له بالدخول للوحة`);
    }
    return user;
  }

  function setAuthView(loggedIn) {
    if (toolbar) toolbar.style.display = loggedIn ? '' : 'none';
    if (statsEl) statsEl.style.display = loggedIn ? '' : 'none';
    if (logoutBtn) {
      logoutBtn.style.display = loggedIn ? '' : 'none';
      logoutBtn.textContent = loggedIn && state.user
        ? `تسجيل الخروج (${state.user.login})`
        : 'تسجيل الخروج';
    }
  }

  function renderLogin(message = '') {
    state.loading = false;
    setAuthView(false);
    grid.innerHTML = `
      <div class="error" style="grid-column: 1 / -1">
        <span class="ic"><svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round"><path d="M15.5 8.5a3.5 3.5 0 1 0-1 6.9 3.5 3.5 0 0 0 1-6.9Z"/><rect x="4" y="17" width="16" height="4" rx="2"/><path d="M12 3v3M5.5 5.5l2 2M18.5 5.5l-2 2"/></svg></span>
        <h3>الدخول للوحة الأجهزة</h3>
        <p style="max-width:520px;margin:0 auto">
          اللوحة بتقرا وتكتب في الريبو الخاص
          <b style="font-family:var(--font-en)" dir="ltr">${REPO}</b>.
          الصق توكن GitHub (Fine-grained PAT) له صلاحية
          <b>Contents: Read and write</b> على الريبو ده — التوكن بيتخزن في متصفحك بس
          ومش بيتنشر في أي مكان.
        </p>
        <p style="margin-top:10px;font-size:12px">
          <a href="https://github.com/settings/personal-access-tokens/new" target="_blank" rel="noopener" style="color:var(--accent-soft)">إنشاء توكن جديد ↗</a>
          — اختار الريبو <b style="font-family:var(--font-en)" dir="ltr">saytarly_releases</b> بس،
          وPermission: <b>Contents → Read and write</b>.
        </p>
        <div style="display:flex;gap:8px;justify-content:center;margin-top:18px;flex-wrap:wrap">
          <input id="tokenInput" type="password" placeholder="ghp_…" autocomplete="off"
            style="flex:1 1 260px;max-width:380px;background:var(--sunken);border:1px solid var(--border);border-radius:11px;padding:10px 12px;color:var(--text-1);font-family:var(--font-en);font-size:13px;outline:none" />
          <button class="btn btn-primary" id="loginBtn">دخول</button>
        </div>
        ${message ? `<p style="margin-top:14px;color:#fecaca;font-weight:700">⚠️ ${escapeHtml(message)}</p>` : ''}
      </div>`;

    const input = $('tokenInput');
    const btn = $('loginBtn');
    const doLogin = async () => {
      const t = input.value.trim();
      if (!t) return toast('اكتب التوكن الأول', 'err');
      btn.disabled = true;
      btn.textContent = 'بيتحقق…';
      try {
        localStorage.setItem(TOKEN_KEY, t);
        const user = await verifyUser();
        state.user = user;
        toast(`أهلاً ${user.login} ✓`);
        boot();
      } catch (error) {
        localStorage.removeItem(TOKEN_KEY);
        renderLogin(loginErrorMessage(error));
      }
    };
    btn.addEventListener('click', doLogin);
    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') doLogin();
    });
    input.focus();
  }

  function loginErrorMessage(error) {
    if (error.status === 401) return 'التوكن غير صالح أو منتهي — اتأكد إنك لصقته صح';
    if (error.status === 403) return 'التوكن مش عليه صلاحية — لازم Contents: Read and write على saytarly_releases';
    if (error.message.includes('مصرّح')) return error.message;
    return error.message;
  }

  function logout() {
    localStorage.removeItem(TOKEN_KEY);
    state.user = null;
    state.devices = [];
    renderLogin();
    toast('تم تسجيل الخروج — التوكن اتمسح من المتصفح');
  }

  /* ── Fetch devices ── */
  async function load() {
    state.loading = true;
    state.error = null;
    render();
    try {
      state.devices = await listDevices();
      $('lastUpdated').textContent = new Intl.DateTimeFormat('ar-EG', {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
      }).format(new Date());
    } catch (error) {
      if (error.status === 401 || error.status === 403 || error.status === 404) {
        localStorage.removeItem(TOKEN_KEY);
        renderLogin(loginErrorMessage(error));
        return;
      }
      state.error = error.message;
    } finally {
      state.loading = false;
      if (state.user) render();
    }
  }

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

  async function putDevice(code, record, message) {
    await gh(`/repos/${REPO}/contents/devices/${code}.json`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        message,
        content: encodeBase64(JSON.stringify(record, null, 2)),
        sha: record.sha,
      }),
    });
  }

  // تفعيل / تعديل ترخيص جهاز: type ∈ days | months | years | unlimited
  async function setLicense(code, type, value) {
    const allowed = ['days', 'months', 'years', 'unlimited'];
    if (!allowed.includes(type)) {
      throw new Error(`نوع ترخيص غير صالح: ${type}`);
    }
    const num = Number(value);
    if (type !== 'unlimited' && (!Number.isInteger(num) || num < 0)) {
      throw new Error('قيمة الترخيص لازم تكون رقم صحيح موجب');
    }
    const record = await getDevice(code);
    const now = new Date();
    // value === 0 مع نوع مؤقت => ترخيص مبدئي (pending) من غير تاريخ انتهاء.
    const pending = type !== 'unlimited' && num === 0;
    record.license = {
      type,
      value: type === 'unlimited' ? 0 : num,
      issuedAt: pending ? null : now.toISOString(),
      expiresAt: pending ? null : (computeExpiry(type, num, now)?.toISOString() ?? null),
    };
    const message = pending
      ? `License: ${record.pcName || code} -> pending (revoked)`
      : `License: ${record.pcName || code} -> ${type}${type === 'unlimited' ? '' : ` ${num}`}`;
    await putDevice(code, record, message);
    return { ...record, status: computeStatus(record) };
  }

  // حظر الجهاز أو فك الحظر
  async function setBlocked(code, blocked) {
    const record = await getDevice(code);
    record.blocked = blocked === true;
    if (record.blocked) {
      record.blockedAt = new Date().toISOString();
    } else {
      delete record.blockedAt;
    }
    const message = record.blocked
      ? `Block device: ${record.pcName || code}`
      : `Unblock device: ${record.pcName || code}`;
    await putDevice(code, record, message);
    return { ...record, status: computeStatus(record) };
  }

  /* ── Stats ── */
  function animateCount(el, target) {
    const dur = 700;
    const start = performance.now();
    const tick = (now) => {
      const p = Math.min(1, (now - start) / dur);
      const eased = 1 - Math.pow(1 - p, 3);
      el.textContent = Math.round(target * eased);
      if (p < 1) requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  }

  function renderStats() {
    const count = (s) => state.devices.filter((d) => d.status === s).length;
    const items = [
      { label: 'إجمالي الأجهزة', value: state.devices.length, color: 'var(--accent)' },
      { label: 'مفعّل', value: count('active'), color: 'var(--success)' },
      { label: 'مدى الحياة', value: count('unlimited'), color: 'var(--info)' },
      { label: 'بانتظار التفعيل', value: count('pending'), color: 'var(--warning)' },
      { label: 'منتهي', value: count('expired'), color: 'var(--danger)' },
      { label: 'محظور', value: count('blocked'), color: '#ff3b3b' },
    ];
    statsEl.innerHTML = items
      .map(
        (it, i) => `
      <div class="stat">
        <div class="num" data-i="${i}">0</div>
        <div class="lbl">${it.label}</div>
        <div class="bar" style="--bar-c:${it.color}"></div>
      </div>`,
      )
      .join('');
    items.forEach((it, i) => {
      const el = statsEl.querySelector(`[data-i="${i}"]`);
      if (el) animateCount(el, it.value);
    });
  }

  /* ── Grid ── */
  const ICON_DEVICE = (w) => `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" width="${w}" height="${w}">
      <rect x="2.5" y="4.5" width="19" height="13" rx="2"/>
      <path d="M8 21h8M12 17.5V21"/>
    </svg>`;
  const ICON_PHONE = (w) => `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" width="${w}" height="${w}">
      <rect x="7" y="2.5" width="10" height="19" rx="2.5"/>
      <path d="M11 18.5h2"/>
    </svg>`;

  function sortedDevices() {
    const list = [...state.devices];
    switch (state.sort) {
      case 'name':
        list.sort((a, b) => (a.pcName || '').localeCompare(b.pcName || '', 'ar'));
        break;
      case 'oldest':
        list.sort((a, b) => new Date(a.lastSeenAt || 0) - new Date(b.lastSeenAt || 0));
        break;
      case 'version':
        list.sort((a, b) => String(b.appVersion || '').localeCompare(String(a.appVersion || '')));
        break;
      default:
        list.sort((a, b) => new Date(b.lastSeenAt || 0) - new Date(a.lastSeenAt || 0));
    }
    return list;
  }

  function filteredDevices() {
    const q = state.query.trim().toLowerCase();
    return sortedDevices().filter((d) => {
      if (state.filter !== 'all' && d.status !== state.filter) return false;
      if (!q) return true;
      return (
        (d.pcName || '').toLowerCase().includes(q) ||
        (d.deviceCode || '').toLowerCase().includes(q)
      );
    });
  }

  function licenseText(d) {
    const t = d.license || {};
    if (t.type === 'unlimited') return 'مدى الحياة';
    const v = t.value || 0;
    return `${v} ${TYPE_LABEL[t.type] || 'أيام'}`;
  }

  function card(d) {
    const st = d.status || 'pending';
    return `
    <article class="card ${st === 'blocked' ? 'is-blocked' : ''}" data-code="${escapeHtml(d.deviceCode)}" tabindex="0">
      <div class="top">
        <div class="name">
          <span class="av">${d.platform === 'windows' ? ICON_DEVICE(21) : ICON_PHONE(21)}</span>
          <div>
            <b>${escapeHtml(d.pcName || 'جهاز')}</b>
            <small>${d.platform === 'windows' ? 'ويندوز' : 'أندرويد'} · v${escapeHtml(d.appVersion || '—')} (b${d.buildNumber ?? 0})</small>
          </div>
        </div>
        <span class="badge ${st}"><span class="dot"></span>${STATUS_LABEL[st]}</span>
      </div>
      <div class="code">
        <span>${escapeHtml(d.deviceCode || '')}</span>
        <button class="copy" title="نسخ الكود">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="12" height="12" rx="2"/><path d="M5 15V5a2 2 0 0 1 2-2h10"/></svg>
        </button>
      </div>
      <div class="meta">
        <div class="box"><small>الترخيص</small><b>${escapeHtml(licenseText(d))}</b></div>
        <div class="box"><small>الصلاحية</small><b>${escapeHtml(countdown(d))}</b></div>
      </div>
      <div class="foot">
        <span class="seen">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>
          آخر ظهور ${rel(d.lastSeenAt)}
        </span>
        <span>سُجّل ${fmt(d.firstSeenAt)}</span>
      </div>
    </article>`;
  }

  function render() {
    renderStats();

    if (state.loading) {
      grid.innerHTML = Array.from({ length: 6 })
        .map(
          () => `<div class="skeleton">
            <div style="display:flex;gap:12px;align-items:center">
              <div class="sk" style="width:44px;height:44px;border-radius:13px"></div>
              <div style="flex:1"><div class="sk" style="width:60%;height:14px;margin-bottom:8px"></div><div class="sk" style="width:40%;height:10px"></div></div>
            </div>
            <div class="sk" style="width:100%;height:38px;margin-top:16px"></div>
            <div class="sk" style="width:100%;height:60px;margin-top:14px"></div>
          </div>`,
        )
        .join('');
      return;
    }

    if (state.error) {
      grid.innerHTML = `<div class="error">
        <span class="ic"><svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round"><path d="M12 9v4M12 17h.01"/><path d="M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0Z"/></svg></span>
        <h3>حصلت مشكلة في جلب الأجهزة</h3>
        <p>${escapeHtml(state.error)}</p>
        <button class="btn btn-primary" style="margin:18px auto 0" onclick="location.reload()">حاول تاني</button>
      </div>`;
      return;
    }

    const list = filteredDevices();
    if (!state.devices.length) {
      grid.innerHTML = `<div class="empty">
        <span class="ic"><svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2.5" y="4.5" width="19" height="13" rx="2"/><path d="M8 21h8M12 17.5V21"/></svg></span>
        <h3>لسه مفيش أجهزة متسجلة</h3>
        <p>أول ما جهاز يشغّل التطبيق في الوضع Online، هيظهر هنا تلقائيًا.</p>
      </div>`;
      return;
    }
    if (!list.length) {
      grid.innerHTML = `<div class="empty">
        <span class="ic"><svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg></span>
        <h3>مفيش نتايج مطابقة</h3>
        <p>جرّب تغيّر البحث أو الفلتر.</p>
      </div>`;
      return;
    }
    grid.innerHTML = list.map(card).join('');
  }

  /* ── Modal ── */
  function openModal(device) {
    state.opened = device;
    const st = device.status || 'pending';
    const t = device.license || {};
    const isBlocked = device.blocked === true;

    modalTitle.textContent = 'تفاصيل الجهاز';

    const rows = [
      { k: 'كود الجهاز', v: device.deviceCode, ar: false },
      { k: 'المنصة', v: device.platform === 'windows' ? 'Windows' : 'Android', ar: false },
      { k: 'نسخة التطبيق', v: `${device.appVersion || '—'} · build ${device.buildNumber ?? 0}`, ar: false },
      { k: 'نوع الترخيص', v: TYPE_LABEL[t.type] || '—', ar: true },
      { k: 'قيمة الترخيص', v: t.type === 'unlimited' ? '∞' : String(t.value ?? 0), ar: false },
      { k: 'صدر الترخيص', v: fmt(t.issuedAt), ar: true },
      { k: 'ينتهي', v: t.expiresAt ? fmt(t.expiresAt) : '—', ar: true },
      { k: 'أول تسجيل', v: fmt(device.firstSeenAt), ar: true },
      { k: 'آخر ظهور', v: `${fmt(device.lastSeenAt)} · ${rel(device.lastSeenAt)}`, ar: true },
      ...(isBlocked && device.blockedAt
        ? [{ k: 'تاريخ الحظر', v: `${fmt(device.blockedAt)} · ${rel(device.blockedAt)}`, ar: true }]
        : []),
    ];

    modalBody.innerHTML = `
      <div class="d-id">
        <span class="av">${device.platform === 'windows' ? ICON_DEVICE(30) : ICON_PHONE(30)}</span>
        <h2>${escapeHtml(device.pcName || 'جهاز')}</h2>
        <div class="pc">${escapeHtml(device.deviceCode || '')}</div>
        <span class="badge ${st}" style="margin-top:10px"><span class="dot"></span>${STATUS_LABEL[st]}</span>
      </div>
      ${
        isBlocked
          ? `<div class="blocked-banner">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M5 5l14 14"/></svg>
              هذا الجهاز محظور — التطبيق مقفول عليه حاليًا مهما كان الترخيص.
            </div>`
          : ''
      }
      ${rows
        .map(
          (r) => `<div class="row">
            <span class="k">
              <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="9"/></svg>
              ${r.k}
            </span>
            <span class="v ${r.ar ? 'ar' : ''}">${escapeHtml(r.v)}</span>
          </div>`,
        )
        .join('')}
      <div class="editor">
        <h4>تعديل الترخيص</h4>
        <div class="seg" id="seg">
          ${['days', 'months', 'years', 'unlimited']
            .map(
              (type) =>
                `<button data-t="${type}" class="${type === (t.type || 'days') ? 'on' : ''}">${TYPE_LABEL[type]}</button>`,
            )
            .join('')}
        </div>
        <div class="val-row" id="valRow">
          <label>القيمة</label>
          <input id="valInput" type="number" min="1" value="${t.value || 1}" />
        </div>
        <div class="preview" id="preview"></div>
        <div class="d-actions">
          <button class="btn btn-primary" id="saveBtn">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
            حفظ الترخيص
          </button>
          <button class="btn btn-danger" id="revokeBtn">إلغاء الترخيص (رجوع للانتظار)</button>
          ${
            isBlocked
              ? `<button class="btn btn-unblock" id="blockBtn">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 9-9"/><path d="M3 3l18 18"/></svg>
                  فك الحظر عن الجهاز
                </button>`
              : `<button class="btn btn-block" id="blockBtn">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M5 5l14 14"/></svg>
                  حظر الجهاز
                </button>`
          }
        </div>
      </div>`;

    // Segmented control
    const seg = $('seg');
    const valRow = $('valRow');
    const preview = $('preview');
    const valInput = $('valInput');
    let selType = t.type || 'days';

    const paintPreview = () => {
      if (selType === 'unlimited') {
        preview.textContent = '✔ الترخيص هيكون مفتوح مدى الحياة';
        return;
      }
      const v = Math.max(1, Number(valInput.value) || 1);
      const from = new Date();
      const d = new Date(from);
      if (selType === 'days') d.setUTCDate(d.getUTCDate() + v);
      else if (selType === 'months') d.setUTCMonth(d.getUTCMonth() + v);
      else d.setUTCFullYear(d.getUTCFullYear() + v);
      preview.textContent = `هينتهي في ${dtf.format(d)}`;
    };

    seg.addEventListener('click', (e) => {
      const btn = e.target.closest('button[data-t]');
      if (!btn) return;
      selType = btn.dataset.t;
      seg.querySelectorAll('button').forEach((b) => b.classList.toggle('on', b === btn));
      valRow.style.opacity = selType === 'unlimited' ? '0.4' : '1';
      valInput.disabled = selType === 'unlimited';
      paintPreview();
    });
    valInput.addEventListener('input', paintPreview);
    if (selType === 'unlimited') {
      valRow.style.opacity = '0.4';
      valInput.disabled = true;
    }
    paintPreview();

    $('saveBtn').addEventListener('click', async () => {
      const value = selType === 'unlimited' ? 0 : Math.max(1, Number(valInput.value) || 1);
      await saveLicense(device.deviceCode, selType, value);
    });
    $('revokeBtn').addEventListener('click', async () => {
      await saveLicense(device.deviceCode, 'days', 0);
    });
    $('blockBtn').addEventListener('click', async () => {
      await toggleBlocked(device.deviceCode, !isBlocked);
    });

    modalBackdrop.classList.add('open');
    document.body.style.overflow = 'hidden';
  }

  function closeModal() {
    modalBackdrop.classList.remove('open');
    document.body.style.overflow = '';
    state.opened = null;
  }

  async function busy(btn) {
    if (!btn) return;
    btn.disabled = true;
    btn.classList.add('btn-blocking');
  }

  function handleApiError(error) {
    if (error.status === 401 || error.status === 403) {
      localStorage.removeItem(TOKEN_KEY);
      renderLogin(loginErrorMessage(error));
      closeModal();
      return true;
    }
    toast(error.message, 'err');
    return false;
  }

  async function saveLicense(code, type, value) {
    busy($('saveBtn'));
    try {
      const device = await setLicense(code, type, value);
      toast(type === 'unlimited' ? 'تم تفعيل الترخيص مدى الحياة ✓' : 'تم حفظ الترخيص ✓');
      closeModal();
      await load();
    } catch (error) {
      handleApiError(error);
    }
  }

  async function toggleBlocked(code, blocked) {
    busy($('blockBtn'));
    try {
      await setBlocked(code, blocked);
      toast(blocked ? 'تم حظر الجهاز ⛔ — التطبيق هيتقفل عليه' : 'تم فك الحظر ✓');
      closeModal();
      await load();
    } catch (error) {
      handleApiError(error);
    }
  }

  /* ── Copy ── */
  async function copyText(text) {
    try {
      await navigator.clipboard.writeText(text);
      toast('تم نسخ كود الجهاز ✓');
    } catch {
      toast('تعذر النسخ', 'err');
    }
  }

  /* ── Events ── */
  grid.addEventListener('click', (e) => {
    const copyBtn = e.target.closest('.copy');
    if (copyBtn) {
      const cardEl = copyBtn.closest('.card');
      copyText(cardEl.dataset.code || '');
      return;
    }
    const cardEl = e.target.closest('.card');
    if (!cardEl) return;
    const device = state.devices.find((d) => d.deviceCode === cardEl.dataset.code);
    if (device) openModal(device);
  });
  grid.addEventListener('keydown', (e) => {
    if (e.key !== 'Enter') return;
    const cardEl = e.target.closest('.card');
    if (!cardEl) return;
    const device = state.devices.find((d) => d.deviceCode === cardEl.dataset.code);
    if (device) openModal(device);
  });

  $('filters').addEventListener('click', (e) => {
    const btn = e.target.closest('.chip-btn');
    if (!btn) return;
    state.filter = btn.dataset.f;
    document.querySelectorAll('#filters .chip-btn').forEach((b) => {
      const on = b === btn;
      b.classList.toggle('on', on);
      b.classList.toggle('all', on && btn.dataset.f === 'all');
    });
    render();
  });

  searchInput.addEventListener('input', () => {
    state.query = searchInput.value;
    render();
  });

  sortSel.addEventListener('change', () => {
    state.sort = sortSel.value;
    render();
  });

  refreshBtn.addEventListener('click', () => {
    if (!token()) return renderLogin();
    load();
  });

  logoutBtn.addEventListener('click', logout);

  $('modalClose').addEventListener('click', closeModal);
  modalBackdrop.addEventListener('click', (e) => {
    if (e.target === modalBackdrop) closeModal();
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeModal();
  });

  /* ── Boot ── */
  async function boot() {
    setAuthView(true);
    await load();
    setInterval(() => {
      if (document.visibilityState === 'visible' && token()) load();
    }, 30000);
  }

  if (token()) {
    (async () => {
      try {
        state.user = await verifyUser();
        boot();
      } catch (error) {
        localStorage.removeItem(TOKEN_KEY);
        renderLogin(loginErrorMessage(error));
      }
    })();
  } else {
    renderLogin();
  }
})();
