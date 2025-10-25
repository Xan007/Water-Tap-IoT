// lib/presentation/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Asegúrate de que las rutas de importación sean correctas
import 'package:water_tap_front/utils/auth-provider.dart'; // Tu AuthProvider
import 'package:water_tap_front/utils/supabase-client.dart'; // Tu cliente Supabase

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _localLoading = false;

  final Color _backgroundColor = const Color(0xFFF0FFFF);
  final Color _primaryColor = Colors.black;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- FUNCIONALIDAD DE LOGIN REAL CON SUPABASE ---
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _localLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      // Llama a la función del provider que envuelve supabase.auth.signInWithPassword
      final success = await authProvider.login(
        _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        if (!success) {
          // Si el login falla y no lanza excepción (ej. credenciales inválidas)
          setState(() {
            _errorMessage = 'Credenciales inválidas o cuenta no confirmada.';
          });
        }
        // Si hay éxito, el redirect de GoRouter lo moverá a /dashboard.
      }
    } on AuthException catch (e) {
      // Captura de errores específicos de Supabase (ej. rate limit, problemas de conexión)
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ocurrió un error inesperado al iniciar sesión.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _localLoading = false;
        });
      }
    }
  }

  // --- FUNCIONALIDAD DE RESTABLECER CONTRASEÑA REAL CON SUPABASE (CORREGIDA) ---
  Future<void> _handlePasswordReset() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, ingresa tu correo electrónico para restablecer la contraseña.';
      });
      return;
    }

    setState(() {
      _localLoading = true;
      _errorMessage = null;
    });

    try {
      // La URL de redirección debe configurarse para Flutter Web (Hash Routing)
      const String redirectTo = '/reset-password';

      // La función resetPasswordForEmail devuelve Future<void> y lanza una excepción si falla.
      await supabase.auth.resetPasswordForEmail(
        _emailController.text,
        redirectTo: redirectTo,
      );

      if (mounted) {
        // Si el await no lanzó una excepción, la llamada fue exitosa.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se ha enviado un correo para restablecer tu contraseña. Revisa tu bandeja de entrada.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on AuthException catch (e) {
      // Captura de errores específicos de Supabase (ej. usuario no encontrado).
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error desconocido al solicitar restablecimiento.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _localLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usa un listener para saber si el AuthProvider está en proceso de carga
    final bool appLoading = context.watch<AuthProvider>().isLoading;
    final bool isLoading = _localLoading || appLoading;

    return Scaffold(
      // Fondo similar a bg-[#F0FFFF]
      backgroundColor: _backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            // Card simulando la estética de shadcn/ui
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Bordes menos redondeados
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                // Padding interno CardContent
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // CardHeader & CardTitle
                      const Text(
                        'Iniciar Sesión',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Color primario
                        ),
                      ),
                      const SizedBox(height: 8),
                      // CardDescription
                      const Text(
                        'Ingresa tu correo y contraseña para acceder a tu cuenta.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6B7280), // Gris simulado
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email Input
                      const Text('Correo', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)), // Label
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'mario@example.com',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12), // Simula padding de Input
                        ),
                        validator: (value) => (value == null || value.isEmpty) ? 'El correo es obligatorio' : null,
                      ),
                      const SizedBox(height: 16), // Espacio entre campos

                      // Password Input
                      const Text('Contraseña', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)), // Label
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        ),
                        validator: (value) => (value == null || value.isEmpty) ? 'La contraseña es obligatoria' : null,
                      ),
                      const SizedBox(height: 24), // Espacio antes del error/botón

                      // Error Message
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14), // text-red-500
                          ),
                        ),

                      // Login Button
                      ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40), // Simula Button w-full
                          backgroundColor: _primaryColor, // Botón primario de shadcn
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const Text('Iniciar Sesión'),
                      ),
                      const SizedBox(height: 16), // mt-4

                      // Password Reset Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿Olvidaste tu contraseña? ',
                            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)), // text-gray-600
                          ),
                          TextButton(
                            onPressed: isLoading ? null : _handlePasswordReset,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              alignment: Alignment.centerLeft,
                            ),
                            child: const Text('Restablecer contraseña',
                                style: TextStyle(color: Color(0xFF2563EB), fontSize: 14)), // text-blue-600
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿No tienes una cuenta? ',
                            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                          ),
                          TextButton(
                            onPressed: () => context.go('/register'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              alignment: Alignment.centerLeft,
                            ),
                            child: const Text('Regístrate aquí',
                                style: TextStyle(color: Color(0xFF2563EB), fontSize: 14)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      // La Toaster se simula con un SnackBar dentro de _handlePasswordReset
    );
  }
}