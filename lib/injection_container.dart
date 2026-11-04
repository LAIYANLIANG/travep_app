import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'features/authentication/data/repositories/auth_repository_impl.dart';
import 'features/authentication/domain/repositories/auth_repository.dart';
import 'features/wishlist/data/repositories/wishlist_repository_impl.dart';
import 'features/wishlist/domain/repositories/wishlist_repository.dart';
import 'features/smart_planning/data/datasources/places_service.dart';
import 'features/smart_planning/domain/services/gemini_service.dart';
import 'features/upload/domain/services/spot_registry_service.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPrefs);

  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => GoogleSignIn());

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl(), sl()),
  );
  
  // Feature: Wishlist
  sl.registerLazySingleton<WishlistRepository>(
    () => WishlistRepositoryImpl(sl()),
  );

  // Services
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => PlacesService(sl()));
  sl.registerLazySingleton(() => GeminiService());
  sl.registerLazySingleton(() => SpotRegistryService(sl(), sl()));
}