import 'package:flutter/material.dart';

class PerfilChoferWidget extends StatelessWidget {
  final Map<String, dynamic>? perfilChofer;
  final VoidCallback onCerrarSesion;

  const PerfilChoferWidget({
    super.key,
    required this.perfilChofer,
    required this.onCerrarSesion,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
            child: const Icon(
              Icons.local_shipping,
              size: 50,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
          _buildPerfilCard(
            Icons.badge,
            'Nombre del Conductor',
            perfilChofer?['nombre'],
          ),
          _buildPerfilCard(
            Icons.account_circle,
            'Usuario',
            perfilChofer?['usuario'],
          ),
          _buildPerfilCard(
            Icons.vignette,
            'Placas del Vehículo',
            perfilChofer?['placa'],
          ),
          _buildPerfilCard(
            Icons.calendar_month,
            'Horario',
            perfilChofer?['horario'],
            color: Colors.green[50],
          ),
          _buildPerfilCard(
            Icons.map,
            'Sector Asignado',
            perfilChofer?['sector'],
            color: Colors.green[50],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onCerrarSesion,
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

  Widget _buildPerfilCard(
    IconData icon,
    String title,
    String? subtitle, {
    Color? color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color,
      elevation: color == null ? 1 : 0,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2E7D32)),
        title: Text(title),
        subtitle: Text(subtitle ?? 'Cargando...'),
      ),
    );
  }
}
