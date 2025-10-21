import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sos_mascotas/servicios/historial_servicio.dart';
import 'package:sos_mascotas/modelo/inicio_sesion.dart';

class HistorialIniciosPage extends StatelessWidget {
  const HistorialIniciosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Historial de inicios')),
        body: const Center(child: Text('Debes iniciar sesión para ver el historial.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de inicios')),
      body: StreamBuilder<List<InicioSesion>>(
        stream: HistorialServicio().obtenerHistorialPorUsuario(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No hay inicios registrados.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final i = items[index];
              return ListTile(
                title: Text(user.email ?? i.uidUsuario),
                subtitle: Text(
                    '${i.fecha.toLocal()} — ${i.dispositivo}\nIP: ${i.direccionIp}'),
                isThreeLine: true,
                leading: const Icon(Icons.login),
              );
            },
          );
        },
      ),
    );
  }
}
