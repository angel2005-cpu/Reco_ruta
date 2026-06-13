import 'package:flutter/material.dart';
import 'package:flutter_application_camiones/datos/utilidades/notificacion_servicio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentacion/pantallas/login_screen.dart';
import 'presentacion/pantallas/interfaz_chofer.dart';
import 'presentacion/pantallas/mapa_ciudadano.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificacionServicio.inicializar();
  await Supabase.initialize(
    url: 'https://tpmcbexsogdsgnpuubam.supabase.co',
    anonKey: 'sb_publishable__5SmP_j0ooEggOvtZ7wQdw_KRpox71e',
  );
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool estaLogueado = prefs.getBool('esta_logueado') ?? false;
  final int? idUsuario = prefs.getInt('id_usuario');
  final String? rol = prefs.getString('rol');

  runApp(MyApp(estaLogueado: estaLogueado, idUsuario: idUsuario, rol: rol));
}

class MyApp extends StatelessWidget {
  // declaramos las propiedades que recibirá el Widget principal
  final bool estaLogueado;
  final int? idUsuario;
  final String? rol;

  // definimos correctamente el constructor con las variables requeridas
  const MyApp({
    super.key,
    required this.estaLogueado,
    this.idUsuario,
    this.rol,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recoruta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      // evaluamos de forma dinámica cuál será la pantalla inicial al abrir la app
      home: _obtenerPantallaInicial(),
      routes: {
        '/login': (context) => const LoginPantalla(),
        '/mapa_ciudadano': (context) {
          final int id =
              ModalRoute.of(context)?.settings.arguments as int? ??
              idUsuario ??
              0;
          return MapaCiudadanoScreen(idUsuario: id);
        },
        '/interfaz_chofer': (context) {
          final int id =
              ModalRoute.of(context)?.settings.arguments as int? ??
              idUsuario ??
              0;
          return InterfazChoferScreen(idUsuario: id);
        },
      },
    );
  }

  Widget _obtenerPantallaInicial() {
    if (!estaLogueado || idUsuario == null || rol == null) {
      return const LoginPantalla();
    }

    if (rol == 'chofer') {
      return InterfazChoferScreen(idUsuario: idUsuario!);
    } else {
      return MapaCiudadanoScreen(idUsuario: idUsuario!);
    }
  }
}
