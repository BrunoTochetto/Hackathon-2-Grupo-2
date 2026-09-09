import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/landing/landing_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/movement/movement_screen.dart';
import '../screens/production/production_screen.dart';
import '../screens/kitchen/kitchen_screen.dart';
import '../screens/menu/menu_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/waste/waste_screen.dart';
import '../screens/demo/demo_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/about/about_screen.dart';
import '../screens/gerente_page.dart';
import '../screens/cozinha_page.dart';
import '../state/auth_provider.dart';

class AppRoutes {
  static const String landing = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String recepcao = '/recepcao';
  static const String gerente = '/gerente';
  static const String kitchen = '/kitchen';
  static const String cozinha = '/cozinha';
  static const String menu = '/menu';
  static const String movement = '/movement';
  static const String production = '/production';
  static const String history = '/history';
  static const String waste = '/waste';
  static const String demo = '/demo';
  static const String settings = '/settings';
  static const String about = '/about';

  static Map<String, WidgetBuilder> get routes => {
        landing: (context) => const LandingScreen(),
        login: (context) => const LoginScreen(),
        register: (context) => const RegisterScreen(),
        forgotPassword: (context) => const ForgotPasswordScreen(),
        dashboard: (context) => _protectedRoute(context, const DashboardScreen()),
        recepcao: (context) => const GerentePage(),
        gerente: (context) => const GerentePage(),
        kitchen: (context) => const KitchenScreen(),
        cozinha: (context) => const CozinhaPage(),
        menu: (context) => _protectedRoute(context, const MenuScreen()),
        movement: (context) => _protectedRoute(context, const MovementScreen()),
        production: (context) => _protectedRoute(context, const ProductionScreen()),
        history: (context) => _protectedRoute(context, const HistoryScreen()),
        waste: (context) => _protectedRoute(context, const WasteScreen()),
        demo: (context) => _protectedRoute(context, const DemoScreen()),
        settings: (context) => _protectedRoute(context, const SettingsScreen()),
        about: (context) => const AboutScreen(),
      };

  /// Proteção de rotas internas: se não autenticado, redireciona para o login
  static Widget _protectedRoute(BuildContext context, Widget screen) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }
    return screen;
  }
}
