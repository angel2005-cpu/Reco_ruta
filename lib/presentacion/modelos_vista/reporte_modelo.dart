import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_camiones/datos/repositorios/reporte_repositorio.dart';

class ReporteModeloVista extends ChangeNotifier {
  final ReporteRepositorio _reporteRepo = ReporteRepositorio();

  bool _estaCargando = false;
  bool get estaCargando => _estaCargando;

  String? _mensajeError;
  String? get mensajeError => _mensajeError;

  bool _operacionExitosa = false;
  bool get operacionExitosa => _operacionExitosa;

  /// Lógica para procesar y enviar el reporte del ciudadano (Recibe la foto directa)
  Future<void> enviarReporte({
    required int idUsuario,
    required String descripcion,
    required double? latitud,
    required double? longitud,
    File? foto, // recibimos el archivo físico seleccionado desde la pantalla
  }) async {
    if (descripcion.trim().isEmpty) {
      _actualizarEstado(error: 'Por favor, escribe los detalles del problema.');
      return;
    }
    if (latitud == null || longitud == null) {
      _actualizarEstado(
        error: 'Por favor, marca el punto del problema en el mapa.',
      );
      return;
    }

    _actualizarEstado(cargando: true, error: null, exito: false);

    try {
      String? urlFinalDeLaFoto;

      // si la vista nos mandó una foto, la subimos primero al Storage
      if (foto != null) {
        urlFinalDeLaFoto = await _reporteRepo.subirFotoEvidencia(foto);
      }

      // Insertamos el reporte en la tabla de la base de datos con la URL
      await _reporteRepo.crearReporteCiudadano(
        idUsuario: idUsuario,
        descripcion: descripcion.trim(),
        latitud: latitud,
        longitud: longitud,
        evidenciaFotoUrl: urlFinalDeLaFoto,
      );

      _actualizarEstado(cargando: false, exito: true);
    } catch (e) {
      _actualizarEstado(cargando: false, error: e.toString());
    }
  }

  /// Lógica para procesar y enviar la incidencia del chofer
  Future<void> enviarIncidencia({
    required int idVehiculo,
    required String descripcion,
  }) async {
    if (descripcion.trim().isEmpty) {
      _actualizarEstado(error: 'Por favor, detalla la incidencia o percance.');
      return;
    }

    _actualizarEstado(cargando: true, error: null, exito: false);

    try {
      await _reporteRepo.crearIncidenciaChofer(
        idVehiculo: idVehiculo,
        descripcion: descripcion.trim(),
      );
      _actualizarEstado(cargando: false, exito: true);
    } catch (e) {
      _actualizarEstado(cargando: false, error: e.toString());
    }
  }

  void resetearEstados() {
    _operacionExitosa = false;
    _mensajeError = null;
    _estaCargando = false;
  }

  void _actualizarEstado({bool? cargando, String? error, bool? exito}) {
    if (cargando != null) _estaCargando = cargando;
    if (exito != null) _operacionExitosa = exito;
    _mensajeError = error;
    notifyListeners();
  }
}
