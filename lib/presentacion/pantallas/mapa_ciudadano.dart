import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_application_camiones/datos/repositorios/perfil_repositorio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_camiones/presentacion/modelos_vista/ciudadano_modelo.dart';
import 'package:flutter_application_camiones/presentacion/modelos_vista/reporte_modelo.dart';
import 'package:flutter_application_camiones/datos/repositorios/reporte_repositorio.dart';
import 'package:flutter_application_camiones/datos/repositorios/vehiculo_repositorio.dart';
import 'componentes_ciudadano/mapa_monitoreo_section.dart';
import 'componentes_ciudadano/reportar_section.dart';
import 'componentes_ciudadano/perfil_section.dart';
import 'componentes_ciudadano/avisos_section.dart';

class MapaCiudadanoScreen extends StatefulWidget {
  const MapaCiudadanoScreen({super.key, required this.idUsuario});
  final int idUsuario;

  @override
  State<MapaCiudadanoScreen> createState() => _MapaCiudadanoScreenState();
}

Future<void> _iniciarMonitoreoSegundoPlano() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  final AndroidSettings configuracionAndroid = AndroidSettings(
    accuracy: LocationAccuracy.low,
    distanceFilter: 50, // solo actualiza cada 50m
    intervalDuration: const Duration(seconds: 30), // ← cada 30s
    foregroundNotificationConfig: const ForegroundNotificationConfig(
      notificationTitle: "Recoruta activo",
      notificationText: "Monitoreando el camión de basura en tu zona.",
      notificationIcon: AndroidResource(name: 'launcher_background'),
      enableWakeLock: true,
    ),
  );

  Geolocator.getPositionStream(locationSettings: configuracionAndroid).listen((
    _,
  ) {
    // se mantiene activo el servicio en segundo plano
  });
}

class _MapaCiudadanoScreenState extends State<MapaCiudadanoScreen> {
  int _currentIndex = 0;
  final MapController _mapController = MapController();
  final ReporteRepositorio _reporteRepo = ReporteRepositorio();
  final VehiculoRepositorio _vehiculoRepo = VehiculoRepositorio();

  final CiudadanoModeloVista _modeloVista = CiudadanoModeloVista();
  final ReporteModeloVista _reporteModelo = ReporteModeloVista();
  final TextEditingController _descripcionController = TextEditingController();
  final PerfilRepositorio _perfilRepo = PerfilRepositorio();
  Map<String, dynamic>? _perfilCiudadano;

  final LatLng _tantoyucaCentro = const LatLng(21.3510, -98.2285);

  // Estado de ubicación residencial de Supabase
  LatLng? _ubicacionCasaUsuario;
  int? _idUsuarioInterno;
  bool _cargandoCasa = true;
  bool _tieneCasaRegistrada =
      false; // Control de visualización del pin residencial

  // Coordenadas seleccionadas interactivamente para el reporte
  LatLng? _coordenadasReporte;
  File? _imagenSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarDomicilioDesdeSupabase();
    _iniciarMonitoreoSegundoPlano();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  /// Descarga las credenciales y el domicilio del ciudadano logueado
  Future<void> _cargarDomicilioDesdeSupabase() async {
    try {
      _idUsuarioInterno = widget.idUsuario; // ← directo, sin consulta extra

      final datosFila = await Supabase.instance.client
          .from('ciudadanos')
          .select('nombre, casa_latitud, casa_longitud')
          .eq('id_usuario', widget.idUsuario)
          .single();

      final double? lat = datosFila['casa_latitud'] != null
          ? (datosFila['casa_latitud'] as num).toDouble()
          : null;
      final double? lng = datosFila['casa_longitud'] != null
          ? (datosFila['casa_longitud'] as num).toDouble()
          : null;

      setState(() {
        if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
          _ubicacionCasaUsuario = LatLng(lat, lng);
          _tieneCasaRegistrada = true;
        } else {
          _ubicacionCasaUsuario = _tantoyucaCentro;
          _tieneCasaRegistrada = false;
        }
        _cargandoCasa = false;
      });

      // Cargar perfil para la sección de perfil
      final perfil = await _perfilRepo.obtenerPerfilCiudadano(widget.idUsuario);
      setState(() {
        _perfilCiudadano = perfil;
      });
    } catch (e) {
      debugPrint("Error al cargar domicilio: $e");
      setState(() {
        _ubicacionCasaUsuario = _tantoyucaCentro;
        _tieneCasaRegistrada = false;
        _cargandoCasa = false;
      });
    }
  }

  /// Fórmula de Haversine local
  double _calcularHaversineLocal(
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

  Future<void> _capturarEvidencia() async {
    final picker = image_picker.ImagePicker();
    final archivo = await picker.pickImage(
      source: image_picker.ImageSource.camera,
    );
    if (archivo != null) {
      setState(() {
        _imagenSeleccionada = File(archivo.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoCasa) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF2E7D32)),
              SizedBox(height: 16),
              Text(
                'Cargando mapa de Tantoyuca...',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Estructura de secciones
    final List<Widget> sections = [
      MapaMonitoreoSection(
        mapController: _mapController,
        vehiculoRepo: _vehiculoRepo,
        reporteRepo: _reporteRepo,
        centroMapa: _ubicacionCasaUsuario ?? _tantoyucaCentro,
        ubicacionCasaUsuario: _ubicacionCasaUsuario,
        tieneCasaRegistrada: _tieneCasaRegistrada,
        coordenadasReporte: _coordenadasReporte,
        idUsuario: widget.idUsuario,
        onTapMapa: (punto) {
          setState(() {
            _coordenadasReporte = punto;
          });
        },
        calcularHaversineLocal: _calcularHaversineLocal,
        onMostrarPanelCamiones: (context) => mostrarPanelCamiones(
          context: context,
          vehiculoRepo: _vehiculoRepo,
          mapController: _mapController,
        ),
      ),
      ReportarSection(
        reporteRepo: _reporteRepo,
        descripcionController: _descripcionController,
        coordenadasReporte: _coordenadasReporte,
        imagenSeleccionada: _imagenSeleccionada,
        idUsuarioInterno: _idUsuarioInterno,
        centroMapaSugerido: _ubicacionCasaUsuario ?? _tantoyucaCentro,
        onCapturarEvidencia: _capturarEvidencia,
        onUbicacionSeleccionada: (punto) {
          setState(() {
            _coordenadasReporte = punto;
          });
        },
        onReporteEnviado: () {
          setState(() {
            _imagenSeleccionada = null;
            _coordenadasReporte = null;
          });
        },
      ),
      IncidenciasSection(reporteRepo: _reporteRepo),
      PerfilSection(
        modeloVista: _modeloVista,
        perfilCiudadano: _perfilCiudadano,
        tieneCasaRegistrada: _tieneCasaRegistrada,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recoruta Ciudadano',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: IndexedStack(index: _currentIndex, children: sections),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() {
          _currentIndex = index;
        }),
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Monitoreo'),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Reportar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber_rounded),
            label: 'Incidencias',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Mi Perfil'),
        ],
      ),
    );
  }
}
