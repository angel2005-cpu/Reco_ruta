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

  /// 🟢 Inicia el rastreo del camión en tiempo real
  Future<void> iniciarRuta(int idVehiculo) async {
    _mensajeError = null;

    // 1. Validar permisos mínimos del hardware del GPS
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

    // 2. Cambiar estado a transmitiendo
    _estaTransmitiendo = true;
    notifyListeners();

    // Configuración del GPS: Alta precisión y actualiza cada 10 metros de movimiento
    const LocationSettings settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    // 3. Empezar a escuchar el flujo del GPS
    _gpsSubscription = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
          (Position posicion) async {
            try {
              // Enviamos las coordenadas directo a Supabase
              await _vehiculoRepo.actualizarUbicacionCamion(
                idVehiculo: idVehiculo,
                latitud: posicion.latitude,
                longitud: posicion.longitude,
              );
              print(
                'Ubicación actualizada: ${posicion.latitude}, ${posicion.longitude}',
              );
            } catch (e) {
              _mensajeError = 'Error de conexión con el servidor.';
              notifyListeners();
            }
          },
          onError: (error) {
            _mensajeError = 'Error en el flujo del GPS.';
            detenerRuta();
          },
        );
  }

  /// 🔴 Detiene el rastreo y cierra el flujo para ahorrar batería
  void detenerRuta() {
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    _estaTransmitiendo = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    super.dispose();
  }
}
