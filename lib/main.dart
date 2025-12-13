import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:classic_drive/l10n/app_localizations.dart';

// Theme
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';

// Services
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/admin_service.dart';
import 'services/payment_service.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/vehicles/vehicle_list_screen.dart';
import 'screens/vehicles/vehicle_detail_screen.dart';
import 'screens/vehicles/add_vehicle_screen.dart';
import 'screens/vehicles/vehicle_availability_screen.dart';
import 'screens/bookings/booking_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/bookings/bookings_list_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/favorites/favorites_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/help/help_support_screen.dart';
import 'screens/kyc/kyc_verification_screen.dart';
import 'screens/insurance/insurance_claim_screen.dart';
import 'screens/recommendations/recommendations_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_kyc_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/admin/admin_vehicles_screen.dart';
import 'screens/admin/admin_bookings_screen.dart';
import 'screens/admin/admin_logs_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/owner/owner_dashboard_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/chat/conversations_screen.dart';
import 'screens/chat/chat_screen.dart';

// Widgets
import 'widgets/chatbot_widget.dart';
import 'widgets/modern_navigation.dart';

// Models
import 'models/insurance_model.dart';

// Providers
import 'providers/comparison_provider.dart';
import 'screens/vehicles/comparison_screen.dart';

final GlobalKey<MainNavigationScreenState> mainNavigationKey =
    GlobalKey<MainNavigationScreenState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar status bar transparente
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Permitir edge-to-edge
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await dotenv.load(fileName: ".env");
  await PaymentService().init();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

/// Aplicação principal ClassicDrive com design moderno.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => DatabaseService()),
        Provider(create: (_) => AdminService()),
        ChangeNotifierProvider(create: (_) => ComparisonProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'ClassicDrive',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('pt'),
              Locale('en'),
            ],
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => MainNavigationScreen(key: mainNavigationKey),
      routes: [
        GoRoute(
          path: 'vehicle/:id',
          builder: (context, state) => VehicleDetailScreen(
            vehicleId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: 'vehicle-availability/:id',
          builder: (context, state) => VehicleAvailabilityScreen(
            vehicleId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: 'add-vehicle',
          builder: (context, state) => const AddVehicleScreen(),
        ),
        GoRoute(
          path: 'booking/:vehicleId',
          builder: (context, state) => BookingScreen(
            vehicleId: state.pathParameters['vehicleId']!,
          ),
        ),
        GoRoute(
          path: 'my-vehicles',
          builder: (context, state) =>
              const VehicleListScreen(showOnlyMine: true),
        ),
        GoRoute(
          path: 'reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: 'search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: 'favorites',
          builder: (context, state) => const FavoritesScreen(),
        ),
        GoRoute(
          path: 'history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: 'vehicles-category',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return VehicleListScreen(
              category: extra?['category'],
              categoryTitle: extra?['title'],
            );
          },
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: 'help-support',
          builder: (context, state) => const HelpSupportScreen(),
        ),
        GoRoute(
          path: 'kyc-verification',
          builder: (context, state) => const KYCVerificationScreen(),
        ),
        GoRoute(
          path: 'insurance-claim',
          builder: (context, state) {
            final policy = state.extra as InsurancePolicy;
            return InsuranceClaimScreen(policy: policy);
          },
        ),
        GoRoute(
          path: 'recommendations',
          builder: (context, state) => const RecommendationsScreen(),
        ),
        GoRoute(
          path: 'compare',
          builder: (context, state) => const ComparisonScreen(),
        ),
        GoRoute(
          path: 'owner-dashboard',
          builder: (context, state) => const OwnerDashboardScreen(),
        ),
        GoRoute(
          path: 'notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: 'conversations',
          builder: (context, state) => const ConversationsScreen(),
        ),
        GoRoute(
          path: 'chat/:conversationId',
          builder: (context, state) => ChatScreen(
            conversationId: state.pathParameters['conversationId']!,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
      routes: [
        GoRoute(
          path: 'kyc',
          builder: (context, state) => const AdminKYCScreen(),
        ),
        GoRoute(
          path: 'users',
          builder: (context, state) => const AdminUsersScreen(),
        ),
        GoRoute(
          path: 'vehicles',
          builder: (context, state) => const AdminVehiclesScreen(),
        ),
        GoRoute(
          path: 'bookings',
          builder: (context, state) => const AdminBookingsScreen(),
        ),
        GoRoute(
          path: 'logs',
          builder: (context, state) => const AdminLogsScreen(),
        ),
      ],
    ),
  ],
  redirect: (context, state) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isLoggedIn = authService.currentUser != null;
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }
    if (isLoggedIn && isAuthRoute) {
      return '/';
    }
    return null;
  },
);

/// Ecrã de navegação principal com Bottom Navigation moderna.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const VehicleListScreen(),
    const BookingsListScreen(),
    const ProfileScreen(),
  ];

  /// Muda a aba selecionada.
  void changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          const Positioned(
            right: 0,
            bottom: 100,
            child: ChatbotWidget(),
          ),
        ],
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          ModernNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'Início',
          ),
          ModernNavItem(
            icon: Icons.directions_car_outlined,
            selectedIcon: Icons.directions_car_rounded,
            label: 'Veículos',
          ),
          ModernNavItem(
            icon: Icons.calendar_today_outlined,
            selectedIcon: Icons.calendar_today_rounded,
            label: 'Reservas',
          ),
          ModernNavItem(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
