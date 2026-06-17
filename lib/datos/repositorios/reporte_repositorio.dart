import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReporteRepositorio {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> subirFotoEvidencia(File archivoImagen) async {
    try {
      // se genera un nombre único basado en los milisegundos del sistema para evitar colisiones
      final String nombreArchivo =
          '${DateTime.now().millisecondsSinceEpoch}.jpg';

      // subimos el archivo al bucket 'evidencias'
      await _supabase.storage
          .from('evidencias')
          .upload(
            nombreArchivo,
            archivoImagen,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Solicitamos la URL pública definitiva del archivo subido
      final String urlPublica = _supabase.storage
          .from('evidencias')
          .getPublicUrl(nombreArchivo);
      return urlPublica;
    } catch (e) {
      throw Exception('Error al subir la imagen al servidor: $e');
    }
  }

  /// ciudadano inserta un nuevo reporte en la base de datos
  Future<void> crearReporteCiudadano({
    required int idUsuario,
    required String descripcion,
    required double latitud,
    required double longitud,
    String? evidenciaFotoUrl,
  }) async {
    try {
      await _supabase.from('reportes_ciudadanos').insert({
        'id_usuario': idUsuario,
        'descripcion': descripcion,
        'latitud': latitud,
        'longitud': longitud,
        'evidencia_foto': evidenciaFotoUrl,
      });
    } catch (e) {
      throw Exception('Error al enviar el reporte: $e');
    }
  }

  /// el chofer escucha los reportes ciudadanos activos en tiempo real
  Stream<List<Map<String, dynamic>>> escucharReportesCiudadanos() {
    return _supabase
        .from('reportes_ciudadanos')
        .stream(primaryKey: ['id_reporte'])
        .order('fecha', ascending: false);
  }

  /// el chofer cambia el estado del reporte de 'Pendiente' a 'Atendido'
  /// el chofer cambia el estado del reporte de 'Pendiente' a 'Atendido' y guarda quién lo atendió
  Future<void> marcarReporteComoAtendido({
    required int idReporte,
    required int idChofer,
  }) async {
    try {
      await _supabase
          .from('reportes_ciudadanos')
          .update({
            'estado': 'Atendido',
            'id_chofer': idChofer, // se guarda el ID del chofer
          })
          .eq('id_reporte', idReporte);
    } catch (e) {
      throw Exception('Error al actualizar el reporte: $e');
    }
  }

  /// el chofer registra un percance de ruta en la tabla incidencias
  Future<void> crearIncidenciaChofer({
    required int idVehiculo,
    required String descripcion,
  }) async {
    try {
      await _supabase.from('incidencias').insert({
        'id_vehiculo': idVehiculo,
        'descripcion': descripcion,
      });
    } catch (e) {
      throw Exception('Error al registrar la incidencia: $e');
    }
  }

  // escuchar incidencias del camion
  Stream<List<Map<String, dynamic>>> escucharIncidenciasActivas() {
    return _supabase
        .from('incidencias') // nombre de la tabla
        .stream(primaryKey: ['id_incidencia'])
        .order('fecha_hora', ascending: false) // Trae las más recientes primero
        .limit(20); // historial reciente de incidencias
  }
}
