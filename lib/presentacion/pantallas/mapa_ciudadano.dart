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

  // Control dinámico de hogar desde Supabase
  LatLng? _ubicacionCasaUsuario;
  int? _idUsuarioInterno;
  bool _cargandoCasa = true;
  bool _tieneCasaRegistrada =
      false; // bandera de control para limpiar el centro del mapa

  // Coordenadas manuales elegidas por el usuario para su reporte
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

  /// 🛰️ Consulta la cuenta del usuario para extraer el ID y su hogar si existe
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
            if (datosFila['latitud_casa'] != null &&
                datosFila['longitud_casa'] != null) {
              _ubicacionCasaUsuario = LatLng(
                (datosFila['latitud_casa'] as num).toDouble(),
                (datosFila['longitud_casa'] as num).toDouble(),
              );
              _tieneCasaRegistrada = true; // Solo activamos si hay datos reales
            }
            _cargandoCasa = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error al mapear credenciales desde Supabase: $e");
    }

    setState(() {
      _idUsuarioInterno = 1;
      _ubicacionCasaUsuario = _tantoyucaCentro;
      _tieneCasaRegistrada = false; // Desactivado si falla o no tiene registro
      _cargandoCasa = false;
    });
  }

  /// 📐 Geometría esférica de Haversine para la métrica crítica de 100m
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

  /// ✨ Disparador asíncronico para enviar el reporte con el ID correcto de usuario
  Future<void> _procesarEnvioReporte() async {
    if (_descripcionController.text.trim().isEmpty ||
        _coordenadasReporte == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, escribe una descripción y toca el mapa para fijar el lugar.',
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
          content: Text('¡Reporte enviado con éxito a la central!'),
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
          content: Text('Error al guardar reporte en Supabase'),
          backgroundColor: Colors.red,
        ),
      );
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
              SizedBox(height: 18),
              Text(
                'Sincronizando entorno de mapas...',
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
      body: Stack(
        children: [
          // 🗺️ CAPA BASE: El mapa se mantiene fijo de fondo (Evita parpadeos y destrucción)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _ubicacionCasaUsuario ?? _tantoyucaCentro,
              initialZoom: 15.0,
              onTap: (tapPosition, point) {
                // 📍 SELECCIÓN MANUAL ANTIGUA: Al hacer tap se actualiza el pin del reporte
                setState(() {
                  _coordenadasReporte = point;
                });
                if (_currentIndex == 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '📍 Punto geográfico del percance marcado.',
                      ),
                    ),
                  );
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.recoruta.app',
              ),

              // 🚚 FLUJO REACTIVO EXCLUSIVO DE MARCADORES (Garantiza visualización de camiones)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _vehiculoRepo.escucharCamionesEnRuta(),
                builder: (context, snapshot) {
                  final camionesActivos = snapshot.data ?? [];
                  List<Marker> marcadoresRender = [];

                  // 🏠 Dibuja la casa del ciudadano ÚNICAMENTE si está validada en la BD
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

                  // 🚨 Dibuja el Pin Rojo del Reporte Manual si el usuario ya tocó el mapa
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

                  // Recorremos y calculamos distancias para las alertas
                  double distanciaMinima = double.infinity;
                  Map<String, dynamic>? camionMasCercano;

                  for (var camion in camionesActivos) {
                    final double lat = (camion['latitud'] as num).toDouble();
                    final double lng = (camion['longitud'] as num).toDouble();
                    final LatLng posicionCamion = LatLng(lat, lng);

                    if (_tieneCasaRegistrada && _ubicacionCasaUsuario != null) {
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

                    // Añadir icono verde flotante del camión recolector
                    marcadoresRender.add(
                      Marker(
                        point: posicionCamion,
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

                  return Stack(
                    children: [
                      MarkerLayer(markers: marcadoresRender),

                      // 🔔 Notificación a los 100 metros dinámicos
                      if (distanciaMinima <= 100 && camionMasCercano != null)
                        _buildAlertaProximidadFlotante(
                          idVehiculo: camionMasCercano!['id_vehiculo'],
                          distancia: distanciaMinima.toInt(),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),

          // 🎛️ CAPAS ADICIONALES SUPERPUESTAS DEPENDIENDO DE LA PESTAÑA ACTIVA
          if (_currentIndex == 0) ...[
            _buildIncidenciasStreamBanner(),
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

          if (_currentIndex == 1)
            _buildFormularioReporteTarjeta(), // 📝 Panel flotante sobre el mapa para selección manual

          if (_currentIndex == 2)
            Container(
              color: Colors.white,
              child: _buildPerfilSection(),
            ), // Panel limpio de perfil
        ],
      ),
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

  /// 📝 Formulario Flotante que permite visualizar el mapa al mismo tiempo para tocar y seleccionar
  Widget _buildFormularioReporteTarjeta() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 20,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Generar Reporte de Basura o Vialidad',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '📍 Toca cualquier parte del mapa para fijar el lugar exacto.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_coordenadasReporte != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Punto seleccionado: (${_coordenadasReporte!.latitude.toStringAsFixed(5)}, ${_coordenadasReporte!.longitude.toStringAsFixed(5)})',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe el problema vial o desperdicios aquí...',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _capturarEvidencia,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: Text(
                        _imagenSeleccionada != null
                            ? 'Foto Adjunta ✓'
                            : 'Evidencia',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _procesarEnvioReporte,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ENVIAR REPORTE',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
                      'La unidad #$idVehiculo está a solo $distancia metros de tu domicilio registrado. ¡Saca tus contenedores!',
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
              ultimaIncidencia['descripcion'] ?? 'Fallo mecánico';
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

  Widget _buildPerfilSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
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
