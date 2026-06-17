import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapaRutaWidget extends StatelessWidget {
  final MapController mapController;
  final LatLng? ubicacionActualCamion;
  final LatLng? reporteDestinoVisual;
  final LatLng tantoyucaCentro;
  final String estadoCamion;
  final bool estaTransmitiendo;
  final ValueChanged<String?> onEstadoCamionChanged;
  final VoidCallback onToggleRuta;
  final VoidCallback onClearDestino;

  const MapaRutaWidget({
    super.key,
    required this.mapController,
    required this.ubicacionActualCamion,
    required this.reporteDestinoVisual,
    required this.tantoyucaCentro,
    required this.estadoCamion,
    required this.estaTransmitiendo,
    required this.onEstadoCamionChanged,
    required this.onToggleRuta,
    required this.onClearDestino,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter:
                reporteDestinoVisual ??
                ubicacionActualCamion ??
                tantoyucaCentro,
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
                  point: ubicacionActualCamion ?? tantoyucaCentro,
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
                      color: estaTransmitiendo
                          ? const Color(0xFF2E7D32)
                          : Colors.grey,
                      size: 32,
                    ),
                  ),
                ),
                if (reporteDestinoVisual != null)
                  Marker(
                    point: reporteDestinoVisual!,
                    width: 55,
                    height: 55,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 45,
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (reporteDestinoVisual != null)
          Positioned(
            top: 85,
            right: 16,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              onPressed: onClearDestino,
              child: const Icon(Icons.layers_clear, color: Colors.red),
            ),
          ),
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
                    value: estadoCamion,
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
                    onChanged: onEstadoCamionChanged,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: ElevatedButton.icon(
            onPressed: onToggleRuta,
            style: ElevatedButton.styleFrom(
              backgroundColor: estaTransmitiendo
                  ? Colors.red[700]
                  : const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            icon: Icon(estaTransmitiendo ? Icons.stop : Icons.play_arrow),
            label: Text(
              estaTransmitiendo
                  ? 'TERMINAR RUTA'
                  : 'INICIAR RUTA (COMPARTIR GPS)',
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
}
