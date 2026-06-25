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
  final bool enPausa;
  final VoidCallback onToggleRuta;
  final VoidCallback onTogglePausa;
  final VoidCallback onClearDestino;

  const MapaRutaWidget({
    super.key,
    required this.mapController,
    required this.ubicacionActualCamion,
    required this.reporteDestinoVisual,
    required this.tantoyucaCentro,
    required this.estadoCamion,
    required this.estaTransmitiendo,
    required this.enPausa,
    required this.onToggleRuta,
    required this.onTogglePausa,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: estaTransmitiendo
                          ? const Color(0xFF2E7D32).withOpacity(0.12)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      estadoCamion,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: estaTransmitiendo
                            ? const Color(0xFF2E7D32)
                            : Colors.grey[700],
                      ),
                    ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón de pausa/reanudar: solo aparece si hay una ruta activa o pausada
              if (estaTransmitiendo || enPausa)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ElevatedButton.icon(
                    onPressed: onTogglePausa,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: enPausa
                          ? const Color(0xFF2E7D32)
                          : Colors.orange[800],
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                    ),
                    icon: Icon(enPausa ? Icons.play_arrow : Icons.pause),
                    label: Text(
                      enPausa ? 'REANUDAR RUTA' : 'PAUSAR RUTA',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),

              // Botón grande existente, sin cambios en su lógica
              ElevatedButton.icon(
                onPressed: enPausa
                    ? null
                    : onToggleRuta, // bloqueado si está en pausa
                style: ElevatedButton.styleFrom(
                  backgroundColor: estaTransmitiendo
                      ? Colors.red[700]
                      : const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[400],
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
            ],
          ),
        ),
      ],
    );
  }
}
