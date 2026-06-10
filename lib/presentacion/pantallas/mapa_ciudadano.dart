import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_camiones/presentacion/modelos_vista/ciudadano_modelo.dart';
import 'package:flutter_application_camiones/presentacion/modelos_vista/reporte_modelo.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart' as image_picker;

class MapaCiudadanoScreen extends StatefulWidget {
  const MapaCiudadanoScreen({super.key});

  @override
  State<MapaCiudadanoScreen> createState() => _MapaCiudadanoScreenState();
}

class _MapaCiudadanoScreenState extends State<MapaCiudadanoScreen> {
  int _currentIndex = 0;
  final MapController _mapController = MapController();

  final CiudadanoModeloVista _modeloVista = CiudadanoModeloVista();

  // Enlazamos nuestro nuevo ViewModel de Reportes
  final ReporteModeloVista _reporteModelo = ReporteModeloVista();
  final TextEditingController _descripcionController = TextEditingController();

  final LatLng _tantoyucaCentro = const LatLng(21.3510, -98.2285);
  LatLng? _casaCiudadano;
  bool _modoSeleccionarCasa = false;

  LatLng? _ubicacionReporte;
  bool _modoSeleccionarReporte = false;

  File? _fotoEvidencia; // Guardará la foto elegida en la vista
  final image_picker.ImagePicker _picker = image_picker.ImagePicker();

  // ID de prueba temporal mientras vinculamos la sesión completa
  final int _idUsuarioActual = 1;

  @override
  void initState() {
    super.initState();
    _modeloVista.addListener(_onViewModelChange);
    _modeloVista.escucharCamiones();

    // Escuchamos el estado del envío del reporte
    _reporteModelo.addListener(_onReporteStateChange);
  }

