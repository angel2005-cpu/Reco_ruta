import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_camiones/presentacion/modelos_vista/ciudadano_modelo.dart';
import 'package:flutter_application_camiones/presentacion/modelos_vista/reporte_modelo.dart';
import 'package:flutter_application_camiones/datos/repositorios/reporte_repositorio.dart';
import 'package:flutter_application_camiones/datos/repositorios/vehiculo_repositorio.dart';

class MapaCiudadanoScreen extends StatefulWidget {
  const MapaCiudadanoScreen({super.key});

  @override
  State<MapaCiudadanoScreen> createState() => _MapaCiudadanoScreenState();
}

class _MapaCiudadanoScreenState extends State<MapaCiudadanoScreen> {
  int _currentIndex = 0;
  final MapController _mapController = MapController();
  final ReporteRepositorio _reporteRepo = ReporteRepositorio();
  final VehiculoRepositorio _vehiculoRepo = VehiculoRepositorio();

  final CiudadanoModeloVista _modeloVista = CiudadanoModeloVista();
  final ReporteModeloVista _reporteModelo = ReporteModeloVista();
  final TextEditingController _descripcionController = TextEditingController();

  final LatLng _tantoyucaCentro = const LatLng(21.3510, -98.2285);

  // Estado de ubicación residencial de Supabase
  LatLng? _ubicacionCasaUsuario;
  int? _idUsuarioInterno;
  bool _cargandoCasa = true;
  bool _tieneCasaRegistrada =
      false; // 🏠 Control de visualización del pin residencial

  // Coordenadas seleccionadas interactivamente para el reporte
  LatLng? _coordenadasReporte;
  File? _imagenSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarDomicilioDesdeSupabase();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  /// 🛰️ Descarga las credenciales y el domicilio del ciudadano logueado
  Future<void> _cargarDomicilioDesdeSupabase() async {
    try {
      final usuarioLogueado = Supabase.instance.client.auth.currentUser;
      if (usuarioLogueado != null && usuarioLogueado.email != null) {
        final datosFila = await Supabase.instance.client
            .from('usuarios')
            .select('id_usuario, latitud_casa, longitud_casa')
            .eq('correo', usuarioLogueado.email!)
            .maybeSingle();

        if (datosFila != null) {
          setState(() {
            _idUsuarioInterno = datosFila['id_usuario'] as int?;
            final double? lat = datosFila['latitud_casa'] != null
                ? (datosFila['latitud_casa'] as num).toDouble()
                : null;
            final double? lng = datosFila['longitud_casa'] != null
                ? (datosFila['longitud_casa'] as num).toDouble()
                : null;

            if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
              _ubicacionCasaUsuario = LatLng(lat, lng);
              _tieneCasaRegistrada =
                  true; // Solo se activa si las coordenadas no son nulas ni ceros
            } else {
              _ubicacionCasaUsuario = _tantoyucaCentro;
              _tieneCasaRegistrada = false;
            }
            _cargandoCasa = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error al consultar datos residenciales en Supabase: $e");
    }

    setState(() {
      _idUsuarioInterno = 1;
      _ubicacionCasaUsuario = _tantoyucaCentro;
      _tieneCasaRegistrada = false;
      _cargandoCasa = false;
    });
  }

  /// 📐 Fórmula de Haversine local (Métrica rigurosa de 100 metros)
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

    // Estructura original de secciones independientes por pestaña
    final List<Widget> sections = [
      _buildMapaSection(),
      _buildReportarSection(),
      _buildPerfilSection(),
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Mi Perfil'),
        ],
      ),
    );
  }

