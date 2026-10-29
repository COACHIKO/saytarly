import 'package:get_it/get_it.dart';

import '../networking/api_service.dart';
import '../networking/dio_factory.dart';
import '../services/shared_pref/shared_pref.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// Register app-wide singletons.
///
/// Feature apps add their own registrations in the [registerFeatures]
/// callback passed by the app bootstrap (see `main.dart`).
Future<void> setupInjector({void Function()? registerFeatures}) async {
  final dio = DioFactory.getDio();

  sl.registerLazySingleton<ApiService>(() => ApiService(dio));
  sl.registerSingleton<SharedPref>(SharedPref());

  registerFeatures?.call();
}
