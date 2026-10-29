// lib/utils/master_devices.dart
//
// نفس القايمة اللي كانت جوه main.dart، نقلناها هنا عشان نستخدمها
// في أكتر من مكان (main.dart + device_approval_screen.dart) من غير تكرار.

const List<String> kMasterDevices = [
  // أجهزة Windows المسموح بها (لازم تكون الهاش الحقيقي، مش اسم الجهاز)
  'E45557BE5400E983C7F54F74253501A3F903F7DECD0F9EDAFBE8B882102D391E',
  'desktop-m1nmmuv',
  // ⚠️ لسه لازم تستبدله بهاشه الحقيقي
  // الموبايل المسموح له بالدخول على شاشة الموافقة على الأجهزة
  'C71CBDFFD42A1221C8003A140E4304D48ABC7B1B21CB1786B81B545D35093DA0',
];

// 🆕 الجهاز الوحيد اللي يشوف شاشة "لوحة اعتماد الأجهزة" (الموبايل بتاعك بس)
// أجهزة الويندوز الموجودة في kMasterDevices بتتخطى الفحص عادي بس من غير الشاشة دي
const String kApprovalPanelDevice =
    'C71CBDFFD42A1221C8003A140E4304D48ABC7B1B21CB1786B81B545D35093DA0';
