import 'package:flutter/material.dart';

class PantallaDetalleCompleto extends StatelessWidget {
  final Map<String, dynamic> data;
  final String tipo;

  const PantallaDetalleCompleto({
    super.key,
    required this.data,
    required this.tipo,
  });

  @override
  Widget build(BuildContext context) {
    final esReporte = tipo == "reporte";
    final fotos = (data["fotos"] ?? []) as List;
    final urlFoto = esReporte
        ? (fotos.isNotEmpty ? fotos.first : null)
        : (data["foto"] ?? "");

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(
          esReporte ? "Detalle del Reporte" : "Detalle del Avistamiento",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 Imagen principal
            Center(
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
                        color: Colors.grey.shade200,
                        child: Icon(
                          esReporte ? Icons.pets : Icons.visibility,
                          color: esReporte ? Colors.teal : Colors.orange,
                          size: 100,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // 🐾 Título
            Text(
              esReporte
                  ? (data["nombre"] ?? "Mascota sin nombre")
                  : (data["direccion"] ?? "Zona no especificada"),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const Divider(height: 30),

            // 📋 Datos generales
            if (esReporte) ...[
              _infoItem("Tipo", data["tipo"]),
              _infoItem("Raza", data["raza"]),
              _infoItem("Características", data["caracteristicas"]),
              _infoItem("Dirección", data["direccion"]),
              _infoItem("Distrito", data["distrito"]),
              _infoItem("Fecha", data["fechaRegistro"]),
            ] else ...[
              _infoItem("Fecha", data["fechaAvistamiento"]),
              _infoItem("Hora", data["horaAvistamiento"]),
              _infoItem("Descripción", data["descripcion"]),
              _infoItem("Dirección", data["direccion"]),
            ],

            const SizedBox(height: 20),

            // 📍 Mapa o ubicación (opcional si tienes lat/lng)
            if (data["latitud"] != null && data["longitud"] != null)
              _infoItem(
                "Ubicación GPS",
                "${data["latitud"]}, ${data["longitud"]}",
              ),

            const SizedBox(height: 30),

            // ✅ Contacto (se puede integrar más adelante con chat directo)
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text("Contactar con el publicador"),
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Chat directo en desarrollo 📞"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String titulo, dynamic valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$titulo: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              valor?.toString() ?? "No especificado",
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
