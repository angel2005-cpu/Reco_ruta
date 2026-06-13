import 'package:flutter/material.dart';
import 'package:flutter_application_camiones/datos/repositorios/autenticacion_repositorio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginModeloVista extends ChangeNotifier {
  final AutenticacionRepositorio _authRepository = AutenticacionRepositorio();

  bool _estaCargando = false;
  bool get estaCargando => _estaCargando;

  String? _mensajeError;
  String? get mensajeError => _mensajeError;

  String? _rolUsuario;
  String? get rolUsuario => _rolUsuario;
  int? _idUsuario;
  int? get idUsuario => _idUsuario;

  /// Ejecuta la validación lógica del Login
  Future<void> ejecutarLogin({
    required String usuario,
    required String password,
  }) async {
    if (usuario.isEmpty || password.isEmpty) {
      _actualizarEstado(error: 'Por favor, llena todos los campos.');
      return;
    }

    _actualizarEstado(cargando: true, error: null);

    try {
      final resultado = await _authRepository.iniciarSesion(
        usuario: usuario.trim(),
        password: password,
      );

      _rolUsuario = resultado['rol'];
      _idUsuario = resultado['id_usuario'];

      // Guardar sesión localmente
      await registrarSesionLocal(_idUsuario!, _rolUsuario!);

      _actualizarEstado(cargando: false);
    } catch (e) {
      _actualizarEstado(cargando: false, error: e.toString());
    }
  }

  /// Resetea los estados al salir o volver a entrar
  void limpiarDatos() {
    _rolUsuario = null;
    _mensajeError = null;
    _estaCargando = false;
  }

  void _actualizarEstado({bool? cargando, String? error}) {
    if (cargando != null) _estaCargando = cargando;
    _mensajeError = error;
    notifyListeners();
  }

  Future<void> registrarSesionLocal(int idUsuario, String rol) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setInt('id_usuario', idUsuario);
    await prefs.setString('rol', rol);
    await prefs.setBool('esta_logueado', true);
  }

  Future<void> cerrarSesion() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.remove('id_usuario');
    await prefs.remove('rol');
    await prefs.setBool('esta_logueado', false);
  }
}