  /// 🗺️ PESTAÑA 0: Sección Monitoreo (Mapa Completo con capa Realtime aislada)
  Widget _buildMapaSection() {
    final LatLng centroMapa = _ubicacionCasaUsuario ?? _tantoyucaCentro;

    return Stack(
      children: [
        // El mapa base se renderiza de forma estática en el fondo para preservar la cámara al mover o hacer zoom
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: centroMapa,
            initialZoom: 15.0,
            onTap: (tapPosition, point) {
              // 📍 SELECCIÓN MANUAL ORIGINAL: Al tocar cualquier calle se actualiza el punto geográfico
              setState(() {
                _coordenadasReporte = point;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '📍 Punto marcado: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}. Pasa a la pestaña "Reportar".',
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.recoruta.app',
            ),

            // 🚚 CAPA EXCLUSIVA DE MARCADORES: Solo esta capa se redibuja con Supabase Realtime
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _vehiculoRepo.escucharCamionesEnRuta(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint(
                    "Error crítico en stream de camiones: ${snapshot.error}",
                  );
                }

                final camionesActivos = snapshot.data ?? [];
                List<Marker> marcadoresRender = [];

                // 1. Añadimos la casa SÓLO si tiene coordenadas reales registradas en Supabase
                if (_tieneCasaRegistrada && _ubicacionCasaUsuario != null) {
                  marcadoresRender.add(
                    Marker(
                      point: _ubicacionCasaUsuario!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.home,
                        color: Colors.blueAccent,
                        size: 38,
                      ),
                    ),
                  );
                }

                // 2. Añadimos el Pin Rojo del reporte si el usuario ya tocó el mapa
                if (_coordenadasReporte != null) {
                  marcadoresRender.add(
                    Marker(
                      point: _coordenadasReporte!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 42,
                      ),
                    ),
                  );
                }

                // 3. Añadimos los camiones activos controlando estrictamente datos nulos
                for (var camion in camionesActivos) {
                  if (camion['latitud'] == null || camion['longitud'] == null)
                    continue;

                  final double lat = (camion['latitud'] as num).toDouble();
                  final double lng = (camion['longitud'] as num).toDouble();

                  marcadoresRender.add(
                    Marker(
                      point: LatLng(lat, lng),
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 6),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          color: Color(0xFF2E7D32),
                          size: 28,
                        ),
                      ),
                    ),
                  );
                }

