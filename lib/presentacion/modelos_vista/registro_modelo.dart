import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Importamos el plugin de GPS
import '../../datos/repositorios/autenticacion_repositorio.dart';

class RegistroModeloVista extends ChangeNotifier {
  final AutenticacionRepositorio _authRepository = AutenticacionRepositorio();

  bool _estaCargando = false;
  bool get estaCargando => _estaCargando;

  String? _mensajeError;
  String? get mensajeError => _mensajeError;

  bool _registroExitoso = false;
  bool get registroExitoso => _registroExitoso;

  /// 🛰️ Método para obtener la ubicación GPS actual del dispositivo
  Future<Position?> obtenerUbicacionGPS() async {
    bool servicioHabilitado;
    LocationPermission permiso;

    // Verificar si el GPS del celular está encendido
    servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      _actualizarEstado(
        error: 'El GPS está desactivado. Por favor, enciéndelo.',
      );
      return null;
    }

    // Verificar y solicitar permisos de ubicación a nivel de sistema operativo
    permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        _actualizarEstado(error: 'Permiso de ubicación denegado.');
        return null;
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      _actualizarEstado(
        error:
            'Los permisos de ubicación están denegados permanentemente en los ajustes.',
      );
      return null;
    }

    // Si todo está en orden, obtiene la posición actual con alta precisión
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// 🚀 Lógica de negocio para validar y registrar
  Future<void> ejecutarRegistro({
    required String usuario,
    required String password,
    required String confirmarPassword,
    required String nombre,
  }) async {
    if (usuario.isEmpty ||
        password.isEmpty ||
        confirmarPassword.isEmpty ||
        nombre.isEmpty) {
      _actualizarEstado(error: 'Por favor, completa todos los campos.');
      return;
    }

    if (password != confirmarPassword) {
      _actualizarEstado(error: 'Las contraseñas no coinciden.');
      return;
    }

    _actualizarEstado(cargando: true, error: null);

    try {
      // Solicitamos la ubicación en tiempo real justo antes de mandar a Supabase
      Position? posicion = await obtenerUbicacionGPS();

      if (posicion == null) {
        _actualizarEstado(
          cargando: false,
        ); // El método de arriba ya setea el mensaje de error específico
        return;
      }

      // Enviamos todo al repositorio con las coordenadas del GPS automático
      await _authRepository.registrarCiudadano(
        usuario: usuario.trim(),
        password: password,
        nombre: nombre.trim(),
        latitud: posicion.latitude,
        longitud: posicion.longitude,
      );

      _registroExitoso = true;
      _actualizarEstado(cargando: false);
    } catch (e) {
      _actualizarEstado(cargando: false, error: e.toString());
    }
  }

  void _actualizarEstado({bool? cargando, String? error}) {
    if (cargando != null) _estaCargando = cargando;
    _mensajeError = error;
    notifyListeners();
  }
}
