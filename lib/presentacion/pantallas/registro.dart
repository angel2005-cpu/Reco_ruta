import 'package:flutter/material.dart';
import '../modelos_vista/registro_modelo.dart';

class RegistroPantalla extends StatefulWidget {
  const RegistroPantalla({super.key});

  @override
  State<RegistroPantalla> createState() => _RegistroPantallaState();
}

class _RegistroPantallaState extends State<RegistroPantalla> {
  bool _ocultarPassword = true;
  bool _ocultarConfirmarPassword = true;

  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmarPasswordController =
      TextEditingController();

  final RegistroModeloVista _modeloVista = RegistroModeloVista();

  @override
  void initState() {
    super.initState();
    _modeloVista.addListener(_onViewModelChange);
  }

  @override
  void dispose() {
    _modeloVista.removeListener(_onViewModelChange);
    _usuarioController.dispose();
    _nombreController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  void _onViewModelChange() {
    if (!mounted) return;

    if (_modeloVista.estaCargando) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    } else if (!_modeloVista.estaCargando && Navigator.canPop(context)) {
      Navigator.pop(context); // Cierra el indicador de carga
    }

    if (_modeloVista.mensajeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_modeloVista.mensajeError!),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (_modeloVista.registroExitoso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Registro exitoso con ubicación actual!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Registro Ciudadano',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2E7D32)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const Icon(
                Icons.share_location,
                size: 75,
                color: Color(0xFF2E7D32),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu ubicación se guardará automáticamente usando el GPS de tu dispositivo.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Campo: Nombre completo
              TextField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre Completo',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Campo: Nombre de Usuario
              TextField(
                controller: _usuarioController,
                decoration: InputDecoration(
                  labelText: 'Nombre de Usuario',
                  prefixIcon: const Icon(Icons.account_box_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Campo: Contraseña
              TextField(
                controller: _passwordController,
                obscureText: _ocultarPassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _ocultarPassword = !_ocultarPassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Campo: Confirmar Contraseña
              TextField(
                controller: _confirmarPasswordController,
                obscureText: _ocultarConfirmarPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarConfirmarPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => _ocultarConfirmarPassword =
                          !_ocultarConfirmarPassword,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 🚀 BOTÓN UNIFICADO: CONCEDE PERMISOS Y REGISTRA
              ElevatedButton.icon(
                onPressed: () {
                  _modeloVista.ejecutarRegistro(
                    usuario: _usuarioController.text,
                    password: _passwordController.text,
                    confirmarPassword: _confirmarPasswordController.text,
                    nombre: _nombreController.text,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.gps_fixed),
                label: const Text(
                  'REGISTRARME CON MI UBICACIÓN',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
