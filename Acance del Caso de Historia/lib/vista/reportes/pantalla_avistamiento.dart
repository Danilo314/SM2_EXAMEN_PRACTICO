import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sos_mascotas/vistamodelo/reportes/avistamiento_vm.dart';
import 'package:sos_mascotas/vista/reportes/pantalla_mapa_osm.dart';

class PantallaAvistamiento extends StatelessWidget {
  const PantallaAvistamiento({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AvistamientoVM(),
      child: const _FormularioAvistamiento(),
    );
  }
}

class _FormularioAvistamiento extends StatefulWidget {
  const _FormularioAvistamiento();

  @override
  State<_FormularioAvistamiento> createState() =>
      _FormularioAvistamientoState();
}

class _FormularioAvistamientoState extends State<_FormularioAvistamiento> {
  final formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  late TextEditingController direccionCtrl;
  late TextEditingController fechaCtrl;
  late TextEditingController horaCtrl;
  late TextEditingController descripcionCtrl;

  File? imagenSeleccionada;

  @override
  void initState() {
    super.initState();
    direccionCtrl = TextEditingController();
    fechaCtrl = TextEditingController();
    horaCtrl = TextEditingController();
    descripcionCtrl = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AvistamientoVM>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrar Avistamiento"),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "📸 Foto del avistamiento",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // 🖼️ Vista previa
              if (imagenSeleccionada != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      imagenSeleccionada!,
                      height: 180,
                      width: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // 📸 Botón seleccionar imagen
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text("Seleccionar foto"),
                  onPressed: () async {
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked != null) {
                      setState(() => imagenSeleccionada = File(picked.path));

                      try {
                        // 🧠 Validar y subir con OpenAI
                        final url = await vm.subirFoto(File(picked.path));
                        vm.avistamiento.foto = url;

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "✅ Imagen validada y subida con éxito",
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(
                          () => imagenSeleccionada = null,
                        ); // limpiar preview
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceAll("Exception: ", ""),
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "📍 Dirección del avistamiento",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: direccionCtrl,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Seleccionar desde el mapa",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map_outlined),
                    onPressed: () async {
                      final resultado = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PantallaMapaOSM(),
                        ),
                      );

                      if (resultado != null) {
                        vm.actualizarUbicacion(
                          direccion: resultado['direccion'] ?? '',
                          distrito: resultado['distrito'] ?? '',
                          latitud: resultado['lat'],
                          longitud: resultado['lng'],
                        );
                        direccionCtrl.text = resultado['direccion'] ?? '';
                      }
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? "Seleccione una ubicación"
                    : null,
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: fechaCtrl,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Fecha del avistamiento",
                  suffixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onTap: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (fecha != null) {
                    vm.avistamiento.fechaAvistamiento =
                        "${fecha.day}/${fecha.month}/${fecha.year}";
                    fechaCtrl.text = vm.avistamiento.fechaAvistamiento;
                  }
                },
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Seleccione la fecha" : null,
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: horaCtrl,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Hora aproximada",
                  suffixIcon: const Icon(Icons.access_time),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onTap: () async {
                  final hora = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (hora != null) {
                    vm.avistamiento.horaAvistamiento =
                        "${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}";
                    horaCtrl.text = vm.avistamiento.horaAvistamiento;
                  }
                },
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Seleccione la hora" : null,
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: descripcionCtrl,
                decoration: InputDecoration(
                  labelText: "Descripción del avistamiento",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
                onChanged: (v) => vm.setDescripcion(v),
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Ingrese una descripción" : null,
              ),

              const SizedBox(height: 30),

              // 🔘 Botón de guardar
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 16,
                    ),
                  ),
                  icon: vm.cargando
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    vm.cargando ? "Guardando..." : "Guardar avistamiento",
                    style: const TextStyle(fontSize: 16),
                  ),
                  onPressed: vm.cargando
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          if (vm.avistamiento.foto.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Debes subir una foto válida antes de guardar.",
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          final ok = await vm.guardarAvistamiento();
                          if (ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "✅ Avistamiento guardado correctamente.",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
