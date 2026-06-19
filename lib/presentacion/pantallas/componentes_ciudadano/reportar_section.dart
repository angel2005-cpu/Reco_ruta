import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_camiones/datos/repositorios/reporte_repositorio.dart';

import 'selector_ubicacion_mapa.dart';

/// Interfaz de Envío de Reportes
class ReportarSection extends StatelessWidget {
  const ReportarSection({
    super.key,
    required this.reporteRepo,
    required this.descripcionController,
    required this.coordenadasReporte,
    required this.imagenSeleccionada,
    required this.idUsuarioInterno,
    required this.centroMapaSugerido,
    required this.onCapturarEvidencia,
    required this.onUbicacionSeleccionada,
    required this.onReporteEnviado,
  });

  final ReporteRepositorio reporteRepo;
  final TextEditingController descripcionController;
  final LatLng? coordenadasReporte;
  final dynamic imagenSeleccionada; // File?
  final int? idUsuarioInterno;

  /// Punto donde se centra el mini mapa al abrirse (ej. la casa del usuario
  /// o el centro de Tantoyuca) cuando aún no hay un punto elegido.
  final LatLng centroMapaSugerido;

  final VoidCallback onCapturarEvidencia;

  /// Se llama cuando el usuario confirma un punto en el mini mapa.
  final ValueChanged<LatLng> onUbicacionSeleccionada;

  /// Se llama tras enviar el reporte con éxito para limpiar el estado
  /// (descripción, imagen y coordenadas) en el widget padre.
  final VoidCallback onReporteEnviado;

  Future<void> _abrirSelectorUbicacion(BuildContext context) async {
    final LatLng? puntoElegido = await mostrarSelectorUbicacionMapa(
      context: context,
      centroInicial: centroMapaSugerido,
      puntoSeleccionadoPrevio: coordenadasReporte,
    );
    if (puntoElegido != null) {
      onUbicacionSeleccionada(puntoElegido);
    }
  }

  Future<void> _enviarReporte(BuildContext context) async {
    if (idUsuarioInterno == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: no se pudo identificar tu usuario. Cierra sesión y vuelve a entrar.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (descripcionController.text.trim().isEmpty ||
        coordenadasReporte == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, ingresa la descripción y marca un punto en el mapa.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      String? urlFoto;
      if (imagenSeleccionada != null) {
        urlFoto = await reporteRepo.subirFotoEvidencia(imagenSeleccionada);
      }

      await reporteRepo.crearReporteCiudadano(
        idUsuario: idUsuarioInterno!,
        descripcion: descripcionController.text.trim(),
        latitud: coordenadasReporte!.latitude,
        longitud: coordenadasReporte!.longitude,
        evidenciaFotoUrl: urlFoto,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Reporte enviado exitosamente a la central!'),
          backgroundColor: Colors.green,
        ),
      );
      descripcionController.clear();
      onReporteEnviado();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al transmitir el reporte a Supabase'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generar Reporte Ciudadano',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Describe el desperfecto o problema con la ruta de recolección.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Indicador / botón de ubicación: abre un mini mapa para seleccionar el punto
            InkWell(
              onTap: () => _abrirSelectorUbicacion(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: coordenadasReporte == null
                      ? Colors.amber[50]
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: coordenadasReporte == null
                        ? Colors.amber
                        : Colors.blue,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      coordenadasReporte == null
                          ? Icons.location_searching
                          : Icons.check_circle_outline,
                      color: coordenadasReporte == null
                          ? Colors.orange[800]
                          : Colors.blue[800],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        coordenadasReporte == null
                            ? 'Toca aquí para marcar la ubicación en el mapa'
                            : 'Ubicación fijada: (${coordenadasReporte!.latitude.toStringAsFixed(5)}, ${coordenadasReporte!.longitude.toStringAsFixed(5)}) · Toca para cambiar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: coordenadasReporte == null
                              ? Colors.orange[900]
                              : Colors.blue[900],
                        ),
                      ),
                    ),
                    Icon(
                      Icons.map_outlined,
                      color: coordenadasReporte == null
                          ? Colors.orange[800]
                          : Colors.blue[800],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: descripcionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Escribe detalladamente las observaciones aquí (ej. Contenedores desbordados, camión omitió la calle)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: onCapturarEvidencia,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.camera_alt, color: Colors.blueGrey),
              label: Text(
                imagenSeleccionada != null
                    ? 'Evidencia Adjuntada ✓'
                    : 'Tomar Foto de Evidencia',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 35),

            ElevatedButton(
              onPressed: () => _enviarReporte(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'ENVIAR REPORTE CIUDADANO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
