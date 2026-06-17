import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Diálogo con un mini mapa interactivo para que el ciudadano
/// seleccione la ubicación del reporte sin salir de la pestaña "Reportar".
///
/// Devuelve el [LatLng] elegido, o `null` si el usuario cancela.
Future<LatLng?> mostrarSelectorUbicacionMapa({
  required BuildContext context,
  required LatLng centroInicial,
  LatLng? puntoSeleccionadoPrevio,
}) {
  return showDialog<LatLng>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return _SelectorUbicacionDialog(
        centroInicial: centroInicial,
        puntoSeleccionadoPrevio: puntoSeleccionadoPrevio,
      );
    },
  );
}

class _SelectorUbicacionDialog extends StatefulWidget {
  const _SelectorUbicacionDialog({
    required this.centroInicial,
    this.puntoSeleccionadoPrevio,
  });

  final LatLng centroInicial;
  final LatLng? puntoSeleccionadoPrevio;

  @override
  State<_SelectorUbicacionDialog> createState() =>
      _SelectorUbicacionDialogState();
}

class _SelectorUbicacionDialogState extends State<_SelectorUbicacionDialog> {
  late final MapController _mapController;
  LatLng? _puntoElegido;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _puntoElegido = widget.puntoSeleccionadoPrevio;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LatLng centro = _puntoElegido ?? widget.centroInicial;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: double.maxFinite,
        height: 480,
        child: Column(
          children: [
            // Encabezado
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Toca el mapa para marcar el lugar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Mini mapa
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: centro,
                      initialZoom: 16.0,
                      onTap: (tapPosition, point) {
                        setState(() {
                          _puntoElegido = point;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.recoruta.app',
                      ),
                      if (_puntoElegido != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _puntoElegido!,
                              width: 50,
                              height: 50,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 42,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  // Texto de ayuda flotante
                  if (_puntoElegido == null)
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Mueve el mapa y toca el punto exacto del problema',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Coordenadas elegidas + acciones
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_puntoElegido != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Seleccionado: (${_puntoElegido!.latitude.toStringAsFixed(5)}, ${_puntoElegido!.longitude.toStringAsFixed(5)})',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _puntoElegido == null
                              ? null
                              : () => Navigator.of(context).pop(_puntoElegido),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Confirmar ubicación'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
