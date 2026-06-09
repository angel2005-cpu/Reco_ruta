import 'package:supabase_flutter/supabase_flutter.dart';

class VehiculoRepositorio {
  final SupabaseClient _supabase = Supabase.instance.client;

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
    } catch (e) {
      throw Exception('Error al transmitir ubicación: $e');
    }
  }

  /// para el ciudadano escucha la tabla de vehículos en tiempo real
  /// Esto genera un Stream que Flutter puede leer para mover el marcador en el mapa
  Stream<List<Map<String, dynamic>>> escucharCamionesEnTiempoReal() {
    return _supabase.from('vehiculos').stream(primaryKey: ['id_vehiculo']);
  }
}
