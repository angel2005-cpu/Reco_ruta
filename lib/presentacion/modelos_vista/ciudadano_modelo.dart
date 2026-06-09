import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_camiones/datos/repositorios/vehiculo_repositorio.dart';

class CiudadanoModeloVista extends ChangeNotifier {
  final VehiculoRepositorio _vehiculoRepo = VehiculoRepositorio();
  StreamSubscription<List<Map<String, dynamic>>>? _vehiculosSubscription;

  // Lista filtrada solo con los que están trabajando (para pintar en el mapa)
  List<Map<String, dynamic>> _camionesActivos = [];
  List<Map<String, dynamic>> get camionesActivos => _camionesActivos;

  // Lista completa de todas las unidades (para tu menú BottomSheet)
  List<Map<String, dynamic>> _todosLosCamiones = [];
  List<Map<String, dynamic>> get todosLosCamiones => _todosLosCamiones;

  bool _estaCargando = true;
  bool get estaCargando => _estaCargando;

  String? _mensajeError;
  String? get mensajeError => _mensajeError;

  void escucharCamiones() {
    _estaCargando = true;
    _mensajeError = null;
    notifyListeners();

    _vehiculosSubscription = _vehiculoRepo
        .escucharCamionesEnTiempoReal()
        .listen(
          (List<Map<String, dynamic>> datos) {
            _todosLosCamiones = datos;
            // Filtramos: Al mapa solo van las unidades en movimiento
            _camionesActivos = datos
                .where((v) => v['estado'] == 'En Ruta')
                .toList();

            _estaCargando = false;
            _mensajeError = null;
            notifyListeners(); // Redibuja tu pantalla MapaCiudadanoScreen
          },
          onError: (error) {
            _mensajeError = 'Error al conectar con el radar en tiempo real.';
            _estaCargando = false;
            notifyListeners();
          },
        );
  }

  void detenerEscucha() {
    _vehiculosSubscription?.cancel();
    _vehiculosSubscription = null;
  }

  @override
  void dispose() {
    _vehiculosSubscription?.cancel();
    super.dispose();
  }
}
