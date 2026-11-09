/* Saytarly — 7-day demo request form.
 *
 * The marketing site is static (also deployed to GitHub Pages), so submitting
 * composes an email to the team with the subject "Demo request — <cafe>" and
 * all the entered details, then opens the visitor's mail app. Nothing is sent
 * until the visitor hits send in their own email client.
 */
(function () {
  'use strict';

  var EMAIL = 'saytarly.official@gmail.com';
  var EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

  var form = document.getElementById('demoForm');
  var statusEl = document.getElementById('formStatus');

  function t(key) {
    return window.SaytarlyI18n ? window.SaytarlyI18n.t(key) : key;
  }

  function value(id) {
    var el = document.getElementById(id);
    return el ? el.value.trim() : '';
  }

  function setInvalid(fieldId, invalid) {
    var field = document.getElementById(fieldId);
    if (field) field.classList.toggle('invalid', invalid);
    return !invalid;
  }

  function validate() {
    var cafe = value('cafe');
    var email = value('email');
    var phone = value('phone').replace(/[\s-]/g, '');

    var cafeOk = setInvalid('fieldCafe', cafe === '');
    var emailOk = setInvalid('fieldEmail', !EMAIL_RE.test(email));
    var phoneOk = setInvalid('fieldPhone', !/^\+?\d{7,15}$/.test(phone));

    return cafeOk && emailOk && phoneOk;
  }

  /* ── Clear an error as soon as the visitor edits the field ── */

  ['cafe', 'email', 'phone'].forEach(function (id) {
    var el = document.getElementById(id);
    if (!el) return;
    el.addEventListener('input', function () {
      var field = el.closest('.field');
      if (field) field.classList.remove('invalid');
      if (statusEl) statusEl.classList.remove('show');
    });
  });

  if (!form) return;

  form.addEventListener('submit', function (event) {
    event.preventDefault();
    if (!validate()) return;

    var cafe = value('cafe');
    var email = value('email');
    var phone = value('phone');
    var location = value('location');

    var subject = 'Demo request — ' + cafe;

    var lines = [
      'Demo request / طلب ديمو',
      '',
      'Cafe / restaurant — اسم المكان: ' + cafe,
      'Email — الإيميل: ' + email,
      'Phone — رقم التواصل: ' + phone,
      'Location — المكان: ' + (location || '—'),
    ];

    window.location.href =
      'mailto:' +
      EMAIL +
      '?subject=' +
      encodeURIComponent(subject) +
      '&body=' +
      encodeURIComponent(lines.join('\n'));

    if (statusEl) {
      statusEl.textContent = t('demo.form.opened');
      statusEl.classList.add('show');
    }
  });
})();
