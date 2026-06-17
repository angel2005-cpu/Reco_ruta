import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_camiones/datos/repositorios/perfil_repositorio.dart';
import 'package:flutter_application_camiones/datos/repositorios/reporte_repositorio.dart';
import 'package:flutter_application_camiones/presentacion/modelos_vista/chofer_modelo.dart';
import 'package:flutter_application_camiones/presentacion/modelos_vista/reporte_modelo.dart';
import 'componentes_chofer/mapa_ruta_widget.dart';
import 'componentes_chofer/lista_reportes_widget.dart';
import 'componentes_chofer/formulario_incidencia_widget.dart';
import 'componentes_chofer/perfil_chofer_widget.dart';

class InterfazChoferScreen extends StatefulWidget {
  final int idUsuario;
  const InterfazChoferScreen({super.key, required this.idUsuario});

  @override
  State<InterfazChoferScreen> createState() => _InterfazChoferScreenState();
}

class _InterfazChoferScreenState extends State<InterfazChoferScreen> {
  Map<String, dynamic>? _perfilChofer;
  final PerfilRepositorio _perfilRepo = PerfilRepositorio();
  final MapController _mapController = MapController();
  int _currentIndex = 0;
  String _estadoCamion = "Disponible";
  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng? _ubicacionActualCamion;
  bool _rutaActiva = false;

  // guarda el reporte que el chofer seleccionó para ir a atender
  LatLng? _reporteDestinoVisual;

  final ChoferModeloVista _modeloVista = ChoferModeloVista();
  final ReporteRepositorio _reporteRepo = ReporteRepositorio();
  final ReporteModeloVista _reporteModelo = ReporteModeloVista();
  final TextEditingController _incidenciaController = TextEditingController();

  final LatLng _tantoyucaCentro = const LatLng(21.3510, -98.2285);

  @override
  void initState() {
    super.initState();
    _modeloVista.addListener(_onViewModelChange);
    _reporteModelo.addListener(_onReporteStateChange);
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final perfil = await _perfilRepo.obtenerPerfilChofer(widget.idUsuario);
    setState(() {
      _perfilChofer = perfil;
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _modeloVista.removeListener(_onViewModelChange);
    _reporteModelo.removeListener(_onReporteStateChange);
    _modeloVista.dispose();
    _reporteModelo.dispose();
    _incidenciaController.dispose();
    super.dispose();
  }

  void _onViewModelChange() {
    if (!mounted) return;
    if (_modeloVista.mensajeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_modeloVista.mensajeError!),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (_modeloVista.estaTransmitiendo && !_rutaActiva) {
      _iniciarRastreoGPS();
    } else if (!_modeloVista.estaTransmitiendo && _rutaActiva) {
      _detenerRastreoGPS();
    }

    setState(() {
      if (_modeloVista.estaTransmitiendo) {
        _estadoCamion = 'En Ruta';
      } else if (_estadoCamion == 'En Ruta') {
        _estadoCamion = 'Disponible';
      }
    });
  }

  Future<void> _iniciarRastreoGPS() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Se requieren permisos de ubicación para iniciar la ruta.',
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      _rutaActiva = true;
    });

    try {
      Position posicionInicial = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final coordenadaInicial = LatLng(
        posicionInicial.latitude,
        posicionInicial.longitude,
      );

      setState(() {
        _ubicacionActualCamion = coordenadaInicial;
      });
      _mapController.move(coordenadaInicial, 16.0);

      await _modeloVista.actualizarUbicacionVehiculo(
        idVehiculo: widget.idUsuario,
        latitud: posicionInicial.latitude,
        longitud: posicionInicial.longitude,
      );
    } catch (e) {
      debugPrint("Aviso: Esperando señal del flujo de GPS continuo...");
    }

