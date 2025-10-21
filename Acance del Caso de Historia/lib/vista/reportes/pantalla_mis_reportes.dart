import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class PantallaMisReportes extends StatelessWidget {
  const PantallaMisReportes({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Inicia sesión para ver tus reportes.")),
      );
    }

    final reportesRef = FirebaseFirestore.instance
        .collection("reportes_mascotas")
        .where("usuarioId", isEqualTo: uid)
        .orderBy("fechaRegistro", descending: true);

    final avistamientosRef = FirebaseFirestore.instance
        .collection("avistamientos")
        .where("usuarioId", isEqualTo: uid)
        .orderBy("fechaRegistro", descending: true);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: Colors.teal,
          title: const Text(
            "Mis Reportes",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.pets), text: "Reportes"),
              Tab(icon: Icon(Icons.visibility), text: "Avistamientos"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ListaReportes(stream: reportesRef.snapshots(), tipo: "reporte"),
            _ListaReportes(
              stream: avistamientosRef.snapshots(),
              tipo: "avistamiento",
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

  const _ListaReportes({required this.stream, required this.tipo});

  Future<void> _eliminar(
    BuildContext context,
    String docId,
    String? fotoUrl,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar registro"),
        content: const Text(
          "¿Estás seguro de que deseas eliminar este registro?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 🔥 Eliminar documento
      final collection = tipo == "reporte"
          ? "reportes_mascotas"
          : "avistamientos";
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .delete();

      // 🧹 Eliminar foto si existe
      if (fotoUrl != null && fotoUrl.isNotEmpty) {
        final ref = FirebaseStorage.instance.refFromURL(fotoUrl);
        await ref.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registro eliminado correctamente."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al eliminar: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _editar(BuildContext context, Map<String, dynamic> data, String docId) {
    final TextEditingController descripcionCtrl = TextEditingController(
      text: data["descripcion"] ?? "",
    );
    final TextEditingController direccionCtrl = TextEditingController(
      text: data["direccion"] ?? "",
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Editar"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tipo == "avistamiento")
              TextFormField(
                controller: descripcionCtrl,
                decoration: const InputDecoration(
                  labelText: "Descripción del avistamiento",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            if (tipo == "reporte") ...[
              TextFormField(
                controller: direccionCtrl,
                decoration: const InputDecoration(
                  labelText: "Dirección",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final collection = tipo == "reporte"
                    ? "reportes_mascotas"
                    : "avistamientos";
                final updates = tipo == "reporte"
                    ? {"direccion": direccionCtrl.text}
                    : {"descripcion": descripcionCtrl.text};

                await FirebaseFirestore.instance
                    .collection(collection)
                    .doc(docId)
                    .update(updates);

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Cambios guardados correctamente."),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error al guardar: $e"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              tipo == "reporte"
                  ? "No has registrado ningún reporte aún 🐾"
                  : "No has registrado ningún avistamiento 👀",
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final id = docs[i].id;
            final fotos = (data["fotos"] ?? []) as List;
            final urlFoto = tipo == "reporte"
                ? (fotos.isNotEmpty ? fotos.first : null)
                : (data["foto"] ?? "");

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                          color: tipo == "reporte"
                              ? Colors.teal.shade50
                              : Colors.orange.shade50,
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
                      : (data["direccion"] ?? "Ubicación no especificada"),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  tipo == "reporte"
                      ? "${data["tipo"] ?? ""} • ${data["raza"] ?? ""}\n${data["direccion"] ?? ""}"
                      : "Fecha: ${data["fechaAvistamiento"] ?? ""} "
                            "Hora: ${data["horaAvistamiento"] ?? ""}\n"
                            "${data["descripcion"] ?? ""}",
                  style: const TextStyle(color: Colors.grey),
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'editar') {
                      _editar(context, data, id);
                    } else if (value == 'eliminar') {
                      _eliminar(context, id, urlFoto);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
