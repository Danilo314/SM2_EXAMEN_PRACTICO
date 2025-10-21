import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'pantalla_detalle_reporte.dart';
import '../chat/pantalla_chat.dart'; // 🧩 nueva pantalla del chat

class PantallaVerReportes extends StatefulWidget {
  const PantallaVerReportes({super.key});

  @override
  State<PantallaVerReportes> createState() => _PantallaVerReportesState();
}

class _PantallaVerReportesState extends State<PantallaVerReportes> {
  String filtroRaza = "";
  String filtroZona = "";

  final _reportesRef = FirebaseFirestore.instance
      .collection("reportes_mascotas")
      .orderBy("fechaRegistro", descending: true);

  final _avistamientosRef = FirebaseFirestore.instance
      .collection("avistamientos")
      .orderBy("fechaRegistro", descending: true);

  void _mostrarDetalle(
    BuildContext context,
    Map<String, dynamic> data,
    String tipo,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TarjetaDetalle(data: data, tipo: tipo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: const Text(
            "Reportes y Avistamientos",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.teal,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(icon: Icon(Icons.pets), text: "Reportes"),
              Tab(icon: Icon(Icons.visibility), text: "Avistamientos"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ListaReportes(
              stream: _reportesRef.snapshots(),
              tipo: "reporte",
              onTapItem: (data) => _mostrarDetalle(context, data, "reporte"),
            ),
            _ListaReportes(
              stream: _avistamientosRef.snapshots(),
              tipo: "avistamiento",
              onTapItem: (data) =>
                  _mostrarDetalle(context, data, "avistamiento"),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaReportes extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String tipo;
  final Function(Map<String, dynamic>) onTapItem;

  const _ListaReportes({
    required this.stream,
    required this.tipo,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Text(
              tipo == "reporte"
                  ? "No hay reportes disponibles 🐾"
                  : "No hay avistamientos registrados 👀",
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final fotos = (data["fotos"] ?? []) as List;
            final urlFoto = tipo == "reporte"
                ? (fotos.isNotEmpty ? fotos.first : null)
                : (data["foto"] ?? "");

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: (urlFoto != null && urlFoto.toString().isNotEmpty)
                      ? Image.network(
                          urlFoto,
                          width: 55,
                          height: 55,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 55,
                          height: 55,
                          color: Colors.teal.shade50,
                          child: Icon(
                            tipo == "reporte" ? Icons.pets : Icons.visibility,
                            color: tipo == "reporte"
                                ? Colors.teal
                                : Colors.orange,
                          ),
                        ),
                ),
                title: Text(
                  tipo == "reporte"
                      ? (data["nombre"] ?? "Mascota sin nombre")
                      : (data["direccion"] ?? "Zona no especificada"),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  tipo == "reporte"
                      ? "${data["tipo"] ?? ""} • ${data["raza"] ?? ""}\nZona: ${data["direccion"] ?? ""}"
                      : "Fecha: ${data["fechaAvistamiento"] ?? ""} "
                            "Hora: ${data["horaAvistamiento"] ?? ""}\n"
                            "${data["descripcion"] ?? ""}",
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () => onTapItem(data),
              ),
            );
          },
        );
      },
    );
  }
}

/// Tarjeta flotante con información completa y botón para contactar
class _TarjetaDetalle extends StatelessWidget {
  final Map<String, dynamic> data;
  final String tipo;

  const _TarjetaDetalle({required this.data, required this.tipo});

  Future<void> _contactar(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes iniciar sesión para chatear")),
      );
      return;
    }

    final publicadorId = data["usuarioId"];
    final reporteId = data["id"] ?? "";

    if (publicadorId == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No puedes chatear contigo mismo.")),
      );
      return;
    }

    // 🔍 Buscar si ya existe un chat entre ambos por este reporte
    final chatExistente = await FirebaseFirestore.instance
        .collection("chats")
        .where("publicadorId", isEqualTo: publicadorId)
        .where("usuarioId", isEqualTo: user.uid)
        .where("reporteId", isEqualTo: reporteId)
        .limit(1)
        .get();

    String chatId;
    if (chatExistente.docs.isNotEmpty) {
      chatId = chatExistente.docs.first.id;
    } else {
      // 🆕 Crear nuevo chat
      final nuevoChat = await FirebaseFirestore.instance
          .collection("chats")
          .add({
            "reporteId": reporteId,
            "tipo": tipo,
            "publicadorId": publicadorId,
            "usuarioId": user.uid,
            "usuarios": [publicadorId, user.uid], // 👈 campo clave
            "fechaInicio": FieldValue.serverTimestamp(),
          });
      chatId = nuevoChat.id;
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PantallaChat(
            chatId: chatId,
            reporteId: reporteId,
            tipo: tipo,
            publicadorId: publicadorId,
            usuarioId: user.uid,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fotos = (data["fotos"] ?? []) as List;
    final urlFoto = tipo == "reporte"
        ? (fotos.isNotEmpty ? fotos.first : null)
        : (data["foto"] ?? "");

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: controller,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (urlFoto != null && urlFoto.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PantallaDetalleReporte(
                            imagenUrl: urlFoto,
                            titulo: data["nombre"] ?? "Foto",
                          ),
                        ),
                      );
                    }
                  },
                  child: Hero(
                    tag: urlFoto ?? "",
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: urlFoto != null && urlFoto.isNotEmpty
                          ? Image.network(
                              urlFoto,
                              height: 250,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              height: 250,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.pets,
                                size: 100,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                tipo == "reporte"
                    ? (data["nombre"] ?? "Mascota sin nombre")
                    : (data["direccion"] ?? "Zona no especificada"),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              const SizedBox(height: 10),
              if (tipo == "reporte") ...[
                _infoRow("Tipo", data["tipo"]),
                _infoRow("Raza", data["raza"]),
                _infoRow("Características", data["caracteristicas"]),
                _infoRow("Dirección", data["direccion"]),
                _infoRow("Distrito", data["distrito"]),
              ] else ...[
                _infoRow("Fecha", data["fechaAvistamiento"]),
                _infoRow("Hora", data["horaAvistamiento"]),
                _infoRow("Descripción", data["descripcion"]),
                _infoRow("Dirección", data["direccion"]),
              ],
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _contactar(context),
                  label: const Text("Contactar con publicador"),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? "No especificado")),
        ],
      ),
    );
  }
}
