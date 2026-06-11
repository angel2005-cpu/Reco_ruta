import 'package:supabase_flutter/supabase_flutter.dart';

class NotificacionRepositorio {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Guarda la notificación en Supabase Y la muestra en el dispositivo
  Future<void> enviarNotificacionCamionCerca({required int idUsuario}) async {
    await _supabase.from('notificaciones').insert({
      'titulo': '🚛 ¡El camión está cerca!',
      'mensaje': 'El camión de basura pasará en unos minutos por tu zona.',
      'id_usuario': idUsuario,
    });
  }

  /// Para mostrar el historial de notificaciones al ciudadano
  Future<List<Map<String, dynamic>>> obtenerNotificaciones({
    required int idUsuario,
  }) async {
    return await _supabase
        .from('notificaciones')
        .select()
        .eq('id_usuario', idUsuario)
        .order('fecha_envio', ascending: false)
        .limit(20);
  }
}