                return MarkerLayer(markers: marcadoresRender);
              },
            ),
          ],
        ),

        // 🔔 ALERTA DE PROXIMIDAD INMEDIATA (100 METROS)
        // Usa su propio StreamBuilder flotante para no interferir con las operaciones de la cámara del mapa
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _vehiculoRepo.escucharCamionesEnRuta(),
          builder: (context, snapshot) {
            final camiones = snapshot.data ?? [];
            if (camiones.isEmpty ||
                !_tieneCasaRegistrada ||
                _ubicacionCasaUsuario == null) {
              return const SizedBox.shrink();
            }

            double distanciaMinima = double.infinity;
            Map<String, dynamic>? camionMasCercano;

            for (var camion in camiones) {
              if (camion['latitud'] == null || camion['longitud'] == null)
                continue;
              final double lat = (camion['latitud'] as num).toDouble();
              final double lng = (camion['longitud'] as num).toDouble();

              final double dist = _calcularHaversineLocal(
                _ubicacionCasaUsuario!.latitude,
                _ubicacionCasaUsuario!.longitude,
                lat,
                lng,
              );

              if (dist < distanciaMinima) {
                distanciaMinima = dist;
                camionMasCercano = camion;
              }
            }

            if (distanciaMinima <= 100 && camionMasCercano != null) {
              return _buildAlertaProximidadFlotante(
                idVehiculo: camionMasCercano['id_vehiculo'],
                distancia: distanciaMinima.toInt(),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // 🚨 BANNER DE INCIDENCIAS MECÁNICAS O DE TRÁFICO
        _buildIncidenciasStreamBanner(),

        // 📋 BOTÓN PARA DESPLEGAR PANEL DE UNIDADES ONLINE
        Positioned(
          bottom: 24,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'fab_camiones_online',
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.commute),
            label: const Text(
              'Camiones Activos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => _mostrarPanelCamiones(context),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertaProximidadFlotante({
    required int idVehiculo,
    required int distancia,
  }) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        color: const Color(0xFFE8F5E9),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF2E7D32),
                child: Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¡Camión aproximándose!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'La unidad #$idVehiculo está a solo $distancia metros de tu domicilio. ¡Saca tus contenedores!',
                      style: const TextStyle(fontSize: 12, height: 1.2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncidenciasStreamBanner() {
    return Positioned(
      top: 115,
      left: 16,
      right: 16,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _reporteRepo.escucharIncidenciasActivas(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return const SizedBox.shrink();

          final ultimaIncidencia = snapshot.data!.first;
          final String desc =
              ultimaIncidencia['descripcion'] ?? 'Percance en la vialidad';
          final int idVehiculo = ultimaIncidencia['id_vehiculo'] ?? 1;

          return Card(
            color: Colors.red[900],
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aviso del Camión #$idVehiculo: $desc',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 📝 PESTAÑA 1: Interfaz Original de Envío de Reportes
  Widget _buildReportarSection() {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generar Reporte Ciudadano',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Describe el desperfecto o problema con la ruta de recolección.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Indicador de estado geográfico del pin seleccionado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _coordenadasReporte == null
                    ? Colors.amber[50]
                    : Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _coordenadasReporte == null
                      ? Colors.amber
                      : Colors.blue,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _coordenadasReporte == null
                        ? Icons.info_outline
                        : Icons.check_circle_outline,
                    color: _coordenadasReporte == null
                        ? Colors.orange[800]
                        : Colors.blue[800],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _coordenadasReporte == null
                          ? 'Falta seleccionar ubicación. Ve a la pestaña Monitoreo y toca el mapa.'
                          : 'Ubicación fijada: (${_coordenadasReporte!.latitude.toStringAsFixed(5)}, ${_coordenadasReporte!.longitude.toStringAsFixed(5)})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _coordenadasReporte == null
                            ? Colors.orange[900]
                            : Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _descripcionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Escribe detalladamente las observaciones aquí (ej. Contenedores desbordados, camión omitió la calle)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: _capturarEvidencia,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.camera_alt, color: Colors.blueGrey),
              label: Text(
                _imagenSeleccionada != null
                    ? 'Evidencia Adjuntada ✓'
                    : 'Tomar Foto de Evidencia',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 35),

            ElevatedButton(
              onPressed: () async {
                if (_descripcionController.text.trim().isEmpty ||
                    _coordenadasReporte == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Por favor, ingresa la descripción y marca un punto en el mapa.',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                try {
                  await _reporteRepo.crearReporteCiudadano(
                    idUsuario: _idUsuarioInterno ?? 1,
                    descripcion: _descripcionController.text.trim(),
                    latitud: _coordenadasReporte!.latitude,
                    longitud: _coordenadasReporte!.longitude,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '¡Reporte enviado exitosamente a la central!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _descripcionController.clear();
                  setState(() {
                    _imagenSeleccionada = null;
                    _coordenadasReporte = null;
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Error al transmitir el reporte a Supabase',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'ENVIAR REPORTE CIUDADANO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 👤 PESTAÑA 2: Sección Perfil
  Widget _buildPerfilSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 30),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, size: 60, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          const Card(
            child: ListTile(
              leading: Icon(Icons.account_circle, color: Color(0xFF2E7D32)),
              title: Text('Nombre de Usuario'),
              subtitle: Text('Ciudadano Autenticado'),
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {
              _modeloVista.detenerEscucha();
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _mostrarPanelCamiones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unidades en Servicio Activo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _vehiculoRepo.escucharCamionesEnRuta(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'No hay camiones de basura en ruta por ahora.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      final lista = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: lista.length,
                        itemBuilder: (context, index) {
                          final unCamion = lista[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.local_shipping,
                              color: Color(0xFF2E7D32),
                            ),
                            title: Text(
                              'Camión Recolector #${unCamion['id_vehiculo']}',
                            ),
                            subtitle: Text('Estatus: ${unCamion['estado']}'),
                            trailing: const Icon(
                              Icons.gps_fixed,
                              color: Colors.blue,
                            ),
                            onTap: () {
                              final double lat = (unCamion['latitud'] as num)
                                  .toDouble();
                              final double lng = (unCamion['longitud'] as num)
                                  .toDouble();
                              _mapController.move(LatLng(lat, lng), 16.0);
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
