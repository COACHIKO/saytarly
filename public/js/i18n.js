/* Saytarly — tiny bilingual (Arabic / English) localization runtime.
 *
 * Usage in HTML:
 *   <h1 data-i18n="hero.title"></h1>
 *   <div data-i18n-html="hero.title"></div>   (trusted static HTML only)
 *   <input data-i18n-placeholder="dash.searchPlaceholder" />
 *   <button data-i18n-aria-label="nav.menu" />
 *   <title data-i18n="meta.title"></title>
 *   <meta name="description" data-i18n-content="meta.description" />
 *
 * In JavaScript:
 *   SaytarlyI18n.t('dash.refresh')
 *   document.addEventListener('saytarly:langchange', () => { ... })
 */
(function () {
  'use strict';

  var STORAGE_KEY = 'saytarly_lang';

  var AR = {
    /* ── Site metadata ─────────────────────────────────── */
    'meta.title': 'Saytarly — نظام إدارة المطاعم والكافيهات',
    'meta.description':
      'Saytarly — نقطة بيع، مخزون، شيفتات وتقارير لمطعمك أو كافيهك على ويندوز وأندرويد، بشغل متواصل حتى من غير إنترنت.',

    /* ── Navigation ────────────────────────────────────── */
    'nav.features': 'المميزات',
    'nav.modes': 'أوضاع التشغيل',
    'nav.contact': 'تواصل معنا',
    'nav.menu': 'القائمة',
    'nav.langSwitch': 'تغيير اللغة',

    /* ── Hero ──────────────────────────────────────────── */
    'hero.badge': 'نظام إدارة المطاعم والكافيهات',
    'hero.title': 'شغّل مطعمك بنظام واحد…<br /><em>نقطة بيع، مخزون، وتقارير.</em>',
    'hero.lead':
      'Saytarly بيجمع كل حاجة مكانك محتاجها في تطبيق واحد: كاشير سريع للطلبات والطاولات، قوائم كاملة، شيفتات لموظفيك، مخزون تحت السيطرة، وتقارير بتوريك مكسبك أول بأول — بشغل متواصل حتى من غير إنترنت.',
    'hero.ctaPrimary': 'اطلب نسختك',
    'hero.ctaSecondary': 'شوف المميزات',
    'hero.sales': 'مبيعات اليوم: 12,450 ج.م<small>بتتحدث لحظيًا مع كل طلب</small>',
    'hero.bestSeller': 'أكتر صنف بيعًا: إسبريسو<small>التقرير بيتحدث تلقائيًا</small>',
    'hero.shift': 'شيفت مفتوح — 4 موظفين<small>مبيعات الشيفت: 8,900 ج.م</small>',

    /* ── Stats strip ───────────────────────────────────── */
    'stats.categories': 'أقسام قائمة لا محدودة — بتضيف وتخصص على مزاجك',
    'stats.uptime': 'شغل متواصل حتى من غير إنترنت',
    'stats.custom': 'قابل للتخصيص — لوجو، اسم، ثيم، ولغة',
    'stats.multi': 'متعدد',
    'stats.currencies': 'عملات وأسعار بتحكم كامل',

    /* ── Features ──────────────────────────────────────── */
    'features.kicker': '— كل مميزات التطبيق —',
    'features.title': 'كل تفصيلة في يومك ليها أداة جاهزة',
    'features.subtitle':
      'من أول طلب على الترابيزة لحد آخر تقرير — وكل حاجة تقدر تخصصها على مزاجك.',

    'features.cat1.title': 'التشغيل اليومي',
    'features.cat1.sub': 'كاشير وطاولات وشيفتات من غير تعقيد',
    'features.cat1.f1.title': 'نقطة بيع سريعة',
    'features.cat1.f1.desc': 'كاشير مبني للسرعة: طلبات وفواتير من غير أي تعقيد، بيعمل في ثواني.',
    'features.cat1.f2.title': 'طاولات وطلبات',
    'features.cat1.f2.desc': 'إدارة كاملة للطاولات: افتح طلب، ضيف عليه، وانقل أو ادمج من غير لخبطة.',
    'features.cat1.f3.title': 'طباعة الفواتير',
    'features.cat1.f3.desc': 'فواتير مطبوعة جاهزة للكاشير أو الطلبات — بضغطة من غير إعدادات معقدة.',
    'features.cat1.f4.title': 'شيفتات الموظفين',
    'features.cat1.f4.desc': 'كل شيفت متسجل: مبيعاته، كاشه، ووقته — وسلّم واستلم من غير خلافات.',
    'features.cat1.f5.title': 'حسابات وصلاحيات',
    'features.cat1.f5.desc': 'كل موظف ليه حسابه وصلاحياته — محدش يقدر يعدي حدوده.',

    'features.cat2.title': 'منيو بلا حدود — تخصيص كامل',
    'features.cat2.sub': 'أقسام وأصناف وأسعار كلها تحت إيدك',
    'features.cat2.f1.title': 'أقسام لا محدودة',
    'features.cat2.f1.desc': 'مش 4 أقسام وبس — ضيف قد ما تحب: أكل، مشروبات، حلويات، مقبلات، وأي حاجة تانية.',
    'features.cat2.f2.title': 'أصناف وأسعار وأحجام',
    'features.cat2.f2.desc': 'كل صنف بأسعاره وأحجامه وإضافاته — وعدّل السعر في لحظة واحدة.',
    'features.cat2.f3.title': 'عملات متعددة',
    'features.cat2.f3.desc': 'شغّل أكتر من عملة في نفس الوقت، وبدّل العملة والتسعير في ثواني.',
    'features.cat2.f4.title': 'ملف تجاري مخصص',
    'features.cat2.f4.desc': 'اسم مكانك ولوجو بتاعك على الفواتير وواجهة التطبيق — بتبصيله هويتك.',
    'features.cat2.f5.title': 'ثيم ولغة على مزاجك',
    'features.cat2.f5.desc': 'عربي أو إنجليزي، وضع نهاري أو ليلي — خلي الواجهة مريحة لموظفينك.',

    'features.cat3.title': 'المخزون والفلوس',
    'features.cat3.sub': 'عرف كل جنيه داخل وطالع من مكانك',
    'features.cat3.f1.title': 'مخزون الخامات',
    'features.cat3.f1.desc': 'تابع كل خامة في مكانك — وعرف نقص إيه قبل ما يوقفلك الشغل.',
    'features.cat3.f2.title': 'موردون ومشتريات',
    'features.cat3.f2.desc': 'سجّل مشترياتك من الموردين — واعرف مين بيسعّرك أحسن من مين.',
    'features.cat3.f3.title': 'المصروفات',
    'features.cat3.f3.desc': 'كل مصروف بتسجله: خامات، إيجار، كهربا — والتقرير بيقولك صرفت قد إيه.',
    'features.cat3.f4.title': 'ديون وآجل',
    'features.cat3.f4.desc': 'تتبع اللي ليك عند العملاء واللي عليك للموردين — مفيش حساب هيضيع.',
    'features.cat3.f5.title': 'تقارير ومبيعات',
    'features.cat3.f5.desc': 'إيراد اليوم، أكتر الأصناف بيعًا، الأداء بالشيفت — الأرقام كلها قدامك.',

    'features.cat4.title': 'شغال من غير توقف',
    'features.cat4.sub': 'نظام ثابت معاك في كل الظروف',
    'features.cat4.f1.title': 'وضع أوفلاين كامل',
    'features.cat4.f1.desc': 'النظام شغال 100% على جهازك — لو النت قطع، شغلك مبيتأثرش بثانية.',
    'features.cat4.f2.title': 'تحديثات من متجر Saytarly',
    'features.cat4.f2.desc': 'مميزات جديدة بتوصلك تلقائيًا — وممكن ترجع لنسخة أقدم لو حصلت مشكلة.',
    'features.cat4.f3.title': 'ويندوز وأندرويد',
    'features.cat4.f3.desc': 'شغّله على كمبيوتر الكاشير وعلى موبايلك — نفس الحسابات ونفس البيانات.',
    'features.cat4.f4.title': 'نسخ احتياطي واسترجاع',
    'features.cat4.f4.desc': 'بياناتك بتتأمن بنسخة احتياطية — وترجّعها في أي وقت بضغطة واحدة.',
    'features.cat4.f5.title': 'شغال في الخلفية',
    'features.cat4.f5.desc': 'على ويندوز التطبيق بيفضل شغال في شريط المهام — قفّل النافذة وشغلك مستمر.',

    /* ── Modes ─────────────────────────────────────────── */
    'modes.kicker': '— نسختين للتطبيق —',
    'modes.title': 'اختار التشغيل اللي يناسب مكانك',
    'modes.subtitle': 'نفس التطبيق ونفس المميزات — انت بتختار اللي يريحك في شغلك اليومي.',
    'modes.online.title': 'وضع Online',
    'modes.online.sub': 'التجربة الكاملة',
    'modes.online.item1': 'دايمًا على آخر نسخة — التحديثات بتوصلك تلقائيًا من متجر Saytarly',
    'modes.online.item2': 'مميزات جديدة بتضاف باستمرار من غير ما تعمل حاجة',
    'modes.online.item3': 'لو حصلت مشكلة في تحديث، بترجع للنسخة القديمة بضغطة',
    'modes.online.item4': 'مناسب للأماكن اللي عندها إنترنت ثابت',
    'modes.offline.title': 'وضع Offline',
    'modes.offline.sub': 'شغال 100% من غير إنترنت',
    'modes.offline.item1': 'كل المميزات شغالة على جهازك من غير أي إنترنت',
    'modes.offline.item2': 'بياناتك كلها محفوظة محليًا على جهازك',
    'modes.offline.item3': 'مفيش أي مقاطعة لشغلك — حتى لو النت فصل فجأة',
    'modes.offline.item4': 'مثالي للأماكن اللي النت فيها ضعيف أو مش موجود',

    /* ── CTA & contact ─────────────────────────────────── */
    'cta.title': 'جاهز تشغّل مطعمك على Saytarly؟',
    'cta.subtitle': 'اطلب نسختك النهاردة وابدأ بجهاز واحد — ووسّع على قد ما شغلك يكبر.',
    'cta.button': 'تواصل معنا ←',
    'contact.title': 'عندك سؤال أو عايز تجرب؟',
    'contact.subtitle': 'فريقنا جاهز يساعدك في أي استفسار عن النظام أو الأسعار.',

    /* ── Contact page ──────────────────────────────────── */
    'contact.metaTitle': 'تواصل معنا — Saytarly',
    'contact.metaDescription':
      'تواصل مع فريق Saytarly — إيميل، واتساب، أو مكالمة على 01018089212.',
    'contact.kicker': 'تواصل معنا',
    'contact.heading': 'كلمنا في أي وقت — إحنا هنا نساعدك',
    'contact.lead':
      'سواء عندك سؤال عن النظام، محتاج عرض سعر، أو عايز تجرب Saytarly على مكانك — ابعتلنا إيميل، كلّمنا على واتساب، أو اتصل بينا مباشرة.',
    'contact.email.title': 'البريد الإلكتروني',
    'contact.email.desc': 'ابعتلنا تفاصيل مكانك واستفسارك وهنرد عليك في أقرب وقت.',
    'contact.email.cta': 'ابعت إيميل',
    'contact.whatsapp.title': 'واتساب',
    'contact.whatsapp.desc': 'أسرع طريقة للرد — ابعتلنا رسالة وهنكلمك على طول.',
    'contact.whatsapp.cta': 'كلّمنا على واتساب',
    'contact.call.title': 'اتصال مباشر',
    'contact.call.desc': 'عايز تكلم حد؟ اتصل بينا مباشرة خلال مواعيد العمل.',
    'contact.call.cta': 'اتصل بينا',
    'contact.copy': 'نسخ',
    'contact.copied': 'تم النسخ ✓',
    'contact.form.title': 'ابعتلنا رسالة',
    'contact.form.desc':
      'املأ البيانات وهنجهزلك الرسالة جاهزة على الإيميل — تراجعها وتبعت.',
    'contact.form.name': 'الاسم',
    'contact.form.namePlaceholder': 'اسمك',
    'contact.form.contact': 'إيميل أو رقم موبايل',
    'contact.form.contactPlaceholder': 'name@example.com / 01xxxxxxxxx',
    'contact.form.subject': 'الموضوع',
    'contact.form.subjectPlaceholder': 'استفسار عن Saytarly',
    'contact.form.message': 'رسالتك',
    'contact.form.messagePlaceholder': 'اكتب تفاصيل استفسارك…',
    'contact.form.send': 'إرسال الإيميل',
    'contact.form.sendWhatsapp': 'إرسال على واتساب',
    'contact.form.defaultSubject': 'رسالة من صفحة التواصل — Saytarly',
    'contact.form.bodyName': 'الاسم',
    'contact.form.bodyContact': 'بيانات التواصل',
    'contact.form.note':
      'لما تدوس «إرسال الإيميل» هيتفتح تطبيق الإيميل عندك والرسالة جاهزة على <a href="mailto:saytarly.official@gmail.com">saytarly.official@gmail.com</a> — راجعها وابعت.',
    'contact.form.errName': 'اكتب اسمك.',
    'contact.form.errContact': 'اكتب إيميل أو رقم موبايل نرد عليه.',
    'contact.form.errMessage': 'اكتب رسالتك.',
    'contact.form.opened':      'تم تجهيز الرسالة — ابعتہا من تطبيق الإيميل.',
    'contact.form.openedWhatsapp': 'بنفتح واتساب بالرسالة جاهزة…',
    'footer.copy': '© 2026 Saytarly — نظام إدارة المطاعم والكافيهات.',

    /* ── 404 ───────────────────────────────────────────── */
    'notfound.text': 'الصفحة دي مش موجودة — ارجع للرئيسية.',
    'notfound.home': 'الرئيسية',

    /* ── Login ─────────────────────────────────────────── */
    'auth.pageTitle': 'دخول لوحة الأجهزة — Saytarly',
    'auth.badge': 'دخول محمي',
    'auth.title': 'لوحة الأجهزة',
    'auth.subtitle': 'ادخل بياناتك للوصول للوحة إدارة الأجهزة والتراخيص.',
    'auth.username': 'اسم المستخدم',
    'auth.usernamePlaceholder': 'اسم المستخدم',
    'auth.password': 'كلمة المرور',
    'auth.passwordPlaceholder': 'كلمة المرور',
    'auth.submit': 'دخول',
    'auth.submitting': 'بيتحقق…',
    'auth.invalid': 'اسم المستخدم أو كلمة المرور غير صحيحة.',
    'auth.rateLimited': 'محاولات كتير — استنى شوية وجرب تاني.',
    'auth.error': 'حصلت مشكلة، جرب تاني.',
    'auth.back': 'الرجوع للرئيسية',
    'auth.secureNote': 'الوصول محمي على السيرفر — بيانات الدخول مش موجودة في الصفحة.',

    /* ── Dashboard ─────────────────────────────────────── */
    'dash.pageTitle': 'لوحة الأجهزة — Saytarly',
    'dash.navHome': 'الرئيسية',
    'dash.live': 'Live — بيتحدث كل 30 ثانية',
    'dash.title': 'لوحة الأجهزة والتراخيص',
    'dash.lead':
      'كل جهاز شغّل Saytarly بيسجل نفسه هنا تلقائيًا — شوف حالته، انسخ كوده، وفعّل أو أوقف ترخيصه.',
    'dash.refresh': 'تحديث الآن',
    'dash.lastUpdatedLabel': 'آخر تحديث:',
    'dash.logout': 'تسجيل الخروج',
    'dash.searchPlaceholder': 'دوّر باسم الجهاز أو الكود…',
    'dash.filter.all': 'الكل',
    'dash.filter.active': 'مفعّل',
    'dash.filter.unlimited': 'مدى الحياة',
    'dash.filter.pending': 'بانتظار التفعيل',
    'dash.filter.expired': 'منتهي',
    'dash.filter.blocked': 'محظور',
    'dash.sort.lastSeen': 'الأحدث ظهورًا',
    'dash.sort.name': 'الاسم أبجديًا',
    'dash.sort.oldest': 'الأقدم ظهورًا',
    'dash.sort.version': 'النسخة',
    'dash.modalTitle': 'تفاصيل الجهاز',
    'dash.close': 'إغلاق',
    'dash.status.active': 'مفعّل',
    'dash.status.unlimited': 'مدى الحياة',
    'dash.status.pending': 'بانتظار التفعيل',
    'dash.status.expired': 'منتهي',
    'dash.status.blocked': 'محظور',
    'dash.type.days': 'أيام',
    'dash.type.months': 'شهور',
    'dash.type.years': 'سنين',
    'dash.type.unlimited': 'مدى الحياة',
    'dash.unit.days.one': 'يوم',
    'dash.unit.days.other': 'أيام',
    'dash.unit.months.one': 'شهر',
    'dash.unit.months.other': 'شهور',
    'dash.unit.years.one': 'سنة',
    'dash.unit.years.other': 'سنين',
    'dash.countdownBlocked': 'محظور ⛔',
    'dash.countdownUnlimited': '∞ مدى الحياة',
    'dash.expiresIn': 'ينتهي {when}',
    'dash.expiredAgo': 'منتهي {when}',
    'dash.now': 'الآن',
    'dash.stat.total': 'إجمالي الأجهزة',
    'dash.stat.active': 'مفعّل',
    'dash.stat.unlimited': 'مدى الحياة',
    'dash.stat.pending': 'بانتظار التفعيل',
    'dash.stat.expired': 'منتهي',
    'dash.stat.blocked': 'محظور',
    'dash.device': 'جهاز',
    'dash.platform.windows': 'ويندوز',
    'dash.platform.android': 'أندرويد',
    'dash.copyCode': 'نسخ الكود',
    'dash.license': 'الترخيص',
    'dash.validity': 'الصلاحية',
    'dash.seen': 'آخر ظهور {when}',
    'dash.registered': 'سُجّل {when}',
    'dash.loadErrorTitle': 'حصلت مشكلة في جلب الأجهزة',
    'dash.retry': 'حاول تاني',
    'dash.emptyTitle': 'لسه مفيش أجهزة متسجلة',
    'dash.emptyText': 'أول ما جهاز يشغّل التطبيق في الوضع Online، هيظهر هنا تلقائيًا.',
    'dash.noResultsTitle': 'مفيش نتايج مطابقة',
    'dash.noResultsText': 'جرّب تغيّر البحث أو الفلتر.',
    'dash.row.code': 'كود الجهاز',
    'dash.row.platform': 'المنصة',
    'dash.row.version': 'نسخة التطبيق',
    'dash.row.build': 'build {n}',
    'dash.row.licenseType': 'نوع الترخيص',
    'dash.row.licenseValue': 'قيمة الترخيص',
    'dash.row.issued': 'صدر الترخيص',
    'dash.row.expires': 'ينتهي',
    'dash.row.firstSeen': 'أول تسجيل',
    'dash.row.lastSeen': 'آخر ظهور',
    'dash.row.blockedAt': 'تاريخ الحظر',
    'dash.blockedBanner': 'هذا الجهاز محظور — التطبيق مقفول عليه حاليًا مهما كان الترخيص.',
    'dash.editLicense': 'تعديل الترخيص',
    'dash.value': 'القيمة',
    'dash.saveLicense': 'حفظ الترخيص',
    'dash.revoke': 'إلغاء الترخيص (رجوع للانتظار)',
    'dash.block': 'حظر الجهاز',
    'dash.unblock': 'فك الحظر عن الجهاز',
    'dash.previewUnlimited': '✔ الترخيص هيكون مفتوح مدى الحياة',
    'dash.previewExpires': 'هينتهي في {date}',
    'dash.toast.copied': 'تم نسخ كود الجهاز ✓',
    'dash.toast.copyFailed': 'تعذر النسخ',
    'dash.toast.licenseSaved': 'تم حفظ الترخيص ✓',
    'dash.toast.licenseUnlimited': 'تم تفعيل الترخيص مدى الحياة ✓',
    'dash.toast.blocked': 'تم حظر الجهاز ⛔ — التطبيق هيتقفل عليه',
    'dash.toast.unblocked': 'تم فك الحظر ✓',
    'dash.err.invalidType': 'نوع ترخيص غير صالح: {type}',
    'dash.err.invalidValue': 'قيمة الترخيص لازم تكون رقم صحيح موجب',
    'dash.err.connection': 'حصلت مشكلة في الاتصال — حاول تاني',
    /* ── Dashboard gate (Pages edition) ─────────────────── */
    'dashGate.title': 'دخول اللوحة',
    'dashGate.desc': 'الصفحة دي للإدارة فقط — ادخل بيانات الحساب عشان تكمّل.',
    'dashGate.user': 'اسم المستخدم',
    'dashGate.pass': 'كلمة المرور',
    'dashGate.enter': 'دخول',
    'dashGate.wrong': 'بيانات غير صحيحة — حاول تاني',
    'dashGate.locked': 'محاولات كتير غلط — استنى {mins} دقيقة وجرّب تاني',
    'dashToken.title': 'ربط حساب GitHub',
    'dashToken.desc': 'اللوحة بتقرا وتكتب في الريبو الخاص saytarly_releases. الصق توكن GitHub (Fine-grained) عليه صلاحية Contents: Read and write على الريبو ده — التوكن بيتخزن في متصفحك بس وعمره ما بيتنشر.',
    'dashToken.placeholder': 'github_pat_…',
    'dashToken.login': 'دخول',
    'dashToken.create': 'إنشاء توكن جديد ↗',
    'dashToken.checking': 'بيتحقق…',
    'dashToken.errEmpty': 'اكتب التوكن الأول',
    'dashToken.errInvalid': 'التوكن غير صالح أو منتهي — اتأكد إنك لصقته صح',
    'dashToken.errForbidden': 'التوكن مش عليه صلاحية — لازم Contents: Read and write على saytarly_releases',
    'dashToken.errWrongUser': 'الحساب {login} مش مصرّح له بالدخول للوحة',
    'dashToken.errUnexpected': 'استجابة غير متوقعة من GitHub',
    'dashToken.welcome': 'أهلًا {login} ✓',
    'dashToken.loggedOut': 'تم تسجيل الخروج — التوكن اتمسح من المتصفح',
  };

  var EN = {
    /* ── Site metadata ─────────────────────────────────── */
    'meta.title': 'Saytarly — Restaurant & Café Management System',
    'meta.description':
      'Saytarly — POS, inventory, shifts and reports for your restaurant or café on Windows and Android, working continuously even offline.',

    /* ── Navigation ────────────────────────────────────── */
    'nav.features': 'Features',
    'nav.modes': 'Modes',
    'nav.contact': 'Contact us',
    'nav.menu': 'Menu',
    'nav.langSwitch': 'Change language',

    /* ── Hero ──────────────────────────────────────────── */
    'hero.badge': 'Restaurant & café management system',
    'hero.title': 'Run your restaurant on one system…<br /><em>POS, inventory and reports.</em>',
    'hero.lead':
      'Saytarly brings everything your venue needs into one app: a fast cashier for orders and tables, full menus, staff shifts, inventory under control, and reports that show your profit as it happens — working continuously even without internet.',
    'hero.ctaPrimary': 'Get your copy',
    'hero.ctaSecondary': 'See features',
    'hero.sales': "Today's sales: EGP 12,450<small>Updated live with every order</small>",
    'hero.bestSeller': 'Best seller: Espresso<small>Report updates automatically</small>',
    'hero.shift': 'Open shift — 4 staff<small>Shift sales: EGP 8,900</small>',

    /* ── Stats strip ───────────────────────────────────── */
    'stats.categories': 'Unlimited menu categories — add and customize freely',
    'stats.uptime': 'Continuous operation even offline',
    'stats.custom': 'Fully customizable — logo, name, theme and language',
    'stats.multi': 'Multi',
    'stats.currencies': 'Multiple currencies with full price control',

    /* ── Features ──────────────────────────────────────── */
    'features.kicker': '— ALL APP FEATURES —',
    'features.title': 'Every detail of your day has a ready tool',
    'features.subtitle':
      'From the first order at the table to the last report — everything customizable your way.',

    'features.cat1.title': 'Daily operations',
    'features.cat1.sub': 'Cashier, tables and shifts without the hassle',
    'features.cat1.f1.title': 'Fast POS',
    'features.cat1.f1.desc': 'A cashier built for speed: orders and invoices without complexity, done in seconds.',
    'features.cat1.f2.title': 'Tables & orders',
    'features.cat1.f2.desc': 'Complete table management: open an order, add items, move or merge with no confusion.',
    'features.cat1.f3.title': 'Invoice printing',
    'features.cat1.f3.desc': 'Printable invoices ready for the cashier or orders — one click, no complex setup.',
    'features.cat1.f4.title': 'Staff shifts',
    'features.cat1.f4.desc': 'Every shift recorded: sales, cash and hours — handovers without disputes.',
    'features.cat1.f5.title': 'Accounts & permissions',
    'features.cat1.f5.desc': 'Every staff member has their own account and permissions — no one oversteps their role.',

    'features.cat2.title': 'Unlimited menu — full customization',
    'features.cat2.sub': 'Categories, items and prices all in your hands',
    'features.cat2.f1.title': 'Unlimited categories',
    'features.cat2.f1.desc': 'Not just four categories — add as many as you like: food, drinks, desserts, appetizers and more.',
    'features.cat2.f2.title': 'Items, prices & sizes',
    'features.cat2.f2.desc': 'Every item with its prices, sizes and add-ons — change a price in an instant.',
    'features.cat2.f3.title': 'Multiple currencies',
    'features.cat2.f3.desc': 'Run more than one currency at once, and switch currency and pricing in seconds.',
    'features.cat2.f4.title': 'Custom business profile',
    'features.cat2.f4.desc': 'Your venue name and logo on invoices and in the app — it reflects your identity.',
    'features.cat2.f5.title': 'Theme & language your way',
    'features.cat2.f5.desc': 'Arabic or English, light or dark mode — make the interface comfortable for your staff.',

    'features.cat3.title': 'Inventory & money',
    'features.cat3.sub': 'Know every pound in and out of your venue',
    'features.cat3.f1.title': 'Ingredients inventory',
    'features.cat3.f1.desc': "Track every ingredient in your venue — and know what's running low before it stops your work.",
    'features.cat3.f2.title': 'Suppliers & purchases',
    'features.cat3.f2.desc': 'Record purchases from suppliers — and know who gives you the best price.',
    'features.cat3.f3.title': 'Expenses',
    'features.cat3.f3.desc': 'Log every expense: ingredients, rent, electricity — and the report shows how much you spent.',
    'features.cat3.f4.title': 'Debts & credit',
    'features.cat3.f4.desc': 'Track what customers owe you and what you owe suppliers — no account gets lost.',
    'features.cat3.f5.title': 'Reports & sales',
    'features.cat3.f5.desc': "Today's revenue, top-selling items, performance by shift — all the numbers in front of you.",

    'features.cat4.title': 'Always running',
    'features.cat4.sub': 'A stable system with you in every condition',
    'features.cat4.f1.title': 'Full offline mode',
    'features.cat4.f1.desc': "The system runs 100% on your device — if the internet drops, your work isn't affected for a second.",
    'features.cat4.f2.title': 'Updates from Saytarly Store',
    'features.cat4.f2.desc': 'New features arrive automatically — and you can roll back to an older version if something goes wrong.',
    'features.cat4.f3.title': 'Windows & Android',
    'features.cat4.f3.desc': 'Run it on the cashier computer and your phone — same accounts, same data.',
    'features.cat4.f4.title': 'Backup & restore',
    'features.cat4.f4.desc': 'Your data is secured with a backup — restore it anytime with one click.',
    'features.cat4.f5.title': 'Runs in the background',
    'features.cat4.f5.desc': 'On Windows the app keeps running in the taskbar — close the window and your work continues.',

    /* ── Modes ─────────────────────────────────────────── */
    'modes.kicker': '— TWO APP EDITIONS —',
    'modes.title': 'Choose the mode that suits your venue',
    'modes.subtitle': 'The same app and the same features — you choose what works best for your daily operations.',
    'modes.online.title': 'Online mode',
    'modes.online.sub': 'The full experience',
    'modes.online.item1': 'Always on the latest version — updates arrive automatically from Saytarly Store',
    'modes.online.item2': 'New features added continuously without any effort from you',
    'modes.online.item3': 'If an update causes a problem, roll back to the previous version in one click',
    'modes.online.item4': 'Best for venues with a stable internet connection',
    'modes.offline.title': 'Offline mode',
    'modes.offline.sub': '100% without internet',
    'modes.offline.item1': 'All features run on your device without any internet',
    'modes.offline.item2': 'All your data is stored locally on your device',
    'modes.offline.item3': 'No interruption to your work — even if the internet drops suddenly',
    'modes.offline.item4': 'Ideal for venues with weak or no internet',

    /* ── CTA & contact ─────────────────────────────────── */
    'cta.title': 'Ready to run your restaurant on Saytarly?',
    'cta.subtitle': 'Order your copy today, start with one device — and scale as your business grows.',
    'cta.button': 'Contact us →',
    'contact.title': 'Have a question or want to try it?',
    'contact.subtitle': 'Our team is ready to help with any question about the system or pricing.',

    /* ── Contact page ──────────────────────────────────── */
    'contact.metaTitle': 'Contact us — Saytarly',
    'contact.metaDescription':
      'Get in touch with the Saytarly team — email, WhatsApp, or call 01018089212.',
    'contact.kicker': 'Contact us',
    'contact.heading': 'Talk to us any time — we are here to help',
    'contact.lead':
      'Whether you have a question about the system, need a quote, or want to try Saytarly at your venue — email us, message us on WhatsApp, or call us directly.',
    'contact.email.title': 'Email',
    'contact.email.desc': "Send us your venue details and question — we'll reply as soon as we can.",
    'contact.email.cta': 'Send email',
    'contact.whatsapp.title': 'WhatsApp',
    'contact.whatsapp.desc': 'The fastest way to reach us — send a message and we will get back to you.',
    'contact.whatsapp.cta': 'Chat on WhatsApp',
    'contact.call.title': 'Direct call',
    'contact.call.desc': 'Prefer to talk? Call us directly during working hours.',
    'contact.call.cta': 'Call us',
    'contact.copy': 'Copy',
    'contact.copied': 'Copied ✓',
    'contact.form.title': 'Send us a message',
    'contact.form.desc':
      'Fill in the details and we will prepare the message in your email app — review it and send.',
    'contact.form.name': 'Name',
    'contact.form.namePlaceholder': 'Your name',
    'contact.form.contact': 'Email or phone number',
    'contact.form.contactPlaceholder': 'name@example.com / 01xxxxxxxxx',
    'contact.form.subject': 'Subject',
    'contact.form.subjectPlaceholder': 'Question about Saytarly',
    'contact.form.message': 'Your message',
    'contact.form.messagePlaceholder': 'Tell us the details…',
    'contact.form.send': 'Send email',
    'contact.form.sendWhatsapp': 'Send on WhatsApp',
    'contact.form.defaultSubject': 'Message from the Saytarly contact page',
    'contact.form.bodyName': 'Name',
    'contact.form.bodyContact': 'Contact details',
    'contact.form.note':
      'Hitting “Send email” opens your email app with the message ready for <a href="mailto:saytarly.official@gmail.com">saytarly.official@gmail.com</a> — review it and send.',
    'contact.form.errName': 'Please enter your name.',
    'contact.form.errContact': 'Please add an email or phone number so we can reply.',
    'contact.form.errMessage': 'Please write your message.',
    'contact.form.opened': 'Message prepared — send it from your email app.',
    'contact.form.openedWhatsapp': 'Opening WhatsApp with the message ready…',
    'footer.copy': '© 2026 Saytarly — Restaurant & café management system.',

    /* ── 404 ───────────────────────────────────────────── */
    'notfound.text': "This page doesn't exist — head back home.",
    'notfound.home': 'Home',

    /* ── Login ─────────────────────────────────────────── */
    'auth.pageTitle': 'Devices dashboard login — Saytarly',
    'auth.badge': 'Protected access',
    'auth.title': 'Devices dashboard',
    'auth.subtitle': 'Sign in to access the devices and licenses dashboard.',
    'auth.username': 'Username',
    'auth.usernamePlaceholder': 'Username',
    'auth.password': 'Password',
    'auth.passwordPlaceholder': 'Password',
    'auth.submit': 'Sign in',
    'auth.submitting': 'Signing in…',
    'auth.invalid': 'Incorrect username or password.',
    'auth.rateLimited': 'Too many attempts — please wait a bit and try again.',
    'auth.error': 'Something went wrong. Please try again.',
    'auth.back': 'Back to home',
    'auth.secureNote': 'Access is secured on the server — credentials are not stored in the page.',

    /* ── Dashboard ─────────────────────────────────────── */
    'dash.pageTitle': 'Devices dashboard — Saytarly',
    'dash.navHome': 'Home',
    'dash.live': 'Live — updates every 30 seconds',
    'dash.title': 'Devices & licenses dashboard',
    'dash.lead':
      'Every device running Saytarly registers itself here automatically — view its status, copy its code, and activate or revoke its license.',
    'dash.refresh': 'Refresh now',
    'dash.lastUpdatedLabel': 'Last updated:',
    'dash.logout': 'Sign out',
    'dash.searchPlaceholder': 'Search by device name or code…',
    'dash.filter.all': 'All',
    'dash.filter.active': 'Active',
    'dash.filter.unlimited': 'Lifetime',
    'dash.filter.pending': 'Pending',
    'dash.filter.expired': 'Expired',
    'dash.filter.blocked': 'Blocked',
    'dash.sort.lastSeen': 'Recently seen',
    'dash.sort.name': 'Name (A–Z)',
    'dash.sort.oldest': 'Oldest seen',
    'dash.sort.version': 'Version',
    'dash.modalTitle': 'Device details',
    'dash.close': 'Close',
    'dash.status.active': 'Active',
    'dash.status.unlimited': 'Lifetime',
    'dash.status.pending': 'Pending',
    'dash.status.expired': 'Expired',
    'dash.status.blocked': 'Blocked',
    'dash.type.days': 'Days',
    'dash.type.months': 'Months',
    'dash.type.years': 'Years',
    'dash.type.unlimited': 'Lifetime',
    'dash.unit.days.one': 'day',
    'dash.unit.days.other': 'days',
    'dash.unit.months.one': 'month',
    'dash.unit.months.other': 'months',
    'dash.unit.years.one': 'year',
    'dash.unit.years.other': 'years',
    'dash.countdownBlocked': 'Blocked ⛔',
    'dash.countdownUnlimited': '∞ Lifetime',
    'dash.expiresIn': 'Ends {when}',
    'dash.expiredAgo': 'Expired {when}',
    'dash.now': 'just now',
    'dash.stat.total': 'Total devices',
    'dash.stat.active': 'Active',
    'dash.stat.unlimited': 'Lifetime',
    'dash.stat.pending': 'Pending',
    'dash.stat.expired': 'Expired',
    'dash.stat.blocked': 'Blocked',
    'dash.device': 'Device',
    'dash.platform.windows': 'Windows',
    'dash.platform.android': 'Android',
    'dash.copyCode': 'Copy code',
    'dash.license': 'License',
    'dash.validity': 'Validity',
    'dash.seen': 'Last seen {when}',
    'dash.registered': 'Registered {when}',
    'dash.loadErrorTitle': "Couldn't load devices",
    'dash.retry': 'Try again',
    'dash.emptyTitle': 'No devices registered yet',
    'dash.emptyText': 'As soon as a device runs the app in Online mode, it will appear here automatically.',
    'dash.noResultsTitle': 'No matching results',
    'dash.noResultsText': 'Try changing your search or filter.',
    'dash.row.code': 'Device code',
    'dash.row.platform': 'Platform',
    'dash.row.version': 'App version',
    'dash.row.build': 'build {n}',
    'dash.row.licenseType': 'License type',
    'dash.row.licenseValue': 'License value',
    'dash.row.issued': 'License issued',
    'dash.row.expires': 'Expires',
    'dash.row.firstSeen': 'First seen',
    'dash.row.lastSeen': 'Last seen',
    'dash.row.blockedAt': 'Blocked at',
    'dash.blockedBanner': 'This device is blocked — the app is locked on it regardless of its license.',
    'dash.editLicense': 'Edit license',
    'dash.value': 'Value',
    'dash.saveLicense': 'Save license',
    'dash.revoke': 'Revoke license (back to pending)',
    'dash.block': 'Block device',
    'dash.unblock': 'Unblock device',
    'dash.previewUnlimited': '✔ The license will be unlimited',
    'dash.previewExpires': 'Expires on {date}',
    'dash.toast.copied': 'Device code copied ✓',
    'dash.toast.copyFailed': "Couldn't copy",
    'dash.toast.licenseSaved': 'License saved ✓',
    'dash.toast.licenseUnlimited': 'Lifetime license activated ✓',
    'dash.toast.blocked': 'Device blocked ⛔ — the app is locked on it',
    'dash.toast.unblocked': 'Device unblocked ✓',
    'dash.err.invalidType': 'Invalid license type: {type}',
    'dash.err.invalidValue': 'License value must be a positive integer',
    'dash.err.connection': 'Connection failed — please try again',
    /* ── Dashboard gate (Pages edition) ─────────────────── */
    'dashGate.title': 'Dashboard sign-in',
    'dashGate.desc': 'This page is for administration only — enter your credentials to continue.',
    'dashGate.user': 'Username',
    'dashGate.pass': 'Password',
    'dashGate.enter': 'Sign in',
    'dashGate.wrong': 'Invalid credentials — try again',
    'dashGate.locked': 'Too many failed attempts — wait {mins} minutes and try again',
    'dashToken.title': 'Link your GitHub account',
    'dashToken.desc': 'The dashboard reads and writes to the private saytarly_releases repo. Paste a GitHub fine-grained token with Contents: Read and write permission on that repo — the token is stored in your browser only and is never published.',
    'dashToken.placeholder': 'github_pat_…',
    'dashToken.login': 'Sign in',
    'dashToken.create': 'Create a new token ↗',
    'dashToken.checking': 'Verifying…',
    'dashToken.errEmpty': 'Enter the token first',
    'dashToken.errInvalid': 'Token is invalid or expired — make sure you pasted it correctly',
    'dashToken.errForbidden': "Token lacks permission — it needs Contents: Read and write on saytarly_releases",
    'dashToken.errWrongUser': 'Account {login} is not allowed to open the dashboard',
    'dashToken.errUnexpected': 'Unexpected response from GitHub',
    'dashToken.welcome': 'Welcome {login} ✓',
    'dashToken.loggedOut': 'Signed out — the token was removed from the browser',
  };

  var DICT = { ar: AR, en: EN };

  function readLang() {
    try {
      var saved = localStorage.getItem(STORAGE_KEY);
      if (saved === 'ar' || saved === 'en') return saved;
    } catch (e) { /* ignore */ }
    return document.documentElement.lang === 'en' ? 'en' : 'ar';
  }

  var lang = readLang();

  function t(key, vars) {
    var table = DICT[lang] || AR;
    var value = table[key];
    if (value === undefined) value = AR[key];
    if (value === undefined) return key;
    if (vars) {
      Object.keys(vars).forEach(function (name) {
        value = value.split('{' + name + '}').join(String(vars[name]));
      });
    }
    return value;
  }

  function apply(root) {
    root = root || document;

    document.documentElement.lang = lang;
    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';

    Array.prototype.forEach.call(root.querySelectorAll('[data-i18n]'), function (el) {
      el.textContent = t(el.getAttribute('data-i18n'));
    });
    Array.prototype.forEach.call(root.querySelectorAll('[data-i18n-html]'), function (el) {
      el.innerHTML = t(el.getAttribute('data-i18n-html'));
    });
    Array.prototype.forEach.call(root.querySelectorAll('[data-i18n-placeholder]'), function (el) {
      el.setAttribute('placeholder', t(el.getAttribute('data-i18n-placeholder')));
    });
    Array.prototype.forEach.call(root.querySelectorAll('[data-i18n-aria-label]'), function (el) {
      el.setAttribute('aria-label', t(el.getAttribute('data-i18n-aria-label')));
    });
    Array.prototype.forEach.call(root.querySelectorAll('[data-i18n-title]'), function (el) {
      el.setAttribute('title', t(el.getAttribute('data-i18n-title')));
    });
    Array.prototype.forEach.call(root.querySelectorAll('[data-i18n-content]'), function (el) {
      el.setAttribute('content', t(el.getAttribute('data-i18n-content')));
    });

    Array.prototype.forEach.call(document.querySelectorAll('[data-lang-switch]'), function (btn) {
      var label = btn.querySelector('[data-lang-label]');
      if (label) label.textContent = lang === 'ar' ? 'EN' : 'عربي';
      btn.setAttribute('aria-label', t('nav.langSwitch'));
      btn.setAttribute('title', t('nav.langSwitch'));
    });

    document.dispatchEvent(new CustomEvent('saytarly:langchange', { detail: { lang: lang } }));
  }

  function setLang(next) {
    if (next !== 'ar' && next !== 'en') return;
    lang = next;
    try { localStorage.setItem(STORAGE_KEY, lang); } catch (e) { /* ignore */ }
    apply();
  }

  document.addEventListener('click', function (event) {
    var btn = event.target.closest ? event.target.closest('[data-lang-switch]') : null;
    if (!btn) return;
    setLang(lang === 'ar' ? 'en' : 'ar');
  });

  window.SaytarlyI18n = {
    t: t,
    getLang: function () { return lang; },
    setLang: setLang,
    apply: apply,
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { apply(); });
  } else {
    apply();
  }
})();
