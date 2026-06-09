import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_camiones/presentacion/modelos_vista/chofer_modelo.dart';

class InterfazChoferScreen extends StatefulWidget {
  const InterfazChoferScreen({super.key});

  @override
  State<InterfazChoferScreen> createState() => _InterfazChoferScreenState();
}

class _InterfazChoferScreenState extends State<InterfazChoferScreen> {
  int _currentIndex = 0;
  String _estadoCamion = "Disponible";

  // INSTANCIAMOS EL MODELO VISTA DE LA ARQUITECTURA
  final ChoferModeloVista _modeloVista = ChoferModeloVista();

  // ID estático de prueba para el camión asignado (Mapeado a tu tabla 'vehiculos')
  final int _idVehiculoAsignado = 1;

  final List<Map<String, dynamic>> _reportesCiudadanos = [
    {
      "id": 1,
      "colonia": "Centro",
      "descripcion":
          "Mucha basura acumulada fuera del mercado municipal, los perros están rompiendo las bolsas.",
      "atendido": false,
    },
    {
      "id": 2,
      "colonia": "La Garita",
      "descripcion":
          "Contenedor comunitario completamente desbordado en la esquina principal.",
      "atendido": false,
    },
  ];

  final LatLng _tantoyucaCentro = const LatLng(21.3510, -98.2285);

  @override
  void initState() {
    super.initState();
    // 3ESCUCHAMOS LOS CAMBIOS DE ESTADO DEL GPS
    _modeloVista.addListener(_onViewModelChange);
  }

  @override
  void dispose() {
    // 4LIMPIAMOS EL LISTENER PARA EVITAR FUGAS DE MEMORIA
    _modeloVista.removeListener(_onViewModelChange);
    _modeloVista.dispose();
    super.dispose();
  }

  void _onViewModelChange() {
    if (!mounted) return;

    // Si el GPS o Supabase reportan un error, lo disparamos en un SnackBar
    if (_modeloVista.mensajeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_modeloVista.mensajeError!),
          backgroundColor: Colors.red,
        ),
      );
    }

    // Sincronizamos el Dropdown visual según si el GPS está transmitiendo o no
    setState(() {
      _estadoCamion = _modeloVista.estaTransmitiendo ? 'En Ruta' : 'Disponible';
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      _buildMapaRutaSection(),
      _buildVerReportesSection(),
      _buildIncidenciaSection(),
      _buildPerfilSection(),
    ];

    final List<String> _titles = [
      'Recoruta Chofer - Mapa y Estado',
      'Reportes Ciudadanos',
      'Registrar Incidencia',
      'Mi Perfil y Horario',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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

  // VISTA 1: Mapa de Ruta + Selector de Estado Conectados al GPS Real
  Widget _buildMapaRutaSection() {
    // Leemos el estado reactivo desde el Modelo Vista en lugar de una variable local
    final bool esRutaActiva = _modeloVista.estaTransmitiendo;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: _tantoyucaCentro,
            initialZoom: 14.5,
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
                  point: _tantoyucaCentro,
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
                    child: Icon(
                      Icons.local_shipping,
                      // Cambia de color dinámicamente según la transmisión del GPS
                      color: esRutaActiva
                          ? const Color(0xFF2E7D32)
                          : Colors.grey,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Tarjeta Superior: Estado del Camión (Sincronizado al ciclo del GPS)
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Estado del Camión:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  DropdownButton<String>(
                    value: _estadoCamion,
                    underline: Container(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                    items:
                        <String>[
                          'Disponible',
                          'En Ruta',
                          'Mantenimiento',
                          'Fuera de Servicio',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        if (newValue == 'En Ruta' && !esRutaActiva) {
                          _modeloVista.iniciarRuta(_idVehiculoAsignado);
                        } else if (newValue != 'En Ruta' && esRutaActiva) {
                          _modeloVista.detenerRuta();
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        // Botón de Iniciar/Detener Ruta conectado al hardware
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: ElevatedButton.icon(
            onPressed: () {
              if (esRutaActiva) {
                _modeloVista.detenerRuta();
              } else {
                _modeloVista.iniciarRuta(_idVehiculoAsignado);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: esRutaActiva
                  ? Colors.red[700]
                  : const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            icon: Icon(esRutaActiva ? Icons.stop : Icons.play_arrow),
            label: Text(
              esRutaActiva ? 'TERMINAR RUTA' : 'INICIAR RUTA (COMPARTIR GPS)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Listado de Reportes Ciudadanos
  Widget _buildVerReportesSection() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _reportesCiudadanos.length,
      itemBuilder: (context, index) {
        final reporte = _reportesCiudadanos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[500]?.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Colonia: ${reporte['colonia']}",
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(
                      reporte['atendido']
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: reporte['atendido'] ? Colors.green : Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  reporte['descripcion'],
                  style: const TextStyle(fontSize: 14, height: 1.3),
                ),
                const Divider(height: 24),
                ElevatedButton.icon(
                  onPressed: reporte['atendido']
                      ? null
                      : () {
                          setState(() {
                            reporte['atendido'] = true;
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.assignment_turned_in),
                  label: Text(
                    reporte['atendido']
                        ? 'REPORTE ATENDIDO'
                        : 'MARCAR COMO ATENDIDO',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Registrar Incidencia
  Widget _buildIncidenciaSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reportar Percance en Ruta',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifica cualquier percance mecánico, tráfico o bloqueo para avisar a los ciudadanos.',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Detalla la incidencia aquí...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.warning_amber_rounded),
            label: const Text(
              'Registrar Incidencia',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Perfil del Chofer y Agenda
  Widget _buildPerfilSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.grey[200],
            child: const Icon(
              Icons.local_shipping,
              size: 50,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const ListTile(
              leading: Icon(Icons.person, color: Color(0xFF2E7D32)),
              title: Text('Nombre del Conductor'),
              subtitle: Text('Chofer Asignado'),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const ListTile(
              leading: Icon(Icons.vignette, color: Color(0xFF2E7D32)),
              title: Text('Placas del Vehículo'),
              subtitle: Text('XW-54-210'),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(),
          ),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Agenda Laboral',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.green[50],
            elevation: 0,
            child: const ListTile(
              leading: Icon(Icons.calendar_month, color: Color(0xFF2E7D32)),
              title: Text(
                'Lun, Mié y Vie — 06:00 AM a 02:00 PM',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text('Sector: Zona Centro - Tantoyuca'),
            ),
          ),

          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () {
              // Detener transmisión antes de salir
              _modeloVista.detenerRuta();
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
        ],
      ),
    );
  }
}
