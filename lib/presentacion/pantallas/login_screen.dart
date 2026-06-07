import 'package:flutter/material.dart';
import '../modelos_vista/login_modelo.dart';
import 'registro.dart';

class LoginPantalla extends StatefulWidget {
  const LoginPantalla({super.key});

  @override
  State<LoginPantalla> createState() => _LoginPantallaState();
}

class _LoginPantallaState extends State<LoginPantalla> {
  bool _ocultarPassword = true;

  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Instanciamos el Modelo-Vista correspondiente
  final LoginModeloVista _modeloVista = LoginModeloVista();

  @override
  void initState() {
    super.initState();
    _modeloVista.addListener(_onViewModelChange);
  }

  @override
  void dispose() {
    _modeloVista.removeListener(_onViewModelChange);
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onViewModelChange() {
    if (!mounted) return;

    // Manejo de la animación de carga
    if (_modeloVista.estaCargando) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    } else if (!_modeloVista.estaCargando && Navigator.canPop(context)) {
      // Remueve el círculo de carga cuando el servidor responde
      Navigator.pop(context);
    }

    // Si hay un error en las credenciales
    if (_modeloVista.mensajeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_modeloVista.mensajeError!),
          backgroundColor: Colors.red,
        ),
      );
    }

    // Redirección inteligente según el rol guardado en la base de datos
    if (_modeloVista.rolUsuario != null) {
      final String rol = _modeloVista.rolUsuario!;
      _modeloVista.limpiarDatos(); // Limpia el estado para futuros accesos

      if (rol == 'chofer') {
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const InterfazChoferScreen()));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abriendo interfaz de Chofer...')),
        );
      } else {
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MapaCiudadanoScreen()));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abriendo mapa de Ciudadano...')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.recycling, size: 85, color: Color(0xFF2E7D32)),
              const SizedBox(height: 12),
              const Text(
                'Recoruta',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Gestión de Residuos en Tantoyuca',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 50),

              // 👤 CAMPO: USUARIO
              TextField(
                controller: _usuarioController,
                decoration: InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF2E7D32),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🔒 CAMPO: CONTRASEÑA
              TextField(
                controller: _passwordController,
                obscureText: _ocultarPassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF2E7D32),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _ocultarPassword = !_ocultarPassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 🚀 BOTÓN PRINCIPAL
              ElevatedButton(
                onPressed: () {
                  _modeloVista.ejecutarLogin(
                    usuario: _usuarioController.text,
                    password: _passwordController.text,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Iniciar Sesión',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),

              // ENLACE A REGISTRO
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿No tienes una cuenta? ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegistroPantalla(),
                        ),
                      );
                    },
                    child: const Text(
                      'Regístrate',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
