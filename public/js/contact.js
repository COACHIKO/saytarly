/* Saytarly — contact page behaviour.
 *
 * The marketing site is static (it is also deployed to GitHub Pages), so the
 * message form does not post to a server: it composes a ready-to-send email to
 * the team via `mailto:` and opens the visitor's mail app. The same message can
 * be sent over WhatsApp instead (also fully client-side). The call button is a
 * plain `tel:` link in the markup.
 */
(function () {
  'use strict';

  var EMAIL = 'saytarly.official@gmail.com';
  var WHATSAPP_NUMBER = '201018089212'; // international format of 01018089212

  var form = document.getElementById('contactForm');
  var statusEl = document.getElementById('formStatus');
  var copyBtn = document.getElementById('copyEmail');

  function t(key) {
    return window.SaytarlyI18n ? window.SaytarlyI18n.t(key) : key;
  }

  function value(id) {
    var el = document.getElementById(id);
    return el ? el.value.trim() : '';
  }

  /* ── Validation ───────────────────────────────────────── */

  function setInvalid(fieldId, invalid) {
    var field = document.getElementById(fieldId);
    if (field) field.classList.toggle('invalid', invalid);
    return !invalid;
  }

  function validate() {
    var nameOk = setInvalid('fieldName', value('name') === '');
    var contactOk = setInvalid('fieldContact', value('contact') === '');
    var messageOk = setInvalid('fieldMessage', value('message') === '');
    return nameOk && contactOk && messageOk;
  }

  ['name', 'contact', 'message'].forEach(function (id) {
    var el = document.getElementById(id);
    if (!el) return;
    el.addEventListener('input', function () {
      el.closest('.field').classList.remove('invalid');
      if (statusEl) statusEl.classList.remove('show');
    });
  });

  /* ── Message body ─────────────────────────────────────── */

  function buildMessage() {
    var name = value('name');
    var contact = value('contact');
    var message = value('message');
    var subject = value('subject') || t('contact.form.defaultSubject');

    var body = [
      t('contact.form.bodyName') + ': ' + name,
      t('contact.form.bodyContact') + ': ' + contact,
      '',
      message,
    ].join('\n');

    return { subject: subject, body: body, text: subject + '\n\n' + body };
  }

  function showStatus(text) {
    if (!statusEl) return;
    statusEl.textContent = text;
    statusEl.classList.add('show');
  }

  /* ── Send via email app ───────────────────────────────── */

  if (form) {
    form.addEventListener('submit', function (event) {
      event.preventDefault();
      if (!validate()) return;

      var data = buildMessage();
      window.location.href =
        'mailto:' +
        EMAIL +
        '?subject=' +
        encodeURIComponent(data.subject) +
        '&body=' +
        encodeURIComponent(data.body);

      showStatus(t('contact.form.opened'));
    });
  }

  /* ── Send via WhatsApp ────────────────────────────────── */

  var waBtn = document.getElementById('sendWhatsapp');
  if (waBtn) {
    waBtn.addEventListener('click', function () {
      if (!validate()) return;
      var data = buildMessage();
      window.open(
        'https://wa.me/' + WHATSAPP_NUMBER + '?text=' + encodeURIComponent(data.text),
        '_blank',
        'noopener',
      );
      showStatus(t('contact.form.openedWhatsapp'));
    });
  }

  /* ── Copy email address ───────────────────────────────── */

  if (copyBtn) {
    var copyLabel = copyBtn.querySelector('[data-copy-label]');
    var resetTimer = null;

    copyBtn.addEventListener('click', function () {
      function done() {
        if (copyLabel) copyLabel.textContent = t('contact.copied');
        clearTimeout(resetTimer);
        resetTimer = setTimeout(function () {
          if (copyLabel) copyLabel.textContent = t('contact.copy');
        }, 2000);
      }

      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(EMAIL).then(done, fallback);
      } else {
        fallback();
      }

      function fallback() {
        var input = document.createElement('textarea');
        input.value = EMAIL;
        input.setAttribute('readonly', '');
        input.style.position = 'fixed';
        input.style.opacity = '0';
        document.body.appendChild(input);
        input.select();
        try {
          document.execCommand('copy');
          done();
        } catch (error) {
          /* Clipboard blocked — the address is visible next to the button. */
        }
        document.body.removeChild(input);
      }
    });

    document.addEventListener('saytarly:langchange', function () {
      if (copyLabel) copyLabel.textContent = t('contact.copy');
    });
  }
})();
