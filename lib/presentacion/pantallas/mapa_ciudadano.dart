import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapaCiudadanoScreen extends StatefulWidget {
  const MapaCiudadanoScreen({super.key});

  @override
  State<MapaCiudadanoScreen> createState() => _MapaCiudadanoScreenState();
}

class _MapaCiudadanoScreenState extends State<MapaCiudadanoScreen> {
  int _currentIndex = 0;
  final MapController _mapController = MapController();

  // Coordenadas base de Tantoyuca
  final LatLng _tantoyucaCentro = const LatLng(21.3510, -98.2285);
  final LatLng _camionSimulado = const LatLng(21.3540, -98.2240);

  // Ubicación de la casa del Ciudadano (Paso previo/Fijar casa)
  LatLng? _casaCiudadano;
  bool _modoSeleccionarCasa = false;

  // Atributos para la ubicación del Reporte Ciudadano (latitud y longitud del diagrama)
  LatLng? _ubicacionReporte;
  bool _modoSeleccionarReporte = false; // Controla el sub-mapa del reporte

  final List<Map<String, dynamic>> _estatusCamiones = [
    {
      "placa": "XW-54-210",
      "sector": "Zona Centro",
      "estado": "En Ruta",
      "activo": true,
    },
    {
      "placa": "AB-87-341",
      "sector": "La Garita",
      "estado": "Disponible",
      "activo": true,
    },
    {
      "placa": "JK-12-990",
      "sector": "Ninguno",
      "estado": "Fuera de Servicio",
      "activo": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Títulos dinámicos según el estado de la pantalla
    String appBarTitle = 'Recoruta - Mapa';
    if (_modoSeleccionarCasa) appBarTitle = 'Oprime tu Casa en el Mapa';
    if (_modoSeleccionarReporte) appBarTitle = 'Ubicación del Problema';

    if (!_modoSeleccionarCasa && !_modoSeleccionarReporte) {
      if (_currentIndex == 1) appBarTitle = 'Redactar Reporte';
      if (_currentIndex == 2) appBarTitle = 'Mi Perfil';
    }

    // Si el usuario está seleccionando la ubicación del reporte, muestra el mapa de selección
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
          ? null // Oculta barra si se está interactuando con algún mapa de selección
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

  // 🗺️ VISTA 1: El Mapa Principal de Monitoreo
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
                Marker(
                  point: _camionSimulado,
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

  // 📝 VISTA 2: Formulario para Redactar Reporte con Selección de Ubicación
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

          // 📍 NUEVO APARTADO: UBICACIÓN DEL REPORTE (Latitud/Longitud del diagrama)
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

  // Las demás secciones auxiliares permanecen idénticas...
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
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estado de las Unidades',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _estatusCamiones.length,
                  itemBuilder: (context, index) {
                    final camion = _estatusCamiones[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: camion['activo']
                            ? Colors.green[50]
                            : Colors.red[50],
                        child: Icon(
                          Icons.local_shipping,
                          color: camion['activo']
                              ? const Color(0xFF2E7D32)
                              : Colors.red,
                        ),
                      ),
                      title: Text(
                        'Camión Placas: ${camion['placa']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Sector: ${camion['sector']}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: camion['activo']
                              ? Colors.green[100]
                              : Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          camion['estado'],
                          style: TextStyle(
                            color: camion['activo']
                                ? Colors.green[900]
                                : Colors.red[900],
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
            onPressed: () {},
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
