import 'package:flutter/material.dart';
import 'package:flutter_application_camiones/presentacion/modelos_vista/ciudadano_modelo.dart';

/// Sección de Perfil del ciudadano
class PerfilSection extends StatelessWidget {
  const PerfilSection({
    super.key,
    required this.modeloVista,
    required this.perfilCiudadano,
    required this.tieneCasaRegistrada,
  });

  final CiudadanoModeloVista modeloVista;
  final Map<String, dynamic>? perfilCiudadano;
  final bool tieneCasaRegistrada;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 30),
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
            child: const Icon(Icons.person, size: 60, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.badge, color: Color(0xFF2E7D32)),
              title: const Text('Nombre completo'),
              subtitle: Text(perfilCiudadano?['nombre'] ?? 'Cargando...'),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.account_circle,
                color: Color(0xFF2E7D32),
              ),
              title: const Text('Usuario'),
              subtitle: Text(perfilCiudadano?['usuario'] ?? 'Cargando...'),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF2E7D32)),
              title: const Text('Domicilio registrado'),
              subtitle: Text(
                tieneCasaRegistrada
                    ? '${perfilCiudadano?['casa_latitud']}, ${perfilCiudadano?['casa_longitud']}'
                    : 'No registrado',
              ),
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {
              modeloVista.detenerEscucha();
              Navigator.pushReplacementNamed(context, '/login');
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
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
