import 'package:flutter/material.dart';
import 'package:flutter_application_camiones/datos/repositorios/reporte_repositorio.dart';

/// Sección "Incidencias" para el ciudadano.
/// Muestra en tiempo real los percances reportados por los choferes
/// (descomposturas, bloqueos, retrasos) con su estado y vehículo.
class IncidenciasSection extends StatelessWidget {
  const IncidenciasSection({super.key, required this.reporteRepo});

  final ReporteRepositorio reporteRepo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  encabezado
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE65100).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFE65100),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Incidencias de Camiones',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Percances reportados por los choferes en tiempo real. '
                    'Pueden afectar la llegada del camión a tu zona.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // lista en tiempo real
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: reporteRepo.escucharIncidenciasActivas(),
                builder: (context, snapshot) {
                  // Error de conexión
                  if (snapshot.hasError) {
                    return _EstadoVacio(
                      icono: Icons.cloud_off_rounded,
                      color: Colors.red[400]!,
                      titulo: 'No se pudieron cargar las incidencias',
                      subtitulo: 'Verifica tu conexión e intenta de nuevo.',
                    );
                  }

                  // Cargando primera vez
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                        strokeWidth: 2.5,
                      ),
                    );
                  }

                  final incidencias = snapshot.data!;

                  // Sin incidencias: servicio normal
                  if (incidencias.isEmpty) {
                    return const _EstadoVacio(
                      icono: Icons.check_circle_outline_rounded,
                      color: Color(0xFF2E7D32),
                      titulo: 'Sin incidencias registradas',
                      subtitulo:
                          'Todos los camiones operan con normalidad en este momento.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: incidencias.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _IncidenciaCard(incidencia: incidencias[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//incidencias
class _IncidenciaCard extends StatelessWidget {
  const _IncidenciaCard({required this.incidencia});

  final Map<String, dynamic> incidencia;

  @override
  Widget build(BuildContext context) {
    final String descripcion =
        incidencia['descripcion'] ?? 'Percance sin descripción';
    final int idVehiculo = incidencia['id_vehiculo'] ?? 0;
    final String? fechaCruda = incidencia['fecha_hora'] as String?;
    final String fechaTexto = _formatearFecha(fechaCruda);

    final _TipoAviso tipo = _clasificarIncidencia(descripcion);

    return Card(
      elevation: 2,
      shadowColor: tipo.color.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: tipo.color.withOpacity(0.25), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono de tipo
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tipo.color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(tipo.icono, color: tipo.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado: camión + badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        idVehiculo > 0
                            ? 'Camión #$idVehiculo'
                            : 'Aviso general',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF212121),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: tipo.color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tipo.etiqueta,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: tipo.color,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Descripción
                  Text(
                    descripcion,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF424242),
                    ),
                  ),
                  // Fecha
                  if (fechaTexto.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fechaTexto,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(String? fechaCruda) {
    if (fechaCruda == null) return '';
    final fecha = DateTime.tryParse(fechaCruda);
    if (fecha == null) return '';
    final local = fecha.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm · $hh:$min hrs';
  }

  /// Clasifica la incidencia por palabras clave para mostrar icono/color correcto.
  _TipoAviso _clasificarIncidencia(String descripcion) {
    final lower = descripcion.toLowerCase();

    if (lower.contains('descompuest') ||
        lower.contains('mecán') ||
        lower.contains('llanta') ||
        lower.contains('motor') ||
        lower.contains('falla')) {
      return _TipoAviso(
        icono: Icons.build_rounded,
        color: const Color(0xFFD32F2F),
        etiqueta: 'MECÁNICA',
      );
    }

    if (lower.contains('tráfico') ||
        lower.contains('trafico') ||
        lower.contains('bloqueo') ||
        lower.contains('accidente') ||
        lower.contains('cerrada')) {
      return _TipoAviso(
        icono: Icons.traffic_rounded,
        color: const Color(0xFFE65100),
        etiqueta: 'TRÁFICO',
      );
    }

    if (lower.contains('retraso') ||
        lower.contains('tardanza') ||
        lower.contains('demora')) {
      return _TipoAviso(
        icono: Icons.schedule_rounded,
        color: const Color(0xFFF9A825),
        etiqueta: 'RETRASO',
      );
    }

    if (lower.contains('cancel') || lower.contains('ruta')) {
      return _TipoAviso(
        icono: Icons.cancel_rounded,
        color: const Color(0xFF6A1B9A),
        etiqueta: 'RUTA',
      );
    }

    // aviso general naranja
    return _TipoAviso(
      icono: Icons.warning_amber_rounded,
      color: const Color(0xFFE65100),
      etiqueta: 'AVISO',
    );
  }
}

class _TipoAviso {
  const _TipoAviso({
    required this.icono,
    required this.color,
    required this.etiqueta,
  });
  final IconData icono;
  final Color color;
  final String etiqueta;
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.subtitulo,
  });

  final IconData icono;
  final Color color;
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 60, color: color),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
