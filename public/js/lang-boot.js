/* Apply the saved language before first paint to avoid a flash of the wrong direction. */
(function () {
  'use strict';
  var lang = 'ar';
  try {
    var fromUrl = new URLSearchParams(window.location.search).get('lang');
    if (fromUrl === 'ar' || fromUrl === 'en') {
      lang = fromUrl;
      try { localStorage.setItem('saytarly_lang', lang); } catch (e) { /* ignore */ }
    } else {
      var saved = localStorage.getItem('saytarly_lang');
      if (saved === 'ar' || saved === 'en') lang = saved;
    }
  } catch (e) { /* ignore */ }
  document.documentElement.lang = lang;
  document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
})();
