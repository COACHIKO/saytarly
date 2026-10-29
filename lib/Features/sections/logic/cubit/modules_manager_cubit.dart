import 'package:bloc/bloc.dart';

import 'package:saytarly/Features/sections/data/repositories/sections_repository.dart';

/// حالة شاشة إدارة أقسام المنتجات.
class ModulesManagerState {
  final bool loading;
  final List<SectionModuleRow> rows;

  const ModulesManagerState({
    required this.loading,
    required this.rows,
  });

  ModulesManagerState copyWith({
    bool? loading,
    List<SectionModuleRow>? rows,
  }) {
    return ModulesManagerState(
      loading: loading ?? this.loading,
      rows: rows ?? this.rows,
    );
  }
}

/// Cubit شاشة إدارة الأقسام — كل منطق الأقسام هنا، والشاشة عرض بس.
class ModulesManagerCubit extends Cubit<ModulesManagerState> {
  ModulesManagerCubit({SectionsRepository? repository})
      : _repository = repository ?? SectionsRepository(),
        super(const ModulesManagerState(loading: true, rows: []));

  final SectionsRepository _repository;

  /// تحميل / إعادة تحميل الأقسام.
  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final rows = await _repository.fetchModuleRows();
    if (isClosed) return;
    emit(state.copyWith(loading: false, rows: rows));
  }

  /// إضافة قسم جديد.
  Future<void> addModule({
    required String name,
    required String icon,
    required int color,
  }) async {
    await _repository.addModule(name: name, icon: icon, color: color);
    await load();
  }

  /// تعديل بيانات قسم موجود.
  Future<void> editModule({
    required int id,
    required String name,
    required String icon,
    required int color,
  }) async {
    await _repository.updateModule(
      id: id,
      name: name,
      icon: icon,
      color: color,
    );
    await load();
  }

  /// تشغيل / تعطيل قسم.
  Future<void> toggleModule(SectionModuleRow row, bool value) async {
    await _repository.updateModule(id: row.module.id!, isEnabled: value);
    await load();
  }

  /// هل ينفع نحذف القسم؟ (ممنوع طول ما فيه منتجات جواه)
  bool canDelete(SectionModuleRow row) => row.drinks == 0;

  /// حذف قسم.
  Future<void> deleteModule(SectionModuleRow row) async {
    await _repository.deleteModule(row.module.id!);
    await load();
  }

  /// تحريك قسم لفوق (delta = -1) أو لتحت (delta = 1).
  Future<void> move(int index, int delta) async {
    final rows = state.rows;
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= rows.length) return;

    final list = [...rows];
    final tmp = list[index];
    list[index] = list[newIndex];
    list[newIndex] = tmp;

    await _repository.reorderModules(list.map((r) => r.module.id!).toList());
    await load();
  }
}
