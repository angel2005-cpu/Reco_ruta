import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_camiones/datos/repositorios/vehiculo_repositorio.dart';
import 'package:latlong2/latlong.dart';

class CiudadanoModeloVista extends ChangeNotifier {
  final VehiculoRepositorio _vehiculoRepo = VehiculoRepositorio();
  StreamSubscription<List<Map<String, dynamic>>>? _vehiculosSubscription;
  final SupabaseClient _supabase = Supabase.instance.client;
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

  LatLng? _ubicacionCasa;
  LatLng? get ubicacionCasa => _ubicacionCasa;

  bool _cargando = true;
  bool get cargando => _cargando;

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

  Future<void> cargarUbicacionDomicilio() async {
    try {
      _cargando = true;
      _mensajeError = null;
      notifyListeners();

      final usuarioActual = _supabase.auth.currentUser;
      if (usuarioActual == null) {
        _mensajeError = "Sesión no válida o expirada.";
        _cargando = false;
        notifyListeners();
        return;
      }

      // Consulta directa a tu tabla de usuarios/perfiles
      final datos = await _supabase
          .from(
            'usuarios',
          ) // ajusta al nombre exacto de tu tabla si es diferente
          .select(
            'latitud_casa, longitud_casa',
          ) // Columnas que guardó el usuario al registrarse
          .eq('id_usuario', usuarioActual.id)
          .single();

      if (datos['latitud_casa'] != null && datos['longitud_casa'] != null) {
        _ubicacionCasa = LatLng(
          (datos['latitud_casa'] as num).toDouble(),
          (datos['longitud_casa'] as num).toDouble(),
        );
      } else {
        _mensajeError = "No tienes una ubicación de casa registrada.";
      }
    } catch (e) {
      _mensajeError = "Error de conexión al recuperar tu domicilio.";
      debugPrint("Error en cargarUbicacionDomicilio: $e");
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
