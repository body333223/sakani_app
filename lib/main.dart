import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakani/core/di/injection_container.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakani/features/apartments/presentation/cubit/apartment_cubit.dart';
import 'package:sakani/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:sakani/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:sakani/features/auth/data/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
            initialRoute: '/login',
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/login':
                  return MaterialPageRoute(builder: (_) => const LoginScreen());
                case '/register':
                  return MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  );
                case '/home':
                  return MaterialPageRoute(builder: (_) => const HomeRouter());
                case '/apartment-detail':
                  final apartment = settings.arguments as Apartment;
                  return MaterialPageRoute(
                    builder: (_) => ApartmentDetailScreen(apartment: apartment),
                  );
                case '/booking':
                  final apartment = settings.arguments as Apartment;
                  return MaterialPageRoute(
                    builder: (_) => BookingScreen(apartment: apartment),
                  );
                case '/my-bookings':
                  return MaterialPageRoute(
                    builder: (_) => const MyBookingsScreen(),
                  );
                case '/add-apartment':
                  return MaterialPageRoute(
                    builder: (_) => const AddApartmentScreen(),
                  );
                case '/chat-list':
                  return MaterialPageRoute(
                    builder: (_) => const ChatListScreen(),
                  );
                case '/chat':
                  final room = settings.arguments as ChatRoom;
                  return MaterialPageRoute(
                    builder: (_) => ChatScreen(room: room),
                  );
                default:
                  return MaterialPageRoute(builder: (_) => const LoginScreen());
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
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return Scaffold(
        backgroundColor: context.bgColor,
        body: Center(
          child: CircularProgressIndicator(color: context.accentColor),
        ),
      );
    }

    // If not loading and user is null, redirect to Login
    if (auth.user == null) {
      return const LoginScreen();
    }

    if (auth.isOwner) {
      return const OwnerDashboardScreen();
    }
    return const TenantHomeScreen();
  }
}
