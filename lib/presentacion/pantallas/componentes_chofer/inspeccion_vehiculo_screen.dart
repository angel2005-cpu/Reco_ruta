import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_camiones/datos/repositorios/reporte_repositorio.dart';

class InspeccionVehiculoScreen extends StatefulWidget {
  const InspeccionVehiculoScreen({
    super.key,
    required this.esSalida,
    required this.idVehiculo,
    required this.idChofer,
    required this.reporteRepo,
  });

  final bool esSalida;
  final int idVehiculo;
  final int idChofer;
  final ReporteRepositorio reporteRepo;

  @override
  State<InspeccionVehiculoScreen> createState() =>
      _InspeccionVehiculoScreenState();
}

class _InspeccionVehiculoScreenState extends State<InspeccionVehiculoScreen> {
  final TextEditingController _kmController = TextEditingController();
  final TextEditingController _combustibleController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();

  File? _fotoTomada;
  bool _estaGuardando = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _kmController.dispose();
    _combustibleController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  Future<void> _tomarFoto() async {
    // Al ser una pantalla normal, esto ya no provoca pantalla en blanco
    // aunque Android pause el proceso mientras la cámara está abierta.
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (pickedFile != null && mounted) {
      setState(() {
        _fotoTomada = File(pickedFile.path);
      });
    }
  }

  Future<void> _guardar() async {
    if (_kmController.text.isEmpty) {
      _mostrarError('Por favor ingresa el kilometraje');
      return;
    }
    if (_combustibleController.text.trim().isEmpty) {
      _mostrarError('Describe el nivel de combustible');
      return;
    }
    if (_estadoController.text.trim().isEmpty) {
      _mostrarError('Describe el estado del camión');
      return;
    }
    if (_fotoTomada == null) {
      _mostrarError('La foto del tablero es obligatoria');
      return;
    }

    setState(() => _estaGuardando = true);

    try {
      final String urlFoto = await widget.reporteRepo.subirFotoEvidencia(
        _fotoTomada!,
      );

      final double? kmParseado = double.tryParse(_kmController.text);

      await Supabase.instance.client.from('inspecciones_vehiculos').insert({
        'id_vehiculo': widget.idVehiculo,
        'id_chofer': widget.idChofer,
        'tipo_registro': widget.esSalida ? 'Salida' : 'Regreso',
        'kilometraje': kmParseado ?? 0.0,
        'nivel_combustible': _combustibleController.text.trim(),
        'estado_mecanico': _estadoController.text.trim(),
        'foto_tablero': urlFoto,
        'observaciones': 'Sin observaciones',
      });

      // Devolvemos 'true' para que la pantalla anterior sepa que se guardó
      // y pueda encender/apagar el GPS.
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _estaGuardando = false);
        _mostrarError('Error al guardar: $e');
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Evita que el chofer cierre la pantalla a medias mientras guarda
      canPop: !_estaGuardando,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.esSalida ? 'Inspección de Salida' : 'Inspección de Regreso',
          ),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: !_estaGuardando,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _kmController,
                  keyboardType: TextInputType.number,
                  enabled: !_estaGuardando,
                  decoration: const InputDecoration(
                    labelText: 'Kilometraje Actual (Ej: 150200)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _combustibleController,
                  enabled: !_estaGuardando,
                  decoration: const InputDecoration(
                    labelText: 'Nivel de Combustible',
                    hintText: 'Ej: Tanque lleno, tres cuartos, en reserva...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _estadoController,
                  enabled: !_estaGuardando,
                  decoration: const InputDecoration(
                    labelText: '¿El camión está en condiciones de salida?',
                    hintText:
                        'Describe el estado: llantas, frenos, motor, ruidos extraños, etc.',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Captura de foto
                if (_fotoTomada == null)
                  ElevatedButton.icon(
                    onPressed: _estaGuardando ? null : _tomarFoto,
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    label: const Text(
                      'Tomar Foto del Tablero',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                else
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _fotoTomada!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: _estaGuardando ? null : _tomarFoto,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Volver a tomar foto'),
                      ),
                    ],
                  ),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: _estaGuardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: _estaGuardando
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Guardar y Continuar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                if (!_estaGuardando)
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