    final AndroidSettings configuracionAndroid = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      forceLocationManager: false,
      intervalDuration: const Duration(seconds: 5),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: "Ruta Activa - Reco_ruta",
        notificationText:
            "Compartiendo la ubicación del camión en tiempo real.",
        notificationIcon: AndroidResource(name: 'launcher_background'),
        enableWakeLock: true,
      ),
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: configuracionAndroid,
        ).listen((Position position) {
          final nuevaCoordenada = LatLng(position.latitude, position.longitude);

          if (!mounted) return;
          setState(() {
            _ubicacionActualCamion = nuevaCoordenada;
          });

          if (_reporteDestinoVisual == null) {
            _mapController.move(nuevaCoordenada, 16.0);
          }

          try {
            _modeloVista.actualizarUbicacionVehiculo(
              idVehiculo: widget.idUsuario,
              latitud: position.latitude,
              longitud: position.longitude,
            );
          } catch (e) {
            debugPrint("Error al enviar coordenadas: $e");
          }
        });
  }

  void _detenerRastreoGPS() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    setState(() {
      _rutaActiva = false;
      _ubicacionActualCamion = null;
      _reporteDestinoVisual = null;
    });
  }

  void _onReporteStateChange() {
    if (!mounted) return;

    if (_reporteModelo.mensajeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_reporteModelo.mensajeError!),
          backgroundColor: Colors.red,
        ),
      );
      _reporteModelo.resetearEstados();
    }

    if (_reporteModelo.operacionExitosa) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incidencia vial registrada con éxito'),
          backgroundColor: Colors.green,
        ),
      );
      _incidenciaController.clear();
      _reporteModelo.resetearEstados();
      setState(() {
        _currentIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      MapaRutaWidget(
        mapController: _mapController,
        ubicacionActualCamion: _ubicacionActualCamion,
        reporteDestinoVisual: _reporteDestinoVisual,
        tantoyucaCentro: _tantoyucaCentro,
        estadoCamion: _estadoCamion,
        estaTransmitiendo: _modeloVista.estaTransmitiendo,
        onEstadoCamionChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _estadoCamion = newValue;
            });
            if (newValue == 'En Ruta') {
              if (!_modeloVista.estaTransmitiendo) {
                _modeloVista.iniciarRuta(widget.idUsuario);
              }
            } else {
              _modeloVista.detenerRuta(widget.idUsuario, estadoFinal: newValue);
            }
          }
        },
        onToggleRuta: () {
          if (_modeloVista.estaTransmitiendo) {
            _modeloVista.detenerRuta(
              widget.idUsuario,
              estadoFinal: 'Disponible',
            );
          } else {
            _modeloVista.iniciarRuta(widget.idUsuario);
          }
        },
        onClearDestino: () {
          setState(() {
            _reporteDestinoVisual = null;
          });
          if (_ubicacionActualCamion != null) {
            _mapController.move(_ubicacionActualCamion!, 16.0);
          }
        },
      ),
      ListaReportesWidget(
        reporteRepo: _reporteRepo,
        idUsuario: widget.idUsuario,
        esDestinoActual: (lat) => _reporteDestinoVisual?.latitude == lat,
        onReporteAtendido: (nuevoDestino) {
          setState(() {
            _reporteDestinoVisual = nuevoDestino;
          });
        },
        onVerEnMapa: (lat, lng) {
          setState(() {
            _reporteDestinoVisual = LatLng(lat, lng);
            _currentIndex = 0;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(_reporteDestinoVisual!, 16.0);
          });
        },
      ),
      FormularioIncidenciaWidget(
        controller: _incidenciaController,
        idUsuario: widget.idUsuario,
        onEnviarIncidencia: (descripcion) {
          _reporteModelo.enviarIncidencia(
            idVehiculo: widget.idUsuario,
            descripcion: descripcion,
          );
        },
      ),
      PerfilChoferWidget(
        perfilChofer: _perfilChofer,
        onCerrarSesion: () {
          _modeloVista.detenerRuta(widget.idUsuario, estadoFinal: 'Disponible');
          Navigator.pushReplacementNamed(context, '/login');
        },
      ),
    ];

    final List<String> titles = [
      'Recoruta Chofer - Mapa y Estado',
      'Reportes Ciudadanos',
      'Registrar Incidencia',
      'Mi Perfil y Horario',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() {
          _currentIndex = index;
        }),
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: 'Ruta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Atender',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_gmailerrorred),
            label: 'Incidencias',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
