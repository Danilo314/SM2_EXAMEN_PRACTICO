import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validaciones de registro', () {
    test('Correo inválido debe fallar', () {
      final correo = "usuario.com";
      final esValido = correo.contains("@");
      expect(esValido, false);
    });

    test('Contraseña demasiado corta', () {
      final clave = "123";
      final esValida = clave.length >= 6;
      expect(esValida, false);
    });

    test('Teléfono solo números', () {
      final telefono = "987abc";
      final esValido = RegExp(r'^[0-9]+$').hasMatch(telefono);
      expect(esValido, false);
    });
  });
}
