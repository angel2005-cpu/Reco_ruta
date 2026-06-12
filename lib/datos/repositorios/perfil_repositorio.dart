import 'package:supabase_flutter/supabase_flutter.dart';

class PerfilRepositorio {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Datos del ciudadano: nombre + usuario
  Future<Map<String, dynamic>> obtenerPerfilCiudadano(int idUsuario) async {
    final usuario = await _supabase
        .from('usuarios')
        .select('usuario')
        .eq('id_usuario', idUsuario)
        .single();

    final ciudadano = await _supabase
        .from('ciudadanos')
        .select('nombre, casa_latitud, casa_longitud')
        .eq('id_usuario', idUsuario)
        .single();

    return {
      'usuario': usuario['usuario'],
      'nombre': ciudadano['nombre'],
      'casa_latitud': ciudadano['casa_latitud'],
      'casa_longitud': ciudadano['casa_longitud'],
    };
  }

  /// Datos del chofer: nombre + placa + horario + sector
  Future<Map<String, dynamic>> obtenerPerfilChofer(int idUsuario) async {
    final usuario = await _supabase
        .from('usuarios')
        .select('usuario')
        .eq('id_usuario', idUsuario)
        .single();

    final chofer = await _supabase
        .from('choferes')
        .select('nombre, horario, sector_asignado, id_vehiculo')
        .eq('id_usuario', idUsuario)
        .single();

    // Obtener placa del vehículo asignado
    String placa = 'Sin vehículo';
    if (chofer['id_vehiculo'] != null) {
      final vehiculo = await _supabase
          .from('vehiculos')
          .select('placa')
          .eq('id_vehiculo', chofer['id_vehiculo'])
          .single();
      placa = vehiculo['placa'];
    }

    return {
      'usuario': usuario['usuario'],
      'nombre': chofer['nombre'],
      'horario': chofer['horario'] ?? 'No asignado',
      'sector': chofer['sector_asignado'] ?? 'No asignado',
      'placa': placa,
    };
  }
}
