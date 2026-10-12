import 'package:flutter/material.dart';

import '../models/sensor_mode.dart';
import '../services/acceleration_service.dart';

/// Pantalla principal de la app. Es un StatefulWidget porque el número
/// que se muestra en pantalla cambia con el tiempo (cada vez que el
/// sensor manda un nuevo dato), y StatelessWidget no permite eso.
class AccelHomePage extends StatefulWidget {
  const AccelHomePage({super.key});

  @override
  State<AccelHomePage> createState() => _AccelHomePageState();
}

class _AccelHomePageState extends State<AccelHomePage> {
  // Una sola instancia del servicio para toda la pantalla.
  final AccelerationService _service = AccelerationService();

  // Variables de estado: todo lo que al cambiar debe redibujar la
  // pantalla vive aquí.
  SensorMode _mode = SensorMode.raw;
  double _maxMagnitude = 0;

  @override
  void initState() {
    super.initState();

    // Le decimos al servicio: "cuando tengas un nuevo máximo, avísame".
    // setState() es lo que le dice a Flutter "algo cambió, redibuja".
    _service.onNewMax = (newMax) => setState(() => _maxMagnitude = newMax);

    // Arrancamos a escuchar el sensor apenas se abre la pantalla.
    _service.start(_mode);
  }

  /// Se ejecuta cuando el usuario toca el selector de modo (crudo/filtrado).
  void _changeMode(SensorMode newMode) {
    if (newMode == _mode) return; // nada que hacer si no cambió

    // Reiniciamos el máximo para que la comparación entre modos sea
    // justa (si no, el valor viejo de un modo "contaminaría" al otro).
    _service.reset();
    setState(() {
      _mode = newMode;
      _maxMagnitude = 0;
    });

    // Re-suscribimos al stream correspondiente al nuevo modo.
    _service.start(_mode);
  }

  /// Botón "Reiniciar": vuelve el contador a cero sin cambiar de modo.
  void _reset() {
    _service.reset();
    setState(() => _maxMagnitude = 0);
  }

  @override
  void dispose() {
    // Importante: apagamos el servicio cuando se destruye la pantalla,
    // para no dejar el sensor escuchando en segundo plano sin necesidad.
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isRaw = _mode == SensorMode.raw;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Acelerómetro'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Selector de modo, separado como su propio widget (ver abajo).
            _ModeSelector(mode: _mode, onChanged: _changeMode),
            const SizedBox(height: 32),

            // Etiqueta que indica en qué modo estamos viendo el resultado.
            Text(
              isRaw
                  ? 'Aceleración máxima (crudo)'
                  : 'Aceleración máxima (filtrado)',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // El número grande: el valor máximo registrado hasta ahora.
            Text(
              _maxMagnitude.toStringAsFixed(2),
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),
            const Text('m/s²', style: TextStyle(fontSize: 20, color: Colors.grey)),
            const SizedBox(height: 40),

            // Botón para reiniciar el contador y repetir la demo.
            ElevatedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh),
              label: const Text('Reiniciar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget aparte solo para el selector de modo (crudo/filtrado).
/// Lo separamos del widget principal para que build() de la pantalla
/// no quede tan largo, y porque este pedazo de UI no necesita saber
/// nada del resto de la pantalla: solo recibe el modo actual y avisa
/// cuando el usuario elige otro.
class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final SensorMode mode;
  final ValueChanged<SensorMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SensorMode>(
      segments: const [
        ButtonSegment(
          value: SensorMode.raw,
          label: Text('Crudo (con gravedad)'),
          icon: Icon(Icons.public),
        ),
        ButtonSegment(
          value: SensorMode.filtered,
          label: Text('Filtrado (sin gravedad)'),
          icon: Icon(Icons.filter_alt),
        ),
      ],
      selected: {mode},
      // selection.first porque SegmentedButton soporta selección múltiple,
      // pero aquí siempre queremos exactamente un modo elegido.
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
