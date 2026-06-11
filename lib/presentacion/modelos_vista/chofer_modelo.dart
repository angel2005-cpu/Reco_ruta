import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_application_camiones/datos/repositorios/vehiculo_repositorio.dart';

class ChoferModeloVista extends ChangeNotifier {
  final VehiculoRepositorio _vehiculoRepo = VehiculoRepositorio();

  // Suscripción activa al GPS para poder apagarla cuando el chofer termine su turno
  StreamSubscription<Position>? _gpsSubscription;

  bool _estaTransmitiendo = false;
  bool get estaTransmitiendo => _estaTransmitiendo;

  String? _mensajeError;
  String? get mensajeError => _mensajeError;

  /// Inicia el estado de la ruta (Valida hardware y activa bandera de transmisión)
  Future<void> iniciarRuta(int idVehiculo) async {
    _mensajeError = null;

    bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      _mensajeError = 'El GPS está apagado. Por favor, enciéndelo.';
      notifyListeners();
      return;
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      _mensajeError = 'La aplicación no tiene permisos de GPS.';
      notifyListeners();
      return;
    }

    // Cambiar estado a transmitiendo para que la vista encienda su rastreador gráfico
    _estaTransmitiendo = true;
    notifyListeners();
  }

  /// MÉTODO AGREGADO: Sincroniza las coordenadas dinámicas con Supabase
  Future<void> actualizarUbicacionVehiculo({
    required int idVehiculo,
    required double latitud,
    required double longitud,
  }) async {
    try {
      // Consumimos el método de tu repositorio de vehículos
      await _vehiculoRepo.actualizarUbicacionCamion(
        idVehiculo: idVehiculo,
        latitud: latitud,
        longitud: longitud,
      );

      _mensajeError = null;
    } catch (e) {
      _mensajeError =
          'Error de conexión: No se pudo actualizar la ruta en el servidor.';
      notifyListeners();
    }
  }

  /// Detiene el rastreo y cierra el flujo para ahorrar batería
  Future<void> detenerRuta(
    int idVehiculo, {
    String estadoFinal = 'Disponible',
  }) async {
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    _estaTransmitiendo = false;

    try {
      // 📡 AVISO GLOBAL: Libera el camión en Supabase
      await _vehiculoRepo.actualizarEstadoVehiculo(
        idVehiculo: idVehiculo,
        nuevoEstado: estadoFinal,
      );
      _mensajeError = null;
    } catch (e) {
      _mensajeError = 'Error al guardar estado final en el servidor.';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    super.dispose();
  }
}
