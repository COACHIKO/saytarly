import 'package:bloc/bloc.dart';

import 'package:saytarly/core/services/business_profile.dart';
import 'package:saytarly/Features/auth/data/repositories/auth_repository.dart';
import 'package:saytarly/Features/auth/viewmodel/current_user.dart';
import 'package:saytarly/core/localization/messages.dart';

/// نتيجة تسجيل دخول ناجح — الشاشة بتستخدمها عشان تعرف توجّه المستخدم فين.
class LoginOutcome {
  /// staff / superadmin / admin
  final String role;

  final String username;
  final int userId;

  /// رقم الشيفت — للستاف بس.
  final int? shiftId;

  const LoginOutcome({
    required this.role,
    required this.username,
    required this.userId,
    this.shiftId,
  });
}

/// حالة شاشة تسجيل الدخول.
class LoginState {
  final bool loading;
  final String? error;
  final String placeName;

  const LoginState({
    required this.loading,
    required this.placeName,
    this.error,
  });

  LoginState copyWith({
    bool? loading,
    String? error,
    String? placeName,
  }) {
    return LoginState(
      loading: loading ?? this.loading,
      error: error ?? this.error,
      placeName: placeName ?? this.placeName,
    );
  }
}

/// Cubit شاشة تسجيل الدخول — كل المنطق هنا، والشاشة عرض بس.
class LoginCubit extends Cubit<LoginState> {
  LoginCubit({AuthRepository? repository})
      : _repository = repository ?? AuthRepository(),
        super(const LoginState(
          loading: false,
          placeName: BusinessProfile.fallbackName,
        ));

  final AuthRepository _repository;

  /// بتجيب اسم المحل اللي بيظهر فوق في الشاشة.
  Future<void> loadPlaceName() async {
    final name = await _repository.getPlaceName();
    if (isClosed) return;
    emit(state.copyWith(placeName: name));
  }

  /// بتحاول تسجل الدخول.
  ///
  /// - نجحت: بترجّع [LoginOutcome] (وبتحفظ المستخدم الحالي في [CurrentUser]).
  /// - فشلت: بترجّع null وبتحدّث رسالة الخطأ في الحالة.
  Future<LoginOutcome?> login({
    required String username,
    required String password,
  }) async {
    if (state.loading) return null; // منع الضغط المتكرر أثناء التحميل

    emit(state.copyWith(loading: true, error: null));

    final user = await _repository.findUser(username.trim(), password.trim());

    if (user == null) {
      emit(state.copyWith(loading: false,
          error: 'خطأ في اسم المستخدم أو كلمة المرور'.tr()));
      return null;
    }

    final role = user['role'] as String;
    final userId = user['id'] as int;
    final userName = user['username'] as String;

    // موظف الطلبات (الويتر) مالوش محطة — المشيات بتتدار من محطة الكاشير والموظف
    // الفرعي بيتعين له من إدارة المستخدمين، والكاشير بتاع مدير الصالة
    // هو اللي بيبدأ لهم الشغل من شاشة «شيفتات الموظفين».
    if (role == 'waiter') {
      emit(state.copyWith(
        loading: false,
        error: ('حساب موظف الطلبات (ويتر) ملوش شغل على المحطة — الكاشير هو اللي '.tr() + 'بيبدأ لهم الشيفت من شاشة «شيفتات الموظفين».'.tr()),
      ));
      return null;
    }

    // خزّن بيانات المستخدم الحالي للاستخدام في باقي الشاشات
    CurrentUser.setUser(username: userName, role: role, userId: userId);

    if (role == 'cashier' || role == 'staff') {
      final shift = await _repository.resolveStaffShift(userId);
      emit(state.copyWith(loading: false, error: shift.isOk ? null : shift.error));
      if (!shift.isOk) return null;
      return LoginOutcome(
        role: role,
        username: userName,
        userId: userId,
        shiftId: shift.shiftId,
      );
    }

    emit(state.copyWith(loading: false));
    return LoginOutcome(role: role, username: userName, userId: userId);
  }
}
