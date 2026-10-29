import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/services/business_profile.dart';
import 'package:saytarly/core/localization/messages.dart';

/// نتيجة تجهيز شيفت الموظف وقت تسجيل الدخول.
class StaffShiftResolution {
  /// رقم الشيفت المفتوح (القديم بتاع الموظف أو الجديد) — null لو فيه مشكلة.
  final int? shiftId;

  /// رسالة الخطأ اللي تتعرض للموظف — null لو كل حاجة تمام.
  final String? error;

  const StaffShiftResolution.ok(int this.shiftId) : error = null;

  const StaffShiftResolution.failure(String this.error) : shiftId = null;

  bool get isOk => shiftId != null;
}

/// مستودع بيانات تسجيل الدخول — كل التعامل مع قاعدة البيانات هنا،
/// والـ ViewModel هو اللي بيستخدمه (الشاشة ما تعرفش حاجة عن DBHelper).
class AuthRepository {
  /// بيجيب بيانات المستخدم بـ اسم المستخدم وكلمة المرور، أو null لو مش موجود.
  Future<Map<String, dynamic>?> findUser(String username, String password) =>
      DBHelper.getUser(username, password);

  /// اسم المحل اللي بيظهر في شاشة الدخول.
  Future<String> getPlaceName() => BusinessProfile.getPlaceName();

  /// بتتأكد إن الموظف ليه شيفت مفتوح (وبترجعه)، أو بتفتح له شيفت جديد.
  ///
  /// الحالات:
  /// - في شيفت مفتوح لنفس الموظف  → بنرجع رقمه.
  /// - في شيفت مفتوح لمستخدم تاني → بنرجع رسالة خطأ.
  /// - مفيش شيفتات مفتوحة         → بنفتح شيفت جديد وبنرجع رقمه.
  Future<StaffShiftResolution> resolveStaffShift(int userId) async {
    final db = await DBHelper.database;

    final openShifts = await db.query('shifts', where: 'check_out IS NULL');

    Map<String, Object?>? userShift;
    for (final shift in openShifts) {
      if (shift['user_id'] == userId) {
        userShift = shift;
        break;
      }
    }

    if (userShift != null) {
      final id = userShift['id'];
      if (id == null) {
        return  StaffShiftResolution.failure(
          'خطأ: بيانات الشيفت غير صحيحة'.tr(),
        );
      }
      return StaffShiftResolution.ok(id as int);
    }

    if (openShifts.isNotEmpty) {
      return  StaffShiftResolution.failure(
        'يوجد شيفت مفتوح لمستخدم آخر، لا يمكن فتح شيفت جديد'.tr(),
      );
    }

    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final shiftId = await DBHelper.checkIn(
      userId,
      date,
      now.toIso8601String(),
    );

    if (shiftId == 0) {
      return  StaffShiftResolution.failure('حدث خطأ أثناء فتح الشيفت'.tr());
    }

    return StaffShiftResolution.ok(shiftId);
  }
}
