import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sos_mascotas/vistamodelo/notificacion/notificacion_vm.dart';
import 'package:sos_mascotas/vista/chat/pantalla_chats_activos.dart';
import 'package:provider/provider.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("usuarios")
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text("Cargando...");
            }

            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final nombre = data["nombre"] ?? "Usuario";
            final fotoPerfil = data["fotoPerfil"];

            return Row(
              children: [
                // 👤 Avatar clickeable
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, "/perfil"),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        (fotoPerfil != null && fotoPerfil.toString().isNotEmpty)
                        ? NetworkImage(fotoPerfil)
                        : null,
                    child: (fotoPerfil == null || fotoPerfil.toString().isEmpty)
                        ? const Icon(Icons.person, color: Colors.teal)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),

                // 👋 Nombre clickeable
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, "/perfil"),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "¡Hola, $nombre!",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const Text(
                        "Ayudemos a encontrar mascotas",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),

        actions: [
          Consumer<NotificacionVM>(
            builder: (context, vm, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.teal),
                    onPressed: () async {
                      Navigator.pushNamed(context, "/notificaciones");
                      // ✅ Marca todas como leídas al abrir la pantalla
                      await vm.marcarTodasComoLeidas();
                    },
                  ),
                  if (vm.noLeidas > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${vm.noLeidas}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.teal),
            onSelected: (value) async {
              if (value == 'logout') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Cerrar sesión"),
                    content: const Text("¿Seguro que deseas cerrar sesión?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancelar"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Cerrar sesión",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      "/login",
                      (route) => false,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Sesión cerrada correctamente"),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 10),
                    Text("Cerrar sesión"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 Buscador
            TextField(
              decoration: InputDecoration(
                hintText: "Buscar mascotas perdidas...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // ⚡ Acciones rápidas
            const Text(
              "Acciones Rápidas",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    Icons.add_circle,
                    "Reportar Mascota",
                    Colors.purple,
                    onTap: () {
                      Navigator.pushNamed(context, "/reportarMascota");
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    Icons.visibility,
                    "Registrar Avistamiento",
                    Colors.orange,
                    onTap: () {
                      Navigator.pushNamed(context, "/avistamiento");
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    Icons.map,
                    "Mapa Interactivo",
                    Colors.teal,
                    onTap: () {
                      Navigator.pushNamed(context, "/mapa");
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 📋 Menú principal
            const Text(
              "Menú Principal",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildMenuItem(
              Icons.pets,
              "Ver Mascotas Reportadas",
              "Explora todos los reportes",
              onTap: () => Navigator.pushNamed(context, "/verReportes"),
            ),
            _buildMenuItem(
              Icons.assignment,
              "Mis Reportes",
              "Gestiona tus publicaciones",
              onTap: () => Navigator.pushNamed(context, "/misReportes"),
            ),
            _buildMenuItem(Icons.favorite, "Favoritos", "Mascotas que sigues"),
            _buildMenuItem(
              Icons.chat,
              "Chats",
              "Conversaciones activas",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PantallaChatsActivos()),
              ),
            ),
            _buildMenuItem(
              Icons.person,
              "Mi Perfil",
              "Configuración de cuenta",
              onTap: () => Navigator.pushNamed(context, "/perfil"),
            ),
            _buildMenuItem(
              Icons.history,
              "Historial de inicios",
              "Ver registros de inicio de sesión",
              onTap: () => Navigator.pushNamed(context, "/historialInicios"),
            ),
          ],
        ),
      ),

      // 📌 Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _currentIndex = index);

          if (index == 4) {
            // 👈 Perfil es el 5to item (0-based)
            Navigator.pushNamed(context, "/perfil");
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Buscar"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Reportar"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Mapa"),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Perfil",
          ), // ✅ aquí
        ],
      ),
    );
  }

  Widget _buildActionCard(
    IconData icon,
    String title,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
