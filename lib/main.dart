import 'package:flutter/material.dart';
import 'presentacion/pantallas/mapa_ciudadano.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'presentacion/pantallas/interfaz_chofer.dart';
import 'presentacion/pantallas/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Supabase.initialize(
    url: 'https://tpmcbexsogdsgnpuubam.supabase.co',
    anonKey: 'sb_publishable__5SmP_j0ooEggOvtZ7wQdw_KRpox71e',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recoruta',
      debugShowCheckedModeBanner:
          false, // Quita la etiqueta roja de "Debug" en la esquina
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      // Definimos la pantalla de inicio de la aplicación
      home: const InterfazChoferScreen(),
    );
  }
}
