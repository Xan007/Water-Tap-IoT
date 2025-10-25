import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:water_tap_front/utils/auth-provider.dart';
import 'package:water_tap_front/presentation/widgets/mobile-menu-drawer.dart';

// Definición de colores
const Color darkPrimaryColor = Color(0xFF1E2952);
const Color secondaryColor = Color(0xFF89CFF0);

// Definición del punto de quiebre para simular 'md'
const double _desktopBreakpoint = 700;

// --- 1. Widget de Navegación (sin cambios) ---
// ... (El código de NavItem se mantiene igual)

class NavItem extends StatelessWidget {
  final String path;
  final String label;
  final bool isUserRequired;

  const NavItem({
    super.key,
    required this.path,
    required this.label,
    this.isUserRequired = false,
  });

  bool _isActive(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    final String currentPath = router.routerDelegate.currentConfiguration.last.matchedLocation;

    if (path == '/dashboard') {
      return currentPath == '/' || currentPath == '/dashboard';
    }
    return currentPath == path;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (isUserRequired && !auth.isAuthenticated) {
      return const SizedBox.shrink();
    }

    final bool isActive = _isActive(context);

    return TextButton(
      onPressed: () => context.go(path),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.only(bottom: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Container(
        padding: const EdgeInsets.only(bottom: 2),
        decoration: isActive
            ? const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: secondaryColor,
              width: 2.0,
            ),
          ),
        )
            : null,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? secondaryColor : Colors.white,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// --- 2. Widget Principal Header (AppBar) ---

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAuthenticated = auth.isAuthenticated;
    final navigate = (String path) => GoRouter.of(context).go(path);
    final isDesktop = MediaQuery.of(context).size.width >= _desktopBreakpoint;

    final handleLogout = () async {
      auth.logout();
      GoRouter.of(context).go('/login');
    };

    return AppBar(
      backgroundColor: darkPrimaryColor,
      elevation: 4,
      toolbarHeight: 64,
      automaticallyImplyLeading: false, // Desactiva el ícono de hamburguesa predeterminado

      // Logo y Panel Admin (Title)
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(99)),
            child: const Center(
              child: Text('W', style: TextStyle(color: darkPrimaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 8),
          const Text('WaterTap', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),

          if (isDesktop && isAuthenticated) // Mostrar Panel Admin solo en desktop
            Padding(
              padding: const EdgeInsets.only(left: 24.0),
              child: TextButton.icon(
                onPressed: () => navigate('/admin-panel'),
                icon: const Icon(Icons.settings, size: 16, color: Colors.white),
                label: const Text('Panel Admin', style: TextStyle(color: Colors.white)),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: secondaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
        ],
      ),

      actions: [
        // Navegación Central (Desktop) - Simulando hidden md:flex
        if (isDesktop)
          const Row(
            children: [
              NavItem(path: '/dashboard', label: 'Página principal'),
              SizedBox(width: 24),
              NavItem(path: '/charts', label: 'Gráficas'),
              SizedBox(width: 24),
              NavItem(path: '/data', label: 'Datos', isUserRequired: true),
              SizedBox(width: 24),
              NavItem(path: '/alerts', label: 'Alertas'),
              SizedBox(width: 24),
            ],
          ),

        // Autenticación (Desktop)
        if (isDesktop)
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 24.0),
            child: isAuthenticated
                ? // Cerrar Sesión
            ElevatedButton(
              onPressed: handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: darkPrimaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
              ),
              child: const Text('Cerrar Sesión', style: TextStyle(fontSize: 14)),
            )
                : // Registro / Iniciar Sesión
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => navigate('/register'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: secondaryColor),
                    foregroundColor: secondaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Registro', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => navigate('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    foregroundColor: darkPrimaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Iniciar Sesión', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          )
        else
        // Menú móvil (Mobile) - Simulando md:hidden
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              // Abrir el Drawer. Usa Scaffold.of(context) del contexto de la ShellRoute.
              Scaffold.of(context).openEndDrawer();
            },
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}