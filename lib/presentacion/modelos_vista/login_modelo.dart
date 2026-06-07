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

  /// Ejecuta el proceso de inicio de sesión
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
      // Consultamos al repositorio el rol del usuario
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

  /// Limpia los datos de sesión anteriores al volver a la pantalla
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
}
