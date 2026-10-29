import 'package:bloc/bloc.dart';

/// بث إشارة "اتحدّثت بيانات الموظف الفرعي" بين الشاشات.
///
/// - شاشة لوحة الموظف [staff_dashboard] بتنادي [markUpdated] بعد أي تعديل.
/// - صفحة الموظف الفرعي [SubStaffPage] بتسمع بالإشارة وبتعيد تحميل البيانات.
class SubStaffUpdateCubit extends Cubit<int> {
  SubStaffUpdateCubit() : super(0);

  int _counter = 0;

  /// إشارة واحدة لكل تعديل — عشان الشاشة اللي بتسمع تفضل تعيد التحميل.
  void markUpdated() => emit(++_counter);
}

/// المثيل الوحيد المستخدم في كل التطبيق.
final subStaffUpdateCubit = SubStaffUpdateCubit();
