# Saytarly Website

موقع ويب يوصف **Saytarly** — نظام إدارة المطاعم والكافيهات — مع لوحة أجهزة
وإدارة تراخيص محمية تعمل من خلال سيرفر Node.

A bilingual (Arabic / English) marketing site for **Saytarly**, plus a
server-protected devices & licenses dashboard.

## اللغة / Localization

- الواجهة عربي/إنجليزي مع زرار تبديل اللغة في القائمة.
- الاختيار بيتحفظ في `localStorage`، ويمكن فرضه من الرابط `?lang=ar` أو `?lang=en`.
- كل النصوص في `public/js/i18n.js` (قاموس `ar` / `en`) وبتتطبق عبر خصائص
  `data-i18n` — عشان إضافة لغة جديدة يبقى سهل.

## الصفحة الرئيسية

الموقع التسويقي (`public/`) ثابت وممكن يتنشر على GitHub Pages:

- `/` → الصفحة الرئيسية (المميزات، أوضاع التشغيل، التراخيص)
- `404.html` → صفحة الخطأ
- لوحة الأجهزة **مش جزء من الموقع العام** ومفيش أي لينك ليها في الصفحة
  الرئيسية أو في قائمة التنقل.

## لوحة الأجهزة (محمية بكلمة مرور)

اللوحة بتتقدم من السيرفر فقط على `/dashboard`:

1. افتح `http://localhost:4600/dashboard`.
2. هتظهر صفحة دخول. البيانات الافتراضية موجودة في `server.js` (اسم المستخدم
   الافتراضي `admin`، وكلمة المرور هي القيمة الـ hardcoded هناك).
3. بعد الدخول، السيرفر بيحط كوكي جلسة `HttpOnly` موقّع بـ HMAC، وبيقدّم
   صفحة اللوحة. البيانات (اسم المستخدم/كلمة المرور) موجودة في `server.js`
   فقط — **عمرها ما بتتبعت للـ HTML أو الـ JavaScript أو المتصفح**.
4. الجلسة صالحة 8 ساعات، و«تسجيل الخروج» بيمسحها.
5. محاولات الدخول محدودة (8 محاولات / 10 دقائق لكل IP).

يمكن تغيير البيانات من متغيرات البيئة على السيرفر:

```bash
ADMIN_USERNAME=admin
ADMIN_PASSWORD=...
SESSION_SECRET=...
```

> **مهم:** نشر GitHub Pages بياخد مجلد `public` فقط، يعني اللوحة وصفحة
> الدخول مش هتتنشر على Pages. لو محتاج اللوحة، شغّل سيرفر Node (تحت) أو
> انشر المشروع على استضافة Node.

## التشغيل محليًا

```bash
npm install
# انسخ .env.example إلى .env وحط التوكن بتاع الريبو (Contents: Read+write)
npm start
```

يفتح على `http://localhost:4600` (غيّر `PORT` في `.env` لو محتاج).

## النشر (Deployment)

### الموقع التسويقي → GitHub Pages

- Workflow `.github/workflows/pages.yml` بيرفع مجلد `public/` **فقط** على
  `https://coachiko.github.io/saytarly/` — يعني صفحة الدخول واللوحة
  (`admin/` و `views/`) عمرها ما بتتنشر.
- خطوة حماية (guard) في الـ workflow بتوقف النشر فورًا لو حد رجّع
  `dashboard.html` أو `admin/` أو `views/` جوّه `public/`.

### السيرفر + اللوحة → Render

`render.yaml` (Blueprint) في التريّة بيوصف السيرفر كامل، وأي push لـ
`main` بيعمل deploy تلقائي:

1. افتح [dashboard.render.com] → **New → Blueprint** → اختار ريبو
   `COACHIKO/saytarly`.
2. وقت تطبيق الـ Blueprint هيسألك على `RELEASES_TOKEN` — حط التوكن
   بتاع `COACHIKO/saytarly_releases` (نفس القيمة اللي في `.env` المحلي).
   التوكن عمره ما بيتكتب في أي ملف في التريّة.
3. `SESSION_SECRET` بيتولّد لوحده، و`TRUST_PROXY=1` مثبت جاهز عشان
   كوكي الجلسة يطلع `Secure` خلف HTTPS بروكسي بتاع Render.
4. الدومين: من إعدادات الخدمة → **Custom Domains** → ضيف
   `dash.saytarly.com`، وبعدها في الـ DNS بتاع saytarly.com ضيف سجل
   `dash` → CNAME → القيمة اللي Render هتقولك عليها (شكلها
   `saytarly-dashboard.onrender.com`). الشهادة بتتعمل تلقائيًا.
5. الخطة الافتراضية `free` بتطفي بعد 15 دقيقة من غير استخدام
   (≈30 ثانية لما تصحي). لو عايز اللوحة ترد فورًا 24/7، ارفع الخطة
   لـ `starter` من الـ dashboard.

بعدها اللوحة بتفتح من `https://dash.saytarly.com/dashboard` — بدون أي
لينك ليها من الموقع العام.

## المسارات (نسخة السيرفر)

| المسار                              | الوصف |
| ----------------------------------- | ----- |
| `/`                                 | الصفحة الرئيسية (عربي/إنجليزي) |
| `/dashboard`                        | صفحة دخول، أو لوحة الأجهزة بعد تسجيل الدخول |
| `/dashboard.html`                   | تحويل لـ `/dashboard` |
| `/saytarly/dashboard`               | تحويل لـ `/dashboard` |
| `POST /api/auth/login`              | تسجيل الدخول (`{ username, password }`) |
| `POST /api/auth/logout`             | تسجيل الخروج ومسح الجلسة |
| `GET /api/auth/session`             | حالة الجلسة |
| `/api/devices`                      | JSON لكل الأجهزة + الحالة المحسوبة (محمي) |
| `POST /api/devices/:code/license`   | تفعيل/تعديل/إلغاء ترخيص جهاز (محمي) |
| `POST /api/devices/:code/block`     | حظر جهاز / فك الحظر (محمي) |
| `/api/health`                       | حالة السيرفر والريبو |

## المميزات

- **لوحة الأجهزة**: بحث + فلترة بالحالة + ترتيب + تحديث تلقائي كل 30 ثانية.
- **تراخيص**: تفعيل (أيام/شهور/سنين/مدى الحياة)، معاينة تاريخ الانتهاء، إلغاء.
- **حظر/فك حظر** أي جهاز فورًا.
- **نسخ كود الجهاز** بضغطة واحدة.
- **عربي/إنجليزي** مع اتجاه RTL/LTR تلقائي.
- تصميم متجاوب كامل (موبايل/تابلت/ديسكتوب) بهوية Saytarly
  (نافي غامق + أزرق كهربائي).

## ملاحظات أمان

- بيانات لوحة الأجهزة hardcoded في `server.js` (أو environment variables)
  وعمرها ما بتظهر في HTML أو JS المتصفح.
- صفحة اللوحة والسكريبت بتاعها مش موجودين في `public/`، فمش بيتنشروا مع
  GitHub Pages.
- كل مسارات `/api/devices` محمية بجلسة موقعة، والتوكن بتاع GitHub بيتقرا
  من بيئة السيرفر بس — عمره ما بيوصل للمتصفح.
- كوكي الجلسة `HttpOnly` + `SameSite=Strict` (و`Secure` على HTTPS).
- ملف `.env` مستبعد من git (`.gitignore`).
