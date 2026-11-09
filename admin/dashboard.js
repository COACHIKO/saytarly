/* Saytarly — protected devices & licenses dashboard.
 *
 * All data goes through the same-origin server API. The GitHub token and the
 * dashboard credentials stay on the server; nothing sensitive is shipped to
 * the browser (the page itself is only served after a valid admin session).
 */

(() => {
  'use strict';

  const i18n = window.SaytarlyI18n;
  const t = (key, vars) => i18n.t(key, vars);
  const getLang = () => i18n.getLang();

  // ── State ──────────────────────────────────────────────────
  const state = {
    devices: [],
    filter: 'all',
    query: '',
    sort: 'lastSeen',
    loading: true,
    error: null,
    opened: null,
    updatedAt: null,
  };

  const $ = (id) => document.getElementById(id);
  const grid = $('grid');
  const statsEl = $('stats');
  const searchInput = $('searchInput');
  const sortSel = $('sort');
  const refreshBtn = $('refreshBtn');
  const logoutBtn = $('logoutBtn');
  const modalBackdrop = $('modalBackdrop');
  const modalBody = $('modalBody');
  const modalTitle = $('modalTitle');

  let rtf;
  let dtf;
  let numberFmt;

  function refreshFormatters() {
    const locale = getLang() === 'ar' ? 'ar-EG' : 'en-GB';
    rtf = new Intl.RelativeTimeFormat(locale, { numeric: 'auto' });
    dtf = new Intl.DateTimeFormat(locale, { dateStyle: 'medium', timeStyle: 'short' });
    numberFmt = new Intl.NumberFormat(locale);
  }

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
    return t('dash.now');
  }

  function fmt(dateStr) {
    if (!dateStr) return '—';
    return dtf.format(new Date(dateStr));
  }

  function statusLabel(status) {
    return t(`dash.status.${status}`);
  }

  function typeLabel(type) {
    return t(`dash.type.${type}`);
  }

  function unitLabel(type, value) {
    if (type === 'unlimited') return t('dash.type.unlimited');
    if (getLang() === 'ar') return t(`dash.type.${type}`);
    const rule = new Intl.PluralRules('en').select(value);
    return t(`dash.unit.${type}.${rule}`);
  }

  function licenseText(device) {
    const license = device.license || {};
    if (license.type === 'unlimited') return t('dash.type.unlimited');
    const type = license.type || 'days';
    const value = license.value || 0;
    return `${numberFmt.format(value)} ${unitLabel(type, value)}`;
  }

  function countdown(device) {
    if (device.status === 'blocked') return t('dash.countdownBlocked');
    if (device.status === 'unlimited') return t('dash.countdownUnlimited');
    if (!device.license || !device.license.expiresAt) return '—';
    if (device.status === 'expired') {
      return t('dash.expiredAgo', { when: rel(device.license.expiresAt) });
    }
    return t('dash.expiresIn', { when: rel(device.license.expiresAt) });
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
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
  }

  /* ── Server API client ───────────────────────────────────── */
  async function api(pathname, options = {}) {
    const headers = { Accept: 'application/json', ...(options.headers || {}) };
    if (options.body && !headers['Content-Type']) {
      headers['Content-Type'] = 'application/json';
    }
    let res;
    try {
      res = await fetch(pathname, {
        ...options,
        headers,
        credentials: 'same-origin',
      });
    } catch (cause) {
      const error = new Error(t('dash.err.connection'));
      error.cause = cause;
      throw error;
    }
    const text = await res.text();
    let data = null;
    try {
      data = JSON.parse(text);
    } catch {
      /* non-JSON body */
    }
    if (!res.ok) {
      const error = new Error((data && data.error) || res.statusText || `HTTP ${res.status}`);
      error.status = res.status;
      throw error;
    }
    return data;
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

  /* ── Fetch devices ───────────────────────────────────────── */
  async function load() {
    state.loading = true;
    state.error = null;
    render();
    try {
      const data = await api('/api/devices');
      state.devices = Array.isArray(data.devices) ? data.devices : [];
      state.updatedAt = new Date();
      renderLastUpdated();
    } catch (error) {
      if (error.status === 401) {
        // Session expired — reload so the server can show the login page.
        window.location.replace('/dashboard');
        return;
      }
      state.error = error.message;
    } finally {
      state.loading = false;
      render();
    }
  }

  async function setLicense(code, type, value) {
    const allowed = ['days', 'months', 'years', 'unlimited'];
    if (!allowed.includes(type)) {
      throw new Error(t('dash.err.invalidType', { type }));
    }
    const num = Number(value);
    if (type !== 'unlimited' && (!Number.isInteger(num) || num < 0)) {
      throw new Error(t('dash.err.invalidValue'));
    }
    const data = await api(`/api/devices/${encodeURIComponent(code)}/license`, {
      method: 'POST',
      body: JSON.stringify({
        type,
        value: type === 'unlimited' ? 0 : num,
      }),
    });
    return data.device;
  }

  async function setBlocked(code, blocked) {
    const data = await api(`/api/devices/${encodeURIComponent(code)}/block`, {
      method: 'POST',
      body: JSON.stringify({ blocked: blocked === true }),
    });
    return data.device;
  }

  /* ── Last updated ────────────────────────────────────────── */
  function renderLastUpdated() {
    const el = $('lastUpdated');
    if (!el) return;
    if (!state.updatedAt) {
      el.textContent = '—';
      return;
    }
    el.textContent = new Intl.DateTimeFormat(
      getLang() === 'ar' ? 'ar-EG' : 'en-GB',
      { hour: '2-digit', minute: '2-digit', second: '2-digit' },
    ).format(state.updatedAt);
  }

  /* ── Stats ── */
  function animateCount(el, target) {
    const dur = 700;
    const start = performance.now();
    const tick = (now) => {
      const p = Math.min(1, (now - start) / dur);
      const eased = 1 - Math.pow(1 - p, 3);
      el.textContent = numberFmt.format(Math.round(target * eased));
      if (p < 1) requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  }

  function renderStats() {
    const count = (status) => state.devices.filter((d) => d.status === status).length;
    const items = [
      { label: t('dash.stat.total'), value: state.devices.length, color: 'var(--accent)' },
      { label: t('dash.stat.active'), value: count('active'), color: 'var(--success)' },
      { label: t('dash.stat.unlimited'), value: count('unlimited'), color: 'var(--info)' },
      { label: t('dash.stat.pending'), value: count('pending'), color: 'var(--warning)' },
      { label: t('dash.stat.expired'), value: count('expired'), color: 'var(--danger)' },
      { label: t('dash.stat.blocked'), value: count('blocked'), color: '#ff3b3b' },
    ];
    statsEl.innerHTML = items
      .map(
        (it, i) => `
      <div class="stat">
        <div class="num" data-i="${i}">0</div>
        <div class="lbl">${escapeHtml(it.label)}</div>
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
        list.sort((a, b) => (a.pcName || '').localeCompare(b.pcName || '', getLang()));
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

  function platformName(device) {
    return t(device.platform === 'windows' ? 'dash.platform.windows' : 'dash.platform.android');
  }

  function card(d) {
    const st = d.status || 'pending';
    return `
    <article class="card ${st === 'blocked' ? 'is-blocked' : ''}" data-code="${escapeHtml(d.deviceCode)}" tabindex="0">
      <div class="top">
        <div class="name">
          <span class="av">${d.platform === 'windows' ? ICON_DEVICE(21) : ICON_PHONE(21)}</span>
          <div>
            <b>${escapeHtml(d.pcName || t('dash.device'))}</b>
            <small>${escapeHtml(platformName(d))} · v${escapeHtml(d.appVersion || '—')} (b${d.buildNumber ?? 0})</small>
          </div>
        </div>
        <span class="badge ${st}"><span class="dot"></span>${escapeHtml(statusLabel(st))}</span>
      </div>
      <div class="code">
        <span>${escapeHtml(d.deviceCode || '')}</span>
        <button class="copy" title="${escapeHtml(t('dash.copyCode'))}">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="12" height="12" rx="2"/><path d="M5 15V5a2 2 0 0 1 2-2h10"/></svg>
        </button>
      </div>
      <div class="meta">
        <div class="box"><small>${escapeHtml(t('dash.license'))}</small><b>${escapeHtml(licenseText(d))}</b></div>
        <div class="box"><small>${escapeHtml(t('dash.validity'))}</small><b>${escapeHtml(countdown(d))}</b></div>
      </div>
      <div class="foot">
        <span class="seen">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>
          ${escapeHtml(t('dash.seen', { when: rel(d.lastSeenAt) }))}
        </span>
        <span>${escapeHtml(t('dash.registered', { when: fmt(d.firstSeenAt) }))}</span>
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
        <h3>${escapeHtml(t('dash.loadErrorTitle'))}</h3>
        <p>${escapeHtml(state.error)}</p>
        <button class="btn btn-primary" style="margin:18px auto 0" onclick="location.reload()">${escapeHtml(t('dash.retry'))}</button>
      </div>`;
      return;
    }

    const list = filteredDevices();
    if (!state.devices.length) {
      grid.innerHTML = `<div class="empty">
        <span class="ic"><svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2.5" y="4.5" width="19" height="13" rx="2"/><path d="M8 21h8M12 17.5V21"/></svg></span>
        <h3>${escapeHtml(t('dash.emptyTitle'))}</h3>
        <p>${escapeHtml(t('dash.emptyText'))}</p>
      </div>`;
      return;
    }
    if (!list.length) {
      grid.innerHTML = `<div class="empty">
        <span class="ic"><svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg></span>
        <h3>${escapeHtml(t('dash.noResultsTitle'))}</h3>
        <p>${escapeHtml(t('dash.noResultsText'))}</p>
      </div>`;
      return;
    }
    grid.innerHTML = list.map(card).join('');
  }

  /* ── Modal ── */
  function openModal(device) {
    state.opened = device;
    const st = device.status || 'pending';
    const license = device.license || {};
    const isBlocked = device.blocked === true;

    modalTitle.textContent = t('dash.modalTitle');

    const rows = [
      { k: t('dash.row.code'), v: device.deviceCode, ar: false },
      { k: t('dash.row.platform'), v: device.platform === 'windows' ? 'Windows' : 'Android', ar: false },
      {
        k: t('dash.row.version'),
        v: `${device.appVersion || '—'} · ${t('dash.row.build', { n: device.buildNumber ?? 0 })}`,
        ar: false,
      },
      { k: t('dash.row.licenseType'), v: typeLabel(license.type || 'days'), ar: true },
      {
        k: t('dash.row.licenseValue'),
        v: license.type === 'unlimited' ? '∞' : String(license.value ?? 0),
        ar: false,
      },
      { k: t('dash.row.issued'), v: fmt(license.issuedAt), ar: true },
      { k: t('dash.row.expires'), v: license.expiresAt ? fmt(license.expiresAt) : '—', ar: true },
      { k: t('dash.row.firstSeen'), v: fmt(device.firstSeenAt), ar: true },
      {
        k: t('dash.row.lastSeen'),
        v: `${fmt(device.lastSeenAt)} · ${rel(device.lastSeenAt)}`,
        ar: true,
      },
      ...(isBlocked && device.blockedAt
        ? [{
            k: t('dash.row.blockedAt'),
            v: `${fmt(device.blockedAt)} · ${rel(device.blockedAt)}`,
            ar: true,
          }]
        : []),
    ];

    modalBody.innerHTML = `
      <div class="d-id">
        <span class="av">${device.platform === 'windows' ? ICON_DEVICE(30) : ICON_PHONE(30)}</span>
        <h2>${escapeHtml(device.pcName || t('dash.device'))}</h2>
        <div class="pc">${escapeHtml(device.deviceCode || '')}</div>
        <span class="badge ${st}" style="margin-top:10px"><span class="dot"></span>${escapeHtml(statusLabel(st))}</span>
      </div>
      ${
        isBlocked
          ? `<div class="blocked-banner">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M5 5l14 14"/></svg>
              ${escapeHtml(t('dash.blockedBanner'))}
            </div>`
          : ''
      }
      ${rows
        .map(
          (r) => `<div class="row">
            <span class="k">
              <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="9"/></svg>
              ${escapeHtml(r.k)}
            </span>
            <span class="v ${r.ar ? 'ar' : ''}">${escapeHtml(r.v)}</span>
          </div>`,
        )
        .join('')}
      <div class="editor">
        <h4>${escapeHtml(t('dash.editLicense'))}</h4>
        <div class="seg" id="seg">
          ${['days', 'months', 'years', 'unlimited']
            .map(
              (type) =>
                `<button data-t="${type}" class="${type === (license.type || 'days') ? 'on' : ''}">${escapeHtml(typeLabel(type))}</button>`,
            )
            .join('')}
        </div>
        <div class="val-row" id="valRow">
          <label>${escapeHtml(t('dash.value'))}</label>
          <input id="valInput" type="number" min="1" value="${license.value || 1}" />
        </div>
        <div class="preview" id="preview"></div>
        <div class="d-actions">
          <button class="btn btn-primary" id="saveBtn">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
            ${escapeHtml(t('dash.saveLicense'))}
          </button>
          <button class="btn btn-danger" id="revokeBtn">${escapeHtml(t('dash.revoke'))}</button>
          ${
            isBlocked
              ? `<button class="btn btn-unblock" id="blockBtn">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 9-9"/><path d="M3 3l18 18"/></svg>
                  ${escapeHtml(t('dash.unblock'))}
                </button>`
              : `<button class="btn btn-block" id="blockBtn">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M5 5l14 14"/></svg>
                  ${escapeHtml(t('dash.block'))}
                </button>`
          }
        </div>
      </div>`;

    // Segmented control
    const seg = $('seg');
    const valRow = $('valRow');
    const preview = $('preview');
    const valInput = $('valInput');
    let selType = license.type || 'days';

    const paintPreview = () => {
      if (selType === 'unlimited') {
        preview.textContent = t('dash.previewUnlimited');
        return;
      }
      const v = Math.max(1, Number(valInput.value) || 1);
      const d = computeExpiry(selType, v, new Date());
      preview.textContent = t('dash.previewExpires', { date: dtf.format(d) });
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

  function busy(btn) {
    if (!btn) return;
    btn.disabled = true;
    btn.classList.add('btn-blocking');
  }

  function handleApiError(error) {
    if (error.status === 401) {
      window.location.replace('/dashboard');
      return true;
    }
    toast(error.message, 'err');
    return false;
  }

  async function saveLicense(code, type, value) {
    busy($('saveBtn'));
    try {
      await setLicense(code, type, value);
      toast(type === 'unlimited' ? t('dash.toast.licenseUnlimited') : t('dash.toast.licenseSaved'));
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
      toast(blocked ? t('dash.toast.blocked') : t('dash.toast.unblocked'));
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
      toast(t('dash.toast.copied'));
    } catch {
      toast(t('dash.toast.copyFailed'), 'err');
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

  refreshBtn.addEventListener('click', () => load());

  logoutBtn.addEventListener('click', async () => {
    try {
      await api('/api/auth/logout', { method: 'POST' });
    } catch {
      /* ignore — the cookie will be cleared server-side if it can be */
    }
    window.location.replace('/dashboard');
  });

  $('modalClose').addEventListener('click', closeModal);
  modalBackdrop.addEventListener('click', (e) => {
    if (e.target === modalBackdrop) closeModal();
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeModal();
  });

  document.addEventListener('saytarly:langchange', () => {
    refreshFormatters();
    renderLastUpdated();
    render();
    if (state.opened) {
      const device = state.devices.find((d) => d.deviceCode === state.opened.deviceCode);
      if (device) openModal(device);
    }
  });

  /* ── Boot ── */
  document.addEventListener('DOMContentLoaded', () => {
    refreshFormatters();
    load();
    setInterval(() => {
      if (document.visibilityState === 'visible') load();
    }, 30000);
  });
})();
