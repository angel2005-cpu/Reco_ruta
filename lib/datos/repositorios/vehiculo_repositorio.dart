import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehiculoRepositorio {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Distancia mínima (en metros) que debe recorrer el camión antes de
  /// guardar un nuevo punto en el historial de recorrido. Evita llenar
  /// la tabla 'historial_ubicaciones' con puntos casi idénticos.
  static const double _distanciaMinimaHistorialMetros = 20;

  /// Última posición conocida para la que ya se registró un punto de
  /// historial, por vehículo. Se usa en memoria para comparar antes de
  /// insertar un nuevo punto.
  final Map<int, _Punto> _ultimoPuntoHistorial = {};

  /// actualiza las coordenadas del camión en Supabase
  Future<void> actualizarUbicacionCamion({
    required int idVehiculo,
    required double latitud,
    required double longitud,
  }) async {
    try {
      await _supabase
          .from('vehiculos')
          .update({
            'latitud': latitud,
            'longitud': longitud,
            'ultima_actualizacion': DateTime.now().toIso8601String(),
          })
          .eq('id_vehiculo', idVehiculo);

      await _registrarPuntoHistorialSiAplica(
        idVehiculo: idVehiculo,
        latitud: latitud,
        longitud: longitud,
      );

      // Registramos el punto en el historial de recorrido, solo si el
      // camión se movió al menos _distanciaMinimaHistorialMetros desde
      // el último punto guardado (para no saturar la tabla).
    } catch (e) {
      throw Exception('Error al transmitir ubicación: $e');
    }
  }

  Future<void> registrarInspeccionVehiculo({
    required int idVehiculo,
    required int idChofer,
    required String tipoRegistro,
    required double kilometraje,
    required String nivelCombustible,
    required String estadoMecanico,
    required String urlFotoTablero,
    String? observaciones,
  }) async {
    try {
      await Supabase.instance.client.from('inspecciones_vehiculos').insert({
        'id_vehiculo': idVehiculo,
        'id_chofer': idChofer,
        'tipo_registro': tipoRegistro,
        'kilometraje': kilometraje,
        'nivel_combustible': nivelCombustible,
        'estado_mecanico': estadoMecanico,
        'foto_tablero': urlFotoTablero,
        'observaciones': observaciones ?? 'Sin observaciones',
      });
    } catch (e) {
      throw Exception('Error al guardar la inspección: $e');
    }
  }

  /// Inserta un punto en 'historial_ubicaciones' si la distancia desde el
  /// último punto registrado supera el umbral mínimo.
  Future<void> _registrarPuntoHistorialSiAplica({
    required int idVehiculo,
    required double latitud,
    required double longitud,
  }) async {
    final ultimo = _ultimoPuntoHistorial[idVehiculo];

    if (ultimo != null) {
      final double distancia = _calcularHaversine(
        ultimo.latitud,
        ultimo.longitud,
        latitud,
        longitud,
      );
      if (distancia < _distanciaMinimaHistorialMetros) {
        return; // Aún no se movió lo suficiente, no registramos punto
      }
    }

    try {
      await _supabase.from('historial_ubicaciones').insert({
        'id_vehiculo': idVehiculo,
        'latitud': latitud,
        'longitud': longitud,
      });
      _ultimoPuntoHistorial[idVehiculo] = _Punto(latitud, longitud);
    } catch (e) {
      // No interrumpimos la actualización principal de ubicación si
      // falla el registro del historial; solo lo registramos en consola.
      // (El recorrido del panel admin simplemente tendrá un hueco).
      // ignore: avoid_print
      print('Error al registrar punto de historial: $e');
    }
  }

  /// Fórmula de Haversine: distancia en metros entre dos coordenadas.
  double _calcularHaversine(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double radioTierraMetros = 6371000;
    final double dLat = (lat2 - lat1) * pi / 180;
    final double dLon = (lon2 - lon1) * pi / 180;

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radioTierraMetros * c;
  }

  /// para el ciudadano escucha la tabla de vehículos en tiempo real
  /// Esto genera un Stream que Flutter puede leer para mover el marcador en el mapa
  Stream<List<Map<String, dynamic>>> escucharCamionesEnTiempoReal() {
    return _supabase.from('vehiculos').stream(primaryKey: ['id_vehiculo']);
  }

  Future<void> actualizarEstadoVehiculo({
    required int idVehiculo,
    required String nuevoEstado,
  }) async {
    await _supabase
        .from('vehiculos')
        .update({'estado': nuevoEstado})
        .eq('id_vehiculo', idVehiculo);
  }

  Stream<List<Map<String, dynamic>>> escucharCamionesEnRuta() {
    return _supabase
        .from('vehiculos')
        .stream(primaryKey: ['id_vehiculo'])
        .eq('estado', 'En Ruta'); // solo muestra camiones en estado activo
  }
}

/// Par de coordenadas simple usado para comparar distancias en memoria.
class _Punto {
  const _Punto(this.latitud, this.longitud);
  final double latitud;
  final double longitud;
}
