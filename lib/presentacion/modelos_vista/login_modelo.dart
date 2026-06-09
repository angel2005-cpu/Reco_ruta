import 'package:flutter/material.dart';
import 'package:flutter_application_camiones/datos/repositorios/autenticacion_repositorio.dart';

class LoginModeloVista extends ChangeNotifier {
  final AutenticacionRepositorio _authRepository = AutenticacionRepositorio();

  bool _estaCargando = false;
  bool get estaCargando => _estaCargando;

  String? _mensajeError;
  String? get mensajeError => _mensajeError;

  String? _rolUsuario;
  String? get rolUsuario => _rolUsuario;

  /// Ejecuta la validación lógica del Login
  Future<void> ejecutarLogin({
    required String usuario,
    required String password,
  }) async {
    // Validación básica inicial
    if (usuario.isEmpty || password.isEmpty) {
      _actualizarEstado(error: 'Por favor, llena todos los campos.');
      return;
    }

    _actualizarEstado(cargando: true, error: null);

    try {
      // Mandamos a pedir el rol al repositorio
      final String rol = await _authRepository.iniciarSesion(
        usuario: usuario.trim(),
        password: password,
      );

      _rolUsuario = rol;
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
    notifyListeners(); // Avisa a login_screen.dart que hubo cambios
  }
}
