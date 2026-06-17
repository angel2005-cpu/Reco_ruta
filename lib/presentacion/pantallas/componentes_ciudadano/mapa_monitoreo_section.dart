import 'package:flutter/material.dart';
import 'package:flutter_application_camiones/datos/utilidades/notificacion_servicio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_camiones/datos/repositorios/reporte_repositorio.dart';
import 'package:flutter_application_camiones/datos/repositorios/vehiculo_repositorio.dart';

/// Sección Monitoreo (Mapa Completo con capa Realtime aislada)
class MapaMonitoreoSection extends StatelessWidget {
  const MapaMonitoreoSection({
    super.key,
    required this.mapController,
    required this.vehiculoRepo,
    required this.reporteRepo,
    required this.centroMapa,
    required this.ubicacionCasaUsuario,
    required this.tieneCasaRegistrada,
    required this.coordenadasReporte,
    required this.onTapMapa,
    required this.calcularHaversineLocal,
    required this.onMostrarPanelCamiones,
    required this.idUsuario,
  });

  final MapController mapController;
  final VehiculoRepositorio vehiculoRepo;
  final ReporteRepositorio reporteRepo;

  final LatLng centroMapa;
  final LatLng? ubicacionCasaUsuario;
  final bool tieneCasaRegistrada;
  final LatLng? coordenadasReporte;

  final void Function(LatLng punto) onTapMapa;
  final double Function(double lat1, double lon1, double lat2, double lon2)
  calcularHaversineLocal;
  final void Function(BuildContext context) onMostrarPanelCamiones;
  final int idUsuario;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // El mapa base se renderiza de forma estática en el fondo para preservar la cámara al mover o hacer zoom
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: centroMapa,
            initialZoom: 15.0,
            onTap: (tapPosition, point) {
              // 📍 SELECCIÓN MANUAL ORIGINAL: Al tocar cualquier calle se actualiza el punto geográfico
              onTapMapa(point);
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
              stream: vehiculoRepo.escucharCamionesEnRuta(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint(
                    "Error crítico en stream de camiones: ${snapshot.error}",
                  );
                }

                final camionesActivos = snapshot.data ?? [];
                List<Marker> marcadoresRender = [];

                // 1. Añadimos la casa SÓLO si tiene coordenadas reales registradas en Supabase
                if (tieneCasaRegistrada && ubicacionCasaUsuario != null) {
                  marcadoresRender.add(
                    Marker(
                      point: ubicacionCasaUsuario!,
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
                if (coordenadasReporte != null) {
                  marcadoresRender.add(
                    Marker(
                      point: coordenadasReporte!,
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
                  if (camion['latitud'] == null || camion['longitud'] == null) {
                    continue;
                  }

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

        // ALERTA DE PROXIMIDAD INMEDIATA (100 METROS)
        // Usa su propio StreamBuilder flotante para no interferir con las operaciones de la cámara del mapa
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: vehiculoRepo.escucharCamionesEnRuta(),
          builder: (context, snapshot) {
            final camiones = snapshot.data ?? [];
            if (camiones.isEmpty ||
                !tieneCasaRegistrada ||
                ubicacionCasaUsuario == null) {
              return const SizedBox.shrink();
            }

            double distanciaMinima = double.infinity;
            Map<String, dynamic>? camionMasCercano;

            for (var camion in camiones) {
              if (camion['latitud'] == null || camion['longitud'] == null) {
                continue;
              }
              final double lat = (camion['latitud'] as num).toDouble();
              final double lng = (camion['longitud'] as num).toDouble();

              final double dist = calcularHaversineLocal(
                ubicacionCasaUsuario!.latitude,
                ubicacionCasaUsuario!.longitude,
                lat,
                lng,
              );

              if (dist < distanciaMinima) {
                distanciaMinima = dist;
                camionMasCercano = camion;
              }
            }

            if (distanciaMinima <= 100 && camionMasCercano != null) {
              NotificacionServicio.notificarCamionCerca(idUsuario: idUsuario);
              return _AlertaProximidadFlotante(
                idVehiculo: camionMasCercano['id_vehiculo'],
                distancia: distanciaMinima.toInt(),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // BANNER DE INCIDENCIAS MECÁNICAS O DE TRÁFICO
        _IncidenciasStreamBanner(reporteRepo: reporteRepo),

        // BOTÓN PARA DESPLEGAR PANEL DE UNIDADES ONLINE
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
            onPressed: () => onMostrarPanelCamiones(context),
          ),
        ),
      ],
    );
  }
}

class _AlertaProximidadFlotante extends StatelessWidget {
  const _AlertaProximidadFlotante({
    required this.idVehiculo,
    required this.distancia,
  });

  final int idVehiculo;
  final int distancia;

  @override
  Widget build(BuildContext context) {
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
}

class _IncidenciasStreamBanner extends StatelessWidget {
  const _IncidenciasStreamBanner({required this.reporteRepo});

  final ReporteRepositorio reporteRepo;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 115,
      left: 16,
      right: 16,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: reporteRepo.escucharIncidenciasActivas(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }

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
}

/// Panel modal con la lista de camiones en servicio activo.
void mostrarPanelCamiones({
  required BuildContext context,
  required VehiculoRepositorio vehiculoRepo,
  required MapController mapController,
}) {
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
                  stream: vehiculoRepo.escucharCamionesEnRuta(),
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
                            mapController.move(LatLng(lat, lng), 16.0);
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
