import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// Services
import 'services/auth_service.dart';
import 'services/database_service.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/vehicles/vehicle_list_screen.dart';
import 'screens/vehicles/vehicle_detail_screen.dart';
import 'screens/vehicles/add_vehicle_screen.dart';
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

// Widgets
import 'widgets/chatbot_widget.dart';

// Models
import 'models/insurance_model.dart';

// Chave global para controlar a navegação principal
final GlobalKey<MainNavigationScreenState> mainNavigationKey =
    GlobalKey<MainNavigationScreenState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => DatabaseService()),
      ],
      child: MaterialApp.router(
        title: 'ClassicDrive',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E3A8A), // Azul clássico
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        routerConfig: _router,
      ),
    );
  }
}

// Configuração de rotas
final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: [
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
          path: 'add-vehicle',
          builder: (context, state) => const AddVehicleScreen(),
        ),
        GoRoute(
          path: 'booking/:vehicleId',
          builder: (context, state) => BookingScreen(
            vehicleId: state.pathParameters['vehicleId']!,
          ),
        ),
        // Rotas para proprietários
        GoRoute(
          path: 'my-vehicles',
          builder: (context, state) =>
              const VehicleListScreen(showOnlyMine: true),
        ),
        GoRoute(
          path: 'reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        // Rotas para arrendatários
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
        // Veículos com categoria
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
        // Novas rotas de segurança e KYC
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

// Navegação principal com BottomNavigationBar e Chatbot
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

  // Método público para permitir a mudança de aba externamente
  void changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Conteúdo principal
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          // Chatbot flutuante
          const Positioned(
            right: 0,
            bottom: 80, // Acima do BottomNavigationBar
            child: ChatbotWidget(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Veículos',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Reservas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}