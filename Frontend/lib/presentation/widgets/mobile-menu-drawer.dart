import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:water_tap_front/utils/auth-provider.dart';

const Color darkPrimaryColor = Color(0xFF1E2952);
const Color secondaryColor = Color(0xFF89CFF0);

// Define los ítems del menú móvil
class MobileMenuItem {
  final String path;
  final String label;
  final IconData icon;
  final bool isUserRequired;

  const MobileMenuItem({
    required this.path,
    required this.label,
    required this.icon,
    this.isUserRequired = false,
  });
}

// Lista de ítems para el Drawer
const List<MobileMenuItem> _menuItems = [
  MobileMenuItem(path: '/dashboard', label: 'Página principal', icon: Icons.dashboard),
  MobileMenuItem(path: '/charts', label: 'Gráficas', icon: Icons.bar_chart),
  MobileMenuItem(path: '/data', label: 'Datos', icon: Icons.storage, isUserRequired: true),
  MobileMenuItem(path: '/alerts', label: 'Alertas', icon: Icons.warning_amber),
];


class MobileMenuDrawer extends StatelessWidget {
  const MobileMenuDrawer({super.key});

  // Determina si el path actual coincide con el path del ítem
  bool _isActive(BuildContext context, String path) {
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
    final isAuthenticated = auth.isAuthenticated;
    final navigate = (String path) {
      context.pop(); // Cierra el Drawer
      context.go(path); // Navega a la ruta
    };

    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Logo/Header del Drawer
          DrawerHeader(
            decoration: const BoxDecoration(color: darkPrimaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(99)),
                  child: const Center(child: Text('W', style: TextStyle(color: darkPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16))),
                ),
                const SizedBox(height: 8),
                const Text('WaterTap', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Ítems de navegación
          ..._menuItems.map((item) {
            if (item.isUserRequired && !isAuthenticated) {
              return const SizedBox.shrink(); // Oculta si requiere usuario
            }

            final isActive = _isActive(context, item.path);

            return ListTile(
              leading: Icon(item.icon, color: isActive ? secondaryColor : darkPrimaryColor),
              title: Text(
                item.label,
                style: TextStyle(
                  color: isActive ? secondaryColor : darkPrimaryColor,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isActive,
              onTap: () => navigate(item.path),
            );
          }).toList(),

          const Divider(height: 20, thickness: 1),

          // Botones de Autenticación/Admin
          if (isAuthenticated)
            ...[
              // Panel Admin
              ListTile(
                leading: const Icon(Icons.settings, color: darkPrimaryColor),
                title: const Text('Panel Admin', style: TextStyle(color: darkPrimaryColor)),
                onTap: () => navigate('/admin-panel'),
              ),
              // Cerrar Sesión
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                onTap: () {
                  context.pop();
                  auth.logout();
                  context.go('/login');
                },
              ),
            ]
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  // Iniciar Sesión
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => navigate('/login'),
                      style: ElevatedButton.styleFrom(backgroundColor: secondaryColor, foregroundColor: darkPrimaryColor),
                      child: const Text('Iniciar Sesión'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Registro
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => navigate('/register'),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: secondaryColor),
                          foregroundColor: secondaryColor
                      ),
                      child: const Text('Registro'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}