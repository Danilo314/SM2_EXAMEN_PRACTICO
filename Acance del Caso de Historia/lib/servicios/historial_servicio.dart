import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sos_mascotas/modelo/inicio_sesion.dart';

class HistorialServicio {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> registrarInicio(InicioSesion inicio) async {
    // Guardar como subcolección dentro del documento del usuario para evitar
    // la necesidad de índices compuestos en consultas sencillas.
    final docRef = _db
        .collection('usuarios')
        .doc(inicio.uidUsuario)
        .collection('inicios')
        .doc();
    await docRef.set(inicio.toMap());
  }

  Stream<List<InicioSesion>> obtenerHistorialPorUsuario(String uid) {
    // Leer desde la subcolección del usuario y ordenar por fecha descendente
    return _db
        .collection('usuarios')
        .doc(uid)
        .collection('inicios')
        .orderBy('fecha', descending: true)
    .snapshots()
    .map((snap) => snap.docs
      .map((d) => InicioSesion.fromMap(d.data()))
      .toList());
  }
}
