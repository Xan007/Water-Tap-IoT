// lib/utils/supabase_client.dart

import 'package:supabase_flutter/supabase_flutter.dart';

// Los valores de tu archivo React (supabaseClient.tsx)
const String supabaseUrl = "https://lujaciqugqbjshmzyuvn.supabase.co";
const String supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx1amFjaXF1Z3FianNobXp5dXZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY5NTk5NDYsImV4cCI6MjA3MjUzNTk0Nn0.UXSxGVKQUzSJM6Xxcqx6xIEdP7vT7GIkofpA7IAksv8";

// Inicializa y expón el cliente Supabase
final SupabaseClient supabase = Supabase.instance.client;

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
}