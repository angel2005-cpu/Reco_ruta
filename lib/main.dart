import 'package:flutter_application_camiones/datos/utilidades/notificacion_servicio.dart';
import 'package:flutter/material.dart';
import 'presentacion/pantallas/mapa_ciudadano.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'presentacion/pantallas/interfaz_chofer.dart';
import 'presentacion/pantallas/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificacionServicio.inicializar();
  await Supabase.initialize(
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      // Definimos la pantalla de inicio de la aplicación
      home: const LoginPantalla(),
      routes: {
        '/login': (context) => const LoginPantalla(),
        '/mapa_ciudadano': (context) {
          final int idUsuario =
              ModalRoute.of(context)?.settings.arguments as int? ?? 0;
          return MapaCiudadanoScreen(idUsuario: idUsuario);
        },
        '/interfaz_chofer': (context) {
          final int idUsuario =
              ModalRoute.of(context)?.settings.arguments as int? ?? 0;
          return InterfazChoferScreen(idUsuario: idUsuario);
        },
      },
    );
  }
}
