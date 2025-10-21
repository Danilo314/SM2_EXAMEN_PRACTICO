import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sos_mascotas/servicios/notificacion_servicio.dart';
import 'package:sos_mascotas/servicios/servicio_openai.dart';
import '../../modelo/reporte_mascota.dart';

class ReporteMascotaVM extends ChangeNotifier {
  int _paso = 0;
  ReporteMascota reporte = ReporteMascota();

  bool _cargando = false;

  // ✅ FormKeys para validaciones en cada paso
  final formKeyPaso1 = GlobalKey<FormState>();
  final formKeyPaso2 = GlobalKey<FormState>();
  final formKeyPaso3 = GlobalKey<FormState>();

  // Getters
  int get paso => _paso;
  bool get cargando => _cargando;
  List<String> get fotos => reporte.fotos;
  List<String> get videos => reporte.videos;

  // 🔹 Control del wizard
  void setPaso(int nuevoPaso) {
    _paso = nuevoPaso;
    notifyListeners();
  }

  void siguientePaso() {
    if (_paso < 2) {
      _paso++;
      notifyListeners();
    }
  }

  void pasoAnterior() {
    if (_paso > 0) {
      _paso--;
      notifyListeners();
    }
  }

  // 📸 Agregar fotos
  void agregarFoto(String url) {
    reporte.fotos.add(url);
    notifyListeners();
  }

  // 🎥 Agregar videos
  void agregarVideo(String url) {
    reporte.videos.add(url);
    notifyListeners();
  }

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

  // 📸 Subir foto con validación por OpenAI
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
        .child("reportes_mascotas")
        .child(uid)
        .child("${DateTime.now().millisecondsSinceEpoch}.jpg");

    await ref.putFile(comprimido);
    return await ref.getDownloadURL();
  }

  // 🎥 Subir video (máx 10 segundos)
  Future<String> subirVideo(File archivo) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final ref = FirebaseStorage.instance
        .ref()
        .child("reportes_mascotas")
        .child(uid)
        .child("${DateTime.now().millisecondsSinceEpoch}.mp4");

    await ref.putFile(archivo);
    return await ref.getDownloadURL();
  }

  // 💾 Guardar reporte en Firestore
  Future<bool> guardarReporte() async {
    try {
      _cargando = true;
      notifyListeners();

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final docRef = FirebaseFirestore.instance
          .collection("reportes_mascotas")
          .doc();

      reporte.id = docRef.id;

      // Guardar en Firestore sin análisis IA adicional
      await docRef.set(
        reporte.toMap()..addAll({
          "usuarioId": uid,
          "fechaRegistro": FieldValue.serverTimestamp(),
          "estado": "perdido",
        }),
      );

      // 🔔 Enviar notificación push global
      await NotificacionServicio.enviarPush(
        titulo: "Nuevo reporte 🐾",
        cuerpo: "Se ha registrado una nueva mascota perdida.",
      );

      _cargando = false;
      notifyListeners();
      return true;
    } catch (e) {
      _cargando = false;
      notifyListeners();
      debugPrint("Error al guardar reporte: $e");
      return false;
    }
  }
}
