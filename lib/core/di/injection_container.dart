import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:sakani/features/apartments/data/datasources/apartment_remote_data_source.dart';
import 'package:sakani/features/apartments/data/repositories/apartment_repository_impl.dart';
import 'package:sakani/features/apartments/domain/repositories/apartment_repository.dart';
import 'package:sakani/features/apartments/domain/usecases/add_apartment_usecase.dart';
import 'package:sakani/features/apartments/domain/usecases/delete_apartment_usecase.dart';
import 'package:sakani/features/apartments/domain/usecases/get_apartments_usecase.dart';
import 'package:sakani/features/apartments/domain/usecases/get_owner_apartments_usecase.dart';
import 'package:sakani/features/apartments/domain/usecases/update_apartment_usecase.dart';
import 'package:sakani/features/apartments/presentation/cubit/apartment_cubit.dart';
import 'package:sakani/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:sakani/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:sakani/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sakani/features/auth/domain/repositories/auth_repository.dart';
import 'package:sakani/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:sakani/features/auth/domain/usecases/login_usecase.dart';
import 'package:sakani/features/auth/domain/usecases/logout_usecase.dart';
import 'package:sakani/features/auth/domain/usecases/register_usecase.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakani/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:sakani/features/bookings/data/repositories/booking_repository_impl.dart';
import 'package:sakani/features/bookings/domain/repositories/booking_repository.dart';
import 'package:sakani/features/bookings/domain/usecases/create_booking_usecase.dart';
import 'package:sakani/features/bookings/domain/usecases/get_owner_bookings_usecase.dart';
import 'package:sakani/features/bookings/domain/usecases/get_tenant_bookings_usecase.dart';
import 'package:sakani/features/bookings/domain/usecases/update_booking_status_usecase.dart';
import 'package:sakani/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:sakani/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:sakani/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:sakani/features/chat/domain/repositories/chat_repository.dart';
import 'package:sakani/features/chat/domain/usecases/create_room_usecase.dart';
import 'package:sakani/features/chat/domain/usecases/get_chat_rooms_usecase.dart';
import 'package:sakani/features/chat/domain/usecases/get_messages_usecase.dart';
import 'package:sakani/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:sakani/features/chat/presentation/cubit/chat_cubit.dart';

final sl = GetIt.instance;

/// Initializes all dependencies across the application (Core, Features, Blocs).
Future<void> initDependencies() async {
  // ─── External / Network ───
  sl.registerLazySingleton<http.Client>(() => http.Client());

  // ─── Auth Feature ───
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerFactory(
    () => AuthCubit(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
      authRepository: sl(),
    ),
  );

  // ─── Apartments Feature ───
  sl.registerLazySingleton<ApartmentRemoteDataSource>(
    () => ApartmentRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<ApartmentRepository>(
    () => ApartmentRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetApartmentsUseCase(sl()));
  sl.registerLazySingleton(() => GetOwnerApartmentsUseCase(sl()));
  sl.registerLazySingleton(() => AddApartmentUseCase(sl()));
  sl.registerLazySingleton(() => UpdateApartmentUseCase(sl()));
  sl.registerLazySingleton(() => DeleteApartmentUseCase(sl()));
  sl.registerFactory(
    () => ApartmentCubit(
      getApartmentsUseCase: sl(),
      getOwnerApartmentsUseCase: sl(),
      addApartmentUseCase: sl(),
      updateApartmentUseCase: sl(),
      deleteApartmentUseCase: sl(),
      apartmentRepository: sl(),
    ),
  );

  // ─── Bookings Feature ───
  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetTenantBookingsUseCase(sl()));
  sl.registerLazySingleton(() => GetOwnerBookingsUseCase(sl()));
  sl.registerLazySingleton(() => CreateBookingUseCase(sl()));
  sl.registerLazySingleton(() => UpdateBookingStatusUseCase(sl()));
  sl.registerFactory(
    () => BookingCubit(
      getTenantBookingsUseCase: sl(),
      getOwnerBookingsUseCase: sl(),
      createBookingUseCase: sl(),
      updateBookingStatusUseCase: sl(),
      bookingRepository: sl(),
    ),
  );

  // ─── Chat Feature ───
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetChatRoomsUseCase(sl()));
  sl.registerLazySingleton(() => GetMessagesUseCase(sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));
  sl.registerLazySingleton(() => CreateRoomUseCase(sl()));
  sl.registerFactory(
    () => ChatCubit(
      getChatRoomsUseCase: sl(),
      getMessagesUseCase: sl(),
      sendMessageUseCase: sl(),
      createRoomUseCase: sl(),
      chatRepository: sl(),
    ),
  );
}
