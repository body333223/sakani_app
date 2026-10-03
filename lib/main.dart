import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sakani/core/localization/app_localizations.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/features/apartments/data/models/apartment_model.dart';
import 'package:sakani/features/chat/data/models/chat_message.dart';
import 'package:sakani/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakani/features/apartments/presentation/providers/apartment_provider.dart';
import 'package:sakani/features/bookings/presentation/providers/booking_provider.dart';
import 'package:sakani/features/chat/presentation/providers/chat_provider.dart';
import 'package:sakani/features/settings/presentation/providers/locale_provider.dart';
import 'package:sakani/features/settings/presentation/providers/theme_provider.dart';
import 'package:sakani/features/auth/presentation/screens/login_screen.dart';
import 'package:sakani/features/auth/presentation/screens/register_screen.dart';
import 'package:sakani/features/apartments/presentation/screens/home_screen.dart';
import 'package:sakani/features/apartments/presentation/screens/apartment_detail_screen.dart';
import 'package:sakani/features/bookings/presentation/screens/booking_screen.dart';
import 'package:sakani/features/bookings/presentation/screens/my_bookings_screen.dart';
import 'package:sakani/features/apartments/presentation/screens/dashboard_screen.dart';
import 'package:sakani/features/apartments/presentation/screens/add_apartment_screen.dart';
import 'package:sakani/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:sakani/features/chat/presentation/screens/chat_screen.dart';
import 'package:sakani/features/auth/presentation/screens/kyc_screen.dart';
import 'package:sakani/core/utils/page_transitions.dart';
import 'package:sakani/features/settings/presentation/screens/user_profile_screen.dart';
import 'package:sakani/features/apartments/presentation/screens/apartments_map_screen.dart';
import 'package:sakani/features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'package:sakani/features/contracts/presentation/screens/contract_screen.dart';
import 'package:sakani/features/contracts/domain/models/contract_model.dart';
import 'package:sakani/features/contracts/presentation/screens/digital_contract_screen.dart';
import 'package:sakani/features/ai_assistant/presentation/screens/ai_copilot_screen.dart';
import 'package:sakani/features/concierge/presentation/screens/concierge_screen.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakani/core/di/injection_container.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_state.dart';
import 'package:sakani/features/splash/presentation/screens/splash_screen.dart';
import 'package:sakani/features/apartments/presentation/cubit/apartment_cubit.dart';
import 'package:sakani/features/apartments/presentation/cubit/wishlist_cubit.dart';
import 'package:sakani/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:sakani/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:sakani/features/auth/data/services/auth_service.dart';
import 'package:sakani/core/security/secure_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecureStorageService.init();
  await initDependencies();
  AuthService.initializeSession();
  runApp(const SakaniApp());
}

class SakaniApp extends StatelessWidget {
  const SakaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => sl<AuthCubit>()),
        BlocProvider<ApartmentCubit>(create: (_) => sl<ApartmentCubit>()),
        BlocProvider<BookingCubit>(create: (_) => sl<BookingCubit>()),
        BlocProvider<ChatCubit>(create: (_) => sl<ChatCubit>()),
        BlocProvider<WishlistCubit>(create: (_) => WishlistCubit()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ApartmentProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, locale, theme, _) {
          return MaterialApp(
            title: 'Sakani',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: theme.mode,
            locale: locale.locale,
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              if (locale != null) {
                for (final supported in supportedLocales) {
                  if (supported.languageCode == locale.languageCode) {
                    return supported;
                  }
                }
              }
              return const Locale('ar');
            },
            initialRoute: '/splash',
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/splash':
                  return LuxuryPageRoute(page: const SplashScreen());
                case '/login':
                  return LuxuryPageRoute(page: const LoginScreen());
                case '/register':
                  return LuxuryPageRoute(page: const RegisterScreen());
                case '/home':
                  return LuxuryPageRoute(page: const HomeRouter());
                case '/apartment-detail':
                  final apartment = settings.arguments as Apartment;
                  return LuxuryPageRoute(
                    page: ApartmentDetailScreen(apartment: apartment),
                  );
                case '/booking':
                  final apartment = settings.arguments as Apartment;
                  return LuxuryPageRoute(
                    page: BookingScreen(apartment: apartment),
                  );
                case '/my-bookings':
                  return LuxuryPageRoute(page: const MyBookingsScreen());
                case '/add-apartment':
                  return LuxuryPageRoute(page: const AddApartmentScreen());
                case '/chat-list':
                  return LuxuryPageRoute(page: const ChatListScreen());
                case '/chat':
                  final room = settings.arguments as ChatRoom;
                  return LuxuryPageRoute(page: ChatScreen(room: room));
                case '/kyc':
                  return LuxuryPageRoute(page: const KycScreen());
                case '/user-profile':
                  return LuxuryPageRoute(page: const UserProfileScreen());
                case '/apartments-map':
                  return LuxuryPageRoute(page: const ApartmentsMapScreen());
                case '/ai-assistant':
                  return LuxuryPageRoute(page: const AiAssistantScreen());
                case '/ai-copilot':
                  return LuxuryPageRoute(page: const AiCopilotScreen());
                case '/concierge':
                  return LuxuryPageRoute(page: const ConciergeScreen());
                case '/contract':
                  final args = settings.arguments as Map<String, dynamic>;
                  return LuxuryPageRoute(
                    page: ContractScreen(
                      apartment: args['apartment'],
                      totalAmount: args['totalAmount'],
                      periodType: args['periodType'],
                      startDate: args['startDate'],
                      endDate: args['endDate'],
                    ),
                  );
                case '/digital-contract':
                  final contract = settings.arguments as ContractModel;
                  return LuxuryPageRoute(
                    page: DigitalContractScreen(contract: contract),
                  );
                default:
                  return LuxuryPageRoute(page: const SplashScreen());
              }
            },
          );
        },
      ),
    );
  }
}

class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return Scaffold(
            backgroundColor: context.bgColor,
            body: Center(
              child: CircularProgressIndicator(color: context.accentColor),
            ),
          );
        }

        if (state is Authenticated) {
          if (state.user.isOwner) {
            return const OwnerDashboardScreen();
          }
          return const TenantHomeScreen();
        }

        // Fallback: check AuthProvider
        final auth = context.watch<AuthProvider>();
        if (auth.isLoggedIn && auth.user != null) {
          if (auth.isOwner) {
            return const OwnerDashboardScreen();
          }
          return const TenantHomeScreen();
        }

        // Fallback: check AuthService directly
        final directUser = AuthService.currentUser;
        if (directUser != null) {
          if (directUser.role == 'owner') {
            return const OwnerDashboardScreen();
          }
          return const TenantHomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
