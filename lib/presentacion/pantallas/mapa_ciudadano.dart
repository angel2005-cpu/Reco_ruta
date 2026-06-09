import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_camiones/presentacion/modelos_vista/ciudadano_modelo.dart';

class MapaCiudadanoScreen extends StatefulWidget {
  const MapaCiudadanoScreen({super.key});

  @override
  State<MapaCiudadanoScreen> createState() => _MapaCiudadanoScreenState();
}

class _MapaCiudadanoScreenState extends State<MapaCiudadanoScreen> {
  int _currentIndex = 0;
  final MapController _mapController = MapController();

  // 2️⃣ INSTANCIAMOS EL MODELO VISTA DE LA ARQUITECTURA
  final CiudadanoModeloVista _modeloVista = CiudadanoModeloVista();

  // Coordenadas base de Tantoyuca
  final LatLng _tantoyucaCentro = const LatLng(21.3510, -98.2285);

  // Ubicación de la casa del Ciudadano
  LatLng? _casaCiudadano;
  bool _modoSeleccionarCasa = false;

  // Ubicación del Reporte Ciudadano
  LatLng? _ubicacionReporte;
  bool _modoSeleccionarReporte = false;

  @override
  void initState() {
    super.initState();
    // 3️⃣ ENCENDEMOS EL ESCUCHADOR EN TIEMPO REAL
    _modeloVista.addListener(_onViewModelChange);
    _modeloVista.escucharCamiones();
  }

  @override
  void dispose() {
    // 4️⃣ APAGAMOS LA ESCUCHA AL SALIR PARA PRESERVAR MEMORIA
    _modeloVista.removeListener(_onViewModelChange);
    _modeloVista.detenerEscucha();
    _modeloVista.dispose();
    super.dispose();
  }

  void _onViewModelChange() {
    if (!mounted) return;
    setState(() {}); // Redibuja la interfaz ante actualizaciones de Supabase
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
                onPressed: () {
                  setState(() {
                    _modoSeleccionarCasa = false;
                    _modoSeleccionarReporte = false;
                  });
                },
              )
            : null,
      ),
      body: cuerpoPantalla,
      bottomNavigationBar: _modoSeleccionarCasa || _modoSeleccionarReporte
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
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

  // 🗺️ VISTA 1: El Mapa Principal de Monitoreo (Alineado al Tiempo Real)
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
                // 🔄 MAPEO DINÁMICO: Pintamos un camión por cada unidad activa devuelta por Supabase
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

        // Alerta visual de carga de radar
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

        if (_modoSeleccionarCasa)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'Toca el mapa para reubicar tu hogar de referencia.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
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

  // 📝 VISTA 2: Formulario para Redactar Reporte
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
                  onPressed: () {
                    setState(() {
                      _modoSeleccionarReporte = true;
                    });
                  },
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
          OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
            label: const Text(
              'Adjuntar Evidencia Foto',
              style: TextStyle(color: Color(0xFF2E7D32)),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              if (_ubicacionReporte == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Por favor, selecciona la ubicación en el mapa',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reporte creado con éxito')),
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
            child: const Text(
              'Enviar Reporte',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // 🗺️ SUB-VISTA INTERACTIVA: Mapa para elegir la ubicación del reporte
  Widget _buildMapaSeleccionReporte() {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: _tantoyucaCentro,
            initialZoom: 15.0,
            onTap: (tapPosition, point) {
              setState(() {
                _ubicacionReporte = point;
              });
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

  // 📋 MODAL BOTTOM SHEET CONNECTED TO SUPABASE
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
        // Obtenemos los camiones dinámicos desde el Modelo-Vista
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
                          'Última act: ${camion['ultima_actualizacion'] != null ? (camion['ultima_actualizacion'].toString().substring(11, 19)) : 'Nunca'}',
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
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const ListTile(
              leading: Icon(Icons.account_circle, color: Color(0xFF2E7D32)),
              title: Text('Nombre de Usuario'),
              subtitle: Text('Ciudadano'),
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {
              _modeloVista.detenerEscucha();
              Navigator.pushReplacementNamed(context, '/');
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
