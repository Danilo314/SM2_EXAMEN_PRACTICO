import 'package:cloud_firestore/cloud_firestore.dart';

class InicioSesion {
  final String uidUsuario;
  final DateTime fecha;
  final String direccionIp;
  final String dispositivo;

  InicioSesion({
    required this.uidUsuario,
    required this.fecha,
    required this.direccionIp,
    required this.dispositivo,
  });

  Map<String, dynamic> toMap() => {
        'uidUsuario': uidUsuario,
        'fecha': Timestamp.fromDate(fecha),
        'direccionIp': direccionIp,
        'dispositivo': dispositivo,
      };

  factory InicioSesion.fromMap(Map<String, dynamic> map) {
    return InicioSesion(
      uidUsuario: map['uidUsuario'] as String,
      fecha: (map['fecha'] as Timestamp).toDate(),
      direccionIp: map['direccionIp'] as String,
      dispositivo: map['dispositivo'] as String,
    );
  }
}
