import 'package:supabase_flutter/supabase_flutter.dart';

class AutenticacionRepositorio {
  final SupabaseClient _supabase = Supabase.instance.client;

  //inserta los datos en 'usuarios' y 'ciudadanos'
  Future<void> registrarCiudadano({
    required String usuario,
    required String password,
    required String nombre,
    required double latitud,
    required double longitud,
  }) async {
    try {
      final List<Map<String, dynamic>> nuevoUsuario = await _supabase
          .from('usuarios')
          .insert({
            'usuario': usuario,
            'contrasena': password,
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

  /// 🔑 LOGIN: Valida las credenciales y devuelve el rol del usuario
  Future<Map<String, dynamic>> iniciarSesion({
    required String usuario,
    required String password,
  }) async {
    try {
      final List<Map<String, dynamic>> respuesta = await _supabase
          .from('usuarios')
          .select('id_usuario, rol') // ← agrega id_usuario
          .eq('usuario', usuario)
          .eq('contrasena', password);

      if (respuesta.isNotEmpty) {
        return {
          'rol': respuesta.first['rol'] as String,
          'id_usuario': respuesta.first['id_usuario'] as int,
        };
      } else {
        throw Exception('Usuario o contraseña incorrectos.');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
