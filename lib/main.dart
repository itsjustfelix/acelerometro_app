import 'package:flutter/material.dart';

import 'screens/accel_home_page.dart';

// Punto de entrada de toda app Flutter: esta función es la primera
// que se ejecuta.
void main() {
  runApp(const AccelApp());
}

/// Widget raíz de la app. Es un StatelessWidget porque no cambia nada
/// aquí en el tiempo: solo configura el tema y dice cuál es la
/// pantalla inicial (AccelHomePage). Toda la lógica real vive allá.
class AccelApp extends StatelessWidget {
  const AccelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aceleración Máxima',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const AccelHomePage(),
    );
  }
}
