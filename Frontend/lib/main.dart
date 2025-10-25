import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:water_tap_front/utils/supabase-client.dart';
import 'package:water_tap_front/utils/auth-provider.dart';

import 'package:water_tap_front/presentation/widgets/header.dart';
import 'package:water_tap_front/presentation/widgets/mobile-menu-drawer.dart';
import 'package:water_tap_front/presentation/pages/login_page.dart';
import 'package:water_tap_front/presentation/pages/charts-page.dart';

import 'package:water_tap_front/presentation/pages/dashboard.dart';


// Implementación de ChartsPage (Mantenemos estas aquí o las movemos a sus propios archivos si son complejas)
class ChartsPage extends StatelessWidget {
  const ChartsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Charts Page Content',
        style: TextStyle(fontSize: 30, color: Color(0xFF1E2952)),
      ),
    );
  }
}

// Implementación de RegisterPage
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Registro')),
        body: const Center(child: Text('Register Page'))
    );
  }
}

// Implementación de ResetPasswordPage
class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Restablecer Contraseña')),
        body: const Center(child: Text('Reset Password Page'))
    );
  }
}

// Implementación de AlertsPage
class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Página de Alertas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E2952))),
          SizedBox(height: 8),
          Text('En construcción', style: TextStyle(color: Color(0xFF5D89BA), fontSize: 16)),
        ],
      ),
    );
  }
}

// Implementación de DataPage
class DataPage extends StatelessWidget {
  const DataPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Data Page Content',
        style: TextStyle(fontSize: 30, color: Color(0xFF1E2952)),
      ),
    );
  }
}


// =========================================================================
// 1. CONFIGURACIÓN DEL ROUTER (GoRouter)
// =========================================================================

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthProvider authProvider) {
  const List<String> noHeaderPaths = ['/login', '/register', '/reset-password'];

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',

    // FUNCIÓN DE REDIRECCIÓN (Control de acceso y rutas protegidas)
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final location = state.uri.toString();

      final isLoggingIn = location == '/login';
      final isRegistering = location == '/register';
      final isResetting = location == '/reset-password';

      // 1. Espera si la autenticación está cargando.
      if (authProvider.isLoading) return null;

      // 2. Si el usuario NO está autenticado:
      if (!isAuthenticated) {
        return (isLoggingIn || isRegistering || isResetting) ? null : '/login';
      }

      // 3. Si el usuario SÍ está autenticado:
      if (isAuthenticated && (isLoggingIn || isRegistering || isResetting)) {
        return '/dashboard';
      }

      // 4. Permite la navegación solicitada.
      return null;
    },

    // Notificar al router cuando cambie el estado de autenticación
    refreshListenable: authProvider,

    routes: [
      // ShellRoute: Rutas con layout compartido (Header/Drawer)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          final bool showHeader = !noHeaderPaths.contains(state.uri.toString());

          return Builder(
              builder: (innerContext) {
                return Scaffold(
                  appBar: showHeader ? const Header() : null,
                  endDrawer: showHeader ? const MobileMenuDrawer() : null,
                  body: child,
                );
              }
          );
        },
        routes: [
          // Rutas principales
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(), // USA LA CLASE IMPORTADA
          ),
          GoRoute(
            path: '/charts',
            builder: (context, state) => const ChartsPage(),
          ),
          GoRoute(
            path: '/data',
            builder: (context, state) => const DataPage(),
          ),
          GoRoute(
            path: '/alerts',
            builder: (context, state) => const AlertsPage(),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardPage(), // USA LA CLASE IMPORTADA
          ),
          GoRoute(
            path: '/admin-panel',
            builder: (context, state) => const Text('Admin Panel Page'),
          ),
        ],
      ),

      // Rutas de Autenticación (sin Header/Shell)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordPage(),
      ),

      // Fallback
      GoRoute(
        path: '/:path',
        builder: (context, state) => const Center(child: Text('404 - Page Not Found')),
      ),
    ],
  );
}


// =========================================================================
// 2. WIDGET PRINCIPAL (main y MyApp)
// =========================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicialización de Supabase
  await initializeSupabase();

  runApp(
    // Envuelve con AuthProvider
    ChangeNotifierProvider(
      // Inicia la verificación del estado de autenticación
      create: (context) => AuthProvider()..initializeAuth(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (innerContext) {
        // Observa los cambios de autenticación para reconstruir el router si es necesario
        final authProvider = innerContext.watch<AuthProvider>();
        final GoRouter router = createRouter(authProvider);

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Water Tap App',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E2952)),
            useMaterial3: true,
          ),
          routerConfig: router,
        );
      },
    );
  }
}