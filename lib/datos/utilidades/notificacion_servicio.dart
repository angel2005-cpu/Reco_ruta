import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_application_camiones/datos/repositorios/notificacion_repositorio.dart';

class NotificacionServicio {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _yaNotificado = false;
  static final NotificacionRepositorio _repo = NotificacionRepositorio();

  static Future<void> inicializar() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  static Future<void> notificarCamionCerca({required int idUsuario}) async {
    if (_yaNotificado) return;
    _yaNotificado = true;

    // Guardar en Supabase
    await _repo.enviarNotificacionCamionCerca(idUsuario: idUsuario);

    // Mostrar en el dispositivo
    await _plugin.show(
      0,
      '🚛 ¡El camión está cerca!',
      'El camión de basura pasará en unos minutos por tu zona.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'camion_cerca',
          'Camión cercano',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );

    // Resetear después de 10 min para no hacer spam
    Future.delayed(const Duration(minutes: 10), () {
      _yaNotificado = false;
    });
  }
}
