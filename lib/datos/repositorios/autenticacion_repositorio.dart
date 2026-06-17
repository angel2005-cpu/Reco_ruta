import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';

class AutenticacionRepositorio {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Inserta los datos en 'usuarios' y 'ciudadanos'
  Future<void> registrarCiudadano({
    required String usuario,
    required String password,
    required String nombre,
    required double latitud,
    required double longitud,
  }) async {
    try {
      // Generar hash de la contraseña
      final String hashPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      final List<Map<String, dynamic>> nuevoUsuario = await _supabase
          .from('usuarios')
          .insert({
            'usuario': usuario,
            'contrasena': hashPassword,
            'rol': 'ciudadano',
          })
          .select('id_usuario');

      if (nuevoUsuario.isNotEmpty) {
        final int idGenerado = nuevoUsuario.first['id_usuario'];

        await _supabase.from('ciudadanos').insert({
          'id_usuario': idGenerado,
          'nombre': nombre,
          'casa_latitud': latitud,
          'casa_longitud': longitud,
        });
      } else {
        throw Exception('No se pudo crear el registro en la tabla usuarios.');
      }
    } catch (e) {
      throw Exception(
        'El usuario ya existe o hubo un problema con la base de datos.',
      );
    }
  }

  /// Valida las credenciales y devuelve el rol del usuario
  Future<Map<String, dynamic>> iniciarSesion({
    required String usuario,
    required String password,
  }) async {
    try {
      final List<Map<String, dynamic>> respuesta = await _supabase
          .from('usuarios')
          .select('id_usuario, rol, contrasena')
          .eq('usuario', usuario);

      if (respuesta.isEmpty) {
        throw Exception('Usuario o contraseña incorrectos.');
      }

      final datosUsuario = respuesta.first;

      final bool passwordCorrecta = BCrypt.checkpw(
        password,
        datosUsuario['contrasena'],
      );

      if (!passwordCorrecta) {
        throw Exception('Usuario o contraseña incorrectos.');
      }

      return {
        'rol': datosUsuario['rol'] as String,
        'id_usuario': datosUsuario['id_usuario'] as int,
      };
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
