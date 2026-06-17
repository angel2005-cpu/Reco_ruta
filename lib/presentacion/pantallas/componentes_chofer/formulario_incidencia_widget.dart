import 'package:flutter/material.dart';

class FormularioIncidenciaWidget extends StatelessWidget {
  final TextEditingController controller;
  final int idUsuario;
  final Function(String) onEnviarIncidencia;

  const FormularioIncidenciaWidget({
    super.key,
    required this.controller,
    required this.idUsuario,
    required this.onEnviarIncidencia,
  });

  @override
  Widget build(BuildContext context) {
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
            controller: controller,
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
            onPressed: () => onEnviarIncidencia(controller.text),
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
}