  @override
  void dispose() {
    _modeloVista.removeListener(_onViewModelChange);
    _reporteModelo.removeListener(_onReporteStateChange);
    _modeloVista.detenerEscucha();
    _modeloVista.dispose();
    _reporteModelo.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _onViewModelChange() {
    if (!mounted) return;
    setState(() {});
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
      _reporteModelo.resetearEstados(); // Limpiamos el estado de error
    }

    if (_reporteModelo.operacionExitosa) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte guardado con éxito en Supabase'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      _descripcionController.clear();
      setState(() {
        _ubicacionReporte = null;
        _fotoEvidencia = null; // ⬅️ Limpiamos la foto al tener éxito
        _currentIndex = 0;
      });
      _reporteModelo.resetearEstados();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = 'Recoruta - Mapa';
    if (_modoSeleccionarCasa) appBarTitle = 'Oprime tu Casa en el Mapa';
    if (_modoSeleccionarReporte) appBarTitle = 'Ubicación del Problema';

    if (!_modoSeleccionarCasa && !_modoSeleccionarReporte) {
      if (_currentIndex == 1) appBarTitle = 'Redactar Reporte';
      if (_currentIndex == 2) appBarTitle = 'Mi Perfil';
    }

    Widget cuerpoPantalla;
    if (_modoSeleccionarReporte) {
      cuerpoPantalla = _buildMapaSeleccionReporte();
    } else {
      final List<Widget> screens = [
        _buildMapaSection(),
        _buildReporteSection(),
        _buildPerfilSection(),
      ];
      cuerpoPantalla = screens[_currentIndex];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _modoSeleccionarCasa || _modoSeleccionarReporte
            ? Colors.blue[800]
            : const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: _modoSeleccionarCasa || _modoSeleccionarReporte
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _modoSeleccionarCasa = false;
                  _modoSeleccionarReporte = false;
                }),
              )
            : null,
      ),
      body: cuerpoPantalla,
      bottomNavigationBar: _modoSeleccionarCasa || _modoSeleccionarReporte
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() {
                _currentIndex = index;
              }),
              selectedItemColor: const Color(0xFF2E7D32),
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.assignment_late),
                  label: 'Reportar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ],
            ),
    );
  }

  Widget _buildMapaSection() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _tantoyucaCentro,
            initialZoom: 14.5,
            onTap: (tapPosition, point) {
              if (_modoSeleccionarCasa) {
                setState(() {
                  _casaCiudadano = point;
                });
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.recoruta.app',
            ),
            MarkerLayer(
              markers: [
                for (var camion in _modeloVista.camionesActivos)
                  Marker(
                    point: LatLng(
                      (camion['latitud'] as num).toDouble(),
                      (camion['longitud'] as num).toDouble(),
                    ),
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
                        size: 32,
                      ),
                    ),
                  ),
                if (_casaCiudadano != null)
                  Marker(
                    point: _casaCiudadano!,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.home, color: Colors.blue, size: 45),
                  ),
              ],
            ),
          ],
        ),
        if (_modeloVista.estaCargando)
          const Positioned(
            top: 70,
            left: 16,
            child: Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Sincronizando radar...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!_modoSeleccionarCasa)
                FloatingActionButton.extended(
                  heroTag: 'btnCamiones',
                  onPressed: () => _mostrarListaCamiones(context),
                  backgroundColor: const Color(0xFF2E7D32),
                  icon: const Icon(
                    Icons.playlist_add_check,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Ver Camiones',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReporteSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Qué inconveniente deseas reportar?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _descripcionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Escribe aquí los detalles del reporte...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ubicación del Problema',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(
                  _ubicacionReporte == null
                      ? Icons.location_off
                      : Icons.pin_drop,
                  color: _ubicacionReporte == null
                      ? Colors.grey
                      : Colors.red[700],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _ubicacionReporte == null
                        ? 'No se ha seleccionado ubicación'
                        : 'Ubicación fijada: (${_ubicacionReporte!.latitude.toStringAsFixed(4)}, ${_ubicacionReporte!.longitude.toStringAsFixed(4)})',
                    style: TextStyle(
                      color: _ubicacionReporte == null
                          ? Colors.grey[600]
                          : Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _modoSeleccionarReporte = true;
                  }),
                  icon: const Icon(Icons.map, color: Color(0xFF2E7D32)),
                  label: Text(
                    _ubicacionReporte == null ? 'Marcar' : 'Cambiar',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SECCIÓN DINÁMICA DE PREVISUALIZACIÓN DE FOTO LOCAL
          if (_fotoEvidencia != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(_fotoEvidencia!),
                    fit: BoxFit.cover,
                  ),
                ),
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: () => setState(() {
                        _fotoEvidencia = null;
                      }),
                    ),
                  ),
                ),
              ),
            ),

          // BOTÓN DE ADJUNTAR FOTO DIRECTO EN LA VISTA
          OutlinedButton.icon(
            onPressed: _reporteModelo.estaCargando
                ? null
                : () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.camera_alt,
                                color: Color(0xFF2E7D32),
                              ),
                              title: const Text('Tomar Foto con la Cámara'),
                              onTap: () async {
                                Navigator.pop(context);
                                final file = await _picker.pickImage(
                                  source: image_picker.ImageSource.camera,
                                  imageQuality: 70,
                                  maxWidth: 1080,
                                );
                                if (file != null) {
                                  setState(() {
                                    _fotoEvidencia = File(file.path);
                                  });
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.photo_library,
                                color: Color(0xFF2E7D32),
                              ),
                              title: const Text('Seleccionar desde la Galería'),
                              onTap: () async {
                                Navigator.pop(context);
                                final file = await _picker.pickImage(
                                  source: image_picker.ImageSource.gallery,
                                  imageQuality: 70,
                                  maxWidth: 1080,
                                );
                                if (file != null) {
                                  setState(() {
                                    _fotoEvidencia = File(file.path);
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: BorderSide(
                color: _fotoEvidencia == null
                    ? const Color(0xFF2E7D32)
                    : Colors.blue,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              _fotoEvidencia == null ? Icons.camera_alt : Icons.cached,
              color: _fotoEvidencia == null
                  ? const Color(0xFF2E7D32)
                  : Colors.blue,
            ),
            label: Text(
              _fotoEvidencia == null
                  ? 'Adjuntar Evidencia Foto'
                  : 'Cambiar Foto Adjunta',
              style: TextStyle(
                color: _fotoEvidencia == null
                    ? const Color(0xFF2E7D32)
                    : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // BOTÓN DE ENVIAR REPORTES CON LA FOTO INCLUIDA
          ElevatedButton(
            onPressed: _reporteModelo.estaCargando
                ? null
                : () {
                    _reporteModelo.enviarReporte(
                      idUsuario: _idUsuarioActual,
                      descripcion: _descripcionController.text,
                      latitud: _ubicacionReporte?.latitude,
                      longitud: _ubicacionReporte?.longitude,
                      foto:
                          _fotoEvidencia, // ⬅️ Pasamos el archivo local aquí directamente
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _reporteModelo.estaCargando
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Enviar Reporte',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapaSeleccionReporte() {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: _tantoyucaCentro,
            initialZoom: 15.0,
            onTap: (tapPosition, point) => setState(() {
              _ubicacionReporte = point;
            }),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.recoruta.app',
            ),
            MarkerLayer(
              markers: [
                if (_ubicacionReporte != null)
                  Marker(
                    point: _ubicacionReporte!,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.report_problem,
                      color: Colors.red,
                      size: 45,
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            color: Colors.red[50],
            elevation: 3,
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                'Toca el mapa exactamente sobre el punto donde está el problema vial/basura.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: ElevatedButton(
            onPressed: () {
              if (_ubicacionReporte == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Selecciona un punto antes de confirmar'),
                  ),
                );
                return;
              }
              setState(() => _modoSeleccionarReporte = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Confirmar Punto del Reporte',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarListaCamiones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        final camiones = _modeloVista.todosLosCamiones;
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estado de las Unidades (En Vivo)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (camiones.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No hay vehículos registrados en el sistema.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              if (camiones.isNotEmpty)
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: camiones.length,
                    itemBuilder: (context, index) {
                      final camion = camiones[index];
                      final bool esActivo =
                          camion['estado'] == 'En Ruta' ||
                          camion['estado'] == 'Disponible';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: esActivo
                              ? Colors.green[50]
                              : Colors.red[50],
                          child: Icon(
                            Icons.local_shipping,
                            color: esActivo
                                ? const Color(0xFF2E7D32)
                                : Colors.red,
                          ),
                        ),
                        title: Text(
                          'Camión Placas: ${camion['placa'] ?? 'Sin Placa'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Última act: ${camion['ultima_actualizacion'] != null ? (camion['ultima_actualizacion'].toString().length >= 19 ? camion['ultima_actualizacion'].toString().substring(11, 19) : camion['ultima_actualizacion'].toString()) : 'Nunca'}',
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: camion['estado'] == 'En Ruta'
                                ? Colors.green[100]
                                : (camion['estado'] == 'Disponible'
                                      ? Colors.blue[100]
                                      : Colors.red[100]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            camion['estado'] ?? 'Desconocido',
                            style: TextStyle(
                              color: camion['estado'] == 'En Ruta'
                                  ? Colors.green[900]
                                  : (camion['estado'] == 'Disponible'
                                        ? Colors.blue[900]
                                        : Colors.red[900]),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerfilSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
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
              subtitle: Text('Ciudadano'),
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
              style: TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
