import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sos_mascotas/servicios/notificacion_servicio.dart';
import 'package:sos_mascotas/servicios/servicio_openai.dart';

import '../../modelo/avistamiento.dart';

class AvistamientoVM extends ChangeNotifier {
  Avistamiento avistamiento = Avistamiento();
  bool _cargando = false;

  bool get cargando => _cargando;

  void setDireccion(String v) => avistamiento.direccion = v;
  void setDescripcion(String v) => avistamiento.descripcion = v;

  // 🔧 Método para comprimir imágenes antes de subir
  Future<File> _comprimirImagen(File archivo) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        "${dir.absolute.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";

    final result = await FlutterImageCompress.compressAndGetFile(
      archivo.absolute.path,
      targetPath,
      quality: 70,
    );

    return result != null ? File(result.path) : archivo;
  }

  // 📸 Subir foto con validación de IA (usa tu API Key de OpenAI)
  Future<String> subirFoto(File archivo) async {
    final comprimido = await _comprimirImagen(archivo);

    // 🧠 Validar con OpenAI antes de subir
    final esValida = await ServicioOpenAI.contieneMascota(comprimido);
    if (!esValida) {
      throw Exception(
        "❌ La imagen no contiene una mascota. Intenta con otra foto.",
      );
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance
        .ref()
        .child("avistamientos")
        .child(uid)
        .child("${DateTime.now().millisecondsSinceEpoch}.jpg");

    await ref.putFile(comprimido);
    return await ref.getDownloadURL();
  }

  // 💾 Guardar el avistamiento en Firestore
  Future<bool> guardarAvistamiento() async {
    try {
      _cargando = true;
      notifyListeners();

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final docRef = FirebaseFirestore.instance
          .collection("avistamientos")
          .doc();

      avistamiento.id = docRef.id;
      avistamiento.usuarioId = uid;

      // Validación básica
      avistamiento.direccion = avistamiento.direccion.trim();
      avistamiento.distrito = avistamiento.distrito.trim();

      await docRef.set(
        avistamiento.toMap()
          ..addAll({"fechaRegistro": FieldValue.serverTimestamp()}),
      );

      // 🔔 Notificación push global
      await NotificacionServicio.enviarPush(
        titulo: "Nuevo avistamiento 👀",
        cuerpo: "Se ha registrado un nuevo avistamiento de mascota.",
      );

      _cargando = false;
      notifyListeners();
      return true;
    } catch (e) {
      _cargando = false;
      notifyListeners();
      debugPrint("❌ Error al guardar avistamiento: $e");
      return false;
    }
  }

  // ✅ Actualizar ubicación (para usar al volver del mapa)
  void actualizarUbicacion({
    required String direccion,
    required String distrito,
    required double latitud,
    required double longitud,
  }) {
    avistamiento.direccion = direccion;
    avistamiento.distrito = distrito;
    avistamiento.latitud = latitud;
    avistamiento.longitud = longitud;
    notifyListeners();
  }
}
