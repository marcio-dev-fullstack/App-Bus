/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:get_it/get_it.dart';

import 'api/directions_service.dart';
import 'api/places_service.dart';
import 'api/auth_service.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'core/services/secure_storage_service.dart';
import 'core/database/database_service.dart';
import 'features/trip/repositories/trip_repository_local.dart';
import 'features/student/repositories/student_repository_local.dart';
import 'api/sync_service.dart';
import 'features/sync/controllers/sync_controller.dart';
import 'core/services/face_recognition_service.dart';

// Esta é a instância global do nosso Localizador de Serviços.
final GetIt locator = GetIt.instance;

/// Registra as dependências (serviços e controllers) para que possam ser
/// acessadas de qualquer lugar do aplicativo.
void setupLocator() {
  // Serviços: Registrados como "Lazy Singletons".
  // Eles só serão criados na primeira vez que forem solicitados.
  locator.registerLazySingleton(() => PlacesService());
  locator.registerLazySingleton(() => DirectionsService());
  locator.registerLazySingleton(() => AuthService());
  locator.registerLazySingleton(() => SecureStorageService());
  locator.registerLazySingleton(() => DatabaseService());
  locator.registerLazySingleton(() => TripRepositoryLocal());
  locator.registerLazySingleton(() => StudentRepositoryLocal());
  locator.registerLazySingleton(() => SyncApiService());
  locator.registerLazySingleton(() => FaceRecognitionService());

  // Controller de Autenticação: Registrado como "LazySingleton".
  // Queremos uma única instância para gerenciar o estado de login em todo o app.
  locator.registerLazySingleton(() => AuthController());

  // Outros Controllers: Registrados como "Factory".
  // Uma nova instância será criada toda vez que for solicitada.
  locator.registerFactory(() => SyncController());
}
