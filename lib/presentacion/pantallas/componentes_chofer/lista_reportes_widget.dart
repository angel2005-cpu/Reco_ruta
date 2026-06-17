import 'package:flutter/material.dart';
import 'package:flutter_application_camiones/datos/repositorios/reporte_repositorio.dart';
import 'package:latlong2/latlong.dart';

class ListaReportesWidget extends StatelessWidget {
  final ReporteRepositorio reporteRepo;
  final int idUsuario;
  final Function(double lat, double lng) onVerEnMapa;
  final Function(LatLng? nuevoDestino) onReporteAtendido;
  final bool Function(double lat) esDestinoActual;

  const ListaReportesWidget({
    super.key,
    required this.reporteRepo,
    required this.idUsuario,
    required this.onVerEnMapa,
    required this.onReporteAtendido,
    required this.esDestinoActual,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: reporteRepo.escucharReportesCiudadanos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No hay reportes viales o de basura pendientes.',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          );
        }

        final reportes = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: reportes.length,
          itemBuilder: (context, index) {
            final reporte = reportes[index];
            final bool esAtendido = reporte['estado'] == 'Atendido';

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
                            "Folio #${reporte['id_reporte']}",
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              reporte['estado'] ?? 'Pendiente',
                              style: TextStyle(
                                color: esAtendido
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              esAtendido
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: esAtendido ? Colors.green : Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      reporte['descripcion'] ?? '',
                      style: const TextStyle(fontSize: 14, height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Coordenadas: (${reporte['latitud']}, ${reporte['longitud']})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: esAtendido
                                ? null
                                : () => onVerEnMapa(
                                    (reporte['latitud'] as num).toDouble(),
                                    (reporte['longitud'] as num).toDouble(),
                                  ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.blue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: const Size.fromHeight(45),
                            ),
                            icon: const Icon(Icons.map, color: Colors.blue),
                            label: const Text(
                              'VER EN MAPA',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: esAtendido
                                ? null
                                : () async {
                                    try {
                                      await reporteRepo
                                          .marcarReporteComoAtendido(
                                            idReporte: reporte['id_reporte'],
                                            idChofer: idUsuario,
                                          );

                                      onReporteAtendido(
                                        esDestinoActual(reporte['latitud'])
                                            ? null
                                            : const LatLng(0, 0),
                                      );

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Reporte actualizado a Atendido',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Error al actualizar reporte',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
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
                            label: Text(esAtendido ? 'ATENDIDO' : 'RESOLVER'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
