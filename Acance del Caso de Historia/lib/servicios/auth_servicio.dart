import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:sos_mascotas/servicios/historial_servicio.dart';
import 'package:sos_mascotas/modelo/inicio_sesion.dart';

class AuthServicio {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> registrar(String correo, String clave) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: correo,
      password: clave,
    );
    return cred.user!.uid;
  }

  // Enviar correo de verificación al usuario actual
  Future<void> enviarVerificacionCorreo() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Volver a cargar datos del usuario desde Firebase
  Future<void> recargarUsuario() async {
    final user = _auth.currentUser;
    if (user != null) await user.reload();
  }

  // ¿El correo ya fue verificado?
  bool get correoVerificado {
    final user = _auth.currentUser;
    return (user != null && user.emailVerified);
  }

  // Reenviar correo (igual a enviarVerificacionCorreo, separado por claridad)
  Future<void> reenviarVerificacion() => enviarVerificacionCorreo();

  // (Opcional) login que bloquea si no está verificado
  Future<User?> loginBloqueandoSiNoVerificado(
    String correo,
    String clave,
  ) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: correo,
      password: clave,
    );
    await cred.user?.reload();
    if (cred.user != null && !cred.user!.emailVerified) {
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Debe verificar su correo antes de continuar.',
      );
    }

    // Intentar registrar el inicio de sesión (no bloquear en caso de fallo)
    try {
      final uid = cred.user?.uid;
      if (uid != null) {
        final ip = await _obtenerIpPublica();
        final dispositivo = _obtenerDescripcionDispositivo();
        final inicio = InicioSesion(
          uidUsuario: uid,
          fecha: DateTime.now().toUtc(),
          direccionIp: ip,
          dispositivo: dispositivo,
        );
        await HistorialServicio().registrarInicio(inicio);
      }
    } catch (_) {
      // Ignorar errores de registro para no bloquear el login
    }

    return cred.user;
  }

  Future<String> _obtenerIpPublica() async {
    try {
      final res = await http
          .get(Uri.parse('https://api.ipify.org?format=json'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final body = res.body;
        final match = RegExp(r'"ip"\s*:\s*"([^"]+)"').firstMatch(body);
        if (match != null) return match.group(1)!;
      }
    } catch (_) {}
    return 'desconocida';
  }

  String _obtenerDescripcionDispositivo() {
    try {
      return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } catch (_) {
      return 'desconocido';
    }
  }
}
