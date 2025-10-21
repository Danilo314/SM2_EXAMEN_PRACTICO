import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();

  String? _fotoUrl;
  bool cargando = true;
  int _currentIndex = 4;

  bool notificacionesPush = true;
  bool alertasEmail = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection("usuarios")
        .doc(uid)
        .get();

    if (doc.exists) {
      final d = doc.data()!;
      _nombreCtrl.text = d["nombre"] ?? "";
      _correoCtrl.text = d["correo"] ?? "";
      _telefonoCtrl.text = d["telefono"] ?? "";
      _ubicacionCtrl.text = d["ubicacion"] ?? "";
      _fotoUrl = d["fotoPerfil"];
    }

    setState(() => cargando = false);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection("usuarios").doc(uid).update({
      "telefono": _telefonoCtrl.text.trim(),
      "ubicacion": _ubicacionCtrl.text.trim(),
      "fotoPerfil": _fotoUrl ?? "",
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Perfil actualizado")));
  }

  Future<void> _cambiarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance.ref().child(
      "usuarios/$uid/perfil.jpg",
    );

    await ref.putFile(File(picked.path));
    final url = await ref.getDownloadURL();

    setState(() => _fotoUrl = url);
    await FirebaseFirestore.instance.collection("usuarios").doc(uid).update({
      "fotoPerfil": url,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEAF0FB),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        title: const Text(
          "Mi perfil",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _guardar,
            child: const Text(
              "Guardar",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SafeArea(
        // 👈 evita que la barra del celular tape la UI
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // 📸 Foto de perfil
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _cambiarFoto,
                        child: CircleAvatar(
                          radius: 55,
                          backgroundImage: _fotoUrl != null
                              ? NetworkImage(_fotoUrl!)
                              : null,
                          backgroundColor: Colors.white,
                          child: _fotoUrl == null
                              ? const Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: Colors.teal,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Cambiar foto de perfil",
                        style: TextStyle(color: Colors.teal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 🧾 Información Personal
                _buildSection(
                  "Información Personal",
                  Column(
                    children: [
                      _buildReadOnlyField("Nombre completo", _nombreCtrl),
                      const SizedBox(height: 12),
                      _buildReadOnlyField("Correo electrónico", _correoCtrl),
                      const SizedBox(height: 12),
                      _buildEditableField("Teléfono", _telefonoCtrl),
                      const SizedBox(height: 12),
                      _buildEditableField(
                        "Ubicación",
                        _ubicacionCtrl,
                        icon: Icons.location_on,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 🔔 Preferencias
                _buildSection(
                  "Preferencias",
                  Column(
                    children: [
                      SwitchListTile(
                        value: notificacionesPush,
                        onChanged: (v) =>
                            setState(() => notificacionesPush = v),
                        title: const Text("Notificaciones push"),
                        subtitle: const Text(
                          "Recibir alertas de mascotas perdidas",
                        ),
                      ),
                      SwitchListTile(
                        value: alertasEmail,
                        onChanged: (v) => setState(() => alertasEmail = v),
                        title: const Text("Alertas por email"),
                        subtitle: const Text("Recibir reportes por correo"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 🔒 Seguridad
                _buildSection(
                  "Seguridad",
                  Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock, color: Colors.teal),
                        title: const Text("Cambiar contraseña"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          FirebaseAuth.instance.sendPasswordResetEmail(
                            email: _correoCtrl.text.trim(),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Enlace enviado a tu correo"),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ⚠️ Zona de peligro
                _buildSection(
                  "Zona de peligro",
                  Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.block, color: Colors.orange),
                        title: const Text("Desactivar cuenta"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // 🚨 lógica pendiente
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        title: const Text("Eliminar cuenta"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final uid = FirebaseAuth.instance.currentUser!.uid;
                          await FirebaseFirestore.instance
                              .collection("usuarios")
                              .doc(uid)
                              .delete();
                          await FirebaseAuth.instance.currentUser!.delete();
                          if (!mounted) return;
                          Navigator.pushReplacementNamed(context, "/login");
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // 📌 Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _currentIndex = index);

          if (index == 0) Navigator.pushReplacementNamed(context, "/inicio");
          if (index == 1) Navigator.pushNamed(context, "/buscar");
          if (index == 2) Navigator.pushNamed(context, "/reportar");
          if (index == 3) Navigator.pushNamed(context, "/mapa");
          if (index == 4) Navigator.pushReplacementNamed(context, "/perfil");
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Buscar"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Reportar"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Mapa"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }

  // 📦 Widgets reutilizables
  Widget _buildSection(String title, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const Divider(),
          content,
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController ctrl, {
    IconData? icon,
  }) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.teal) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
