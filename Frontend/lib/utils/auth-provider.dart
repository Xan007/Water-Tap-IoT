// lib/auth/auth-provider.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:water_tap_front/utils/supabase-client.dart';

class AuthProvider extends ChangeNotifier {
  // Simulación de estados de autenticación
  bool _isAuthenticated = false;
  bool _isLoading = true;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  // Escuchar cambios de estado de autenticación de Supabase
  late final StreamSubscription<AuthState> _authSubscription;

  AuthProvider() {
    // Escucha automáticamente si el token del usuario cambia o expira.
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      // Solo nos interesa el usuario actual
      final Session? session = data.session;

      _isAuthenticated = session?.user != null;

      // Manejar la carga inicial después de que Supabase haya terminado de revisar el almacenamiento local
      if (_isLoading && (event == AuthChangeEvent.initialSession || event == AuthChangeEvent.signedIn || event == AuthChangeEvent.signedOut)) {
        _isLoading = false;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  // Inicialización (ahora solo revisa el estado actual)
  void initializeAuth() {
    // El constructor ya inicia la suscripción y maneja el estado inicial.
    // Solo marcamos isLoading a true al inicio. La suscripción lo cambiará a false.
    _isLoading = true;
    notifyListeners();
  }

  // Método de Login REAL con Supabase
  Future<bool> login(String email, String password) async {
    final AuthResponse response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Si la respuesta tiene un error, Supabase lo manejará a través del .onError,
    // o simplemente regresará una sesión nula.
    // El listener onAuthStateChange actualizará _isAuthenticated automáticamente.
    return response.session != null;
  }

  // Método de Logout REAL con Supabase
  Future<void> logout() async {
    await supabase.auth.signOut();
    // El listener onAuthStateChange actualizará _isAuthenticated a false automáticamente.
  }
}