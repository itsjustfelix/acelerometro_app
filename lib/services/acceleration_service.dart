import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

import '../models/sensor_mode.dart';

/// Esta clase es el "cerebro" de la app: todo lo que tiene que ver con
/// hablar con el sensor vive aquí adentro, y SOLO aquí.
///
/// La pantalla (la UI) no sabe nada de streams, de sensors_plus, ni de
/// cómo se calcula la magnitud. Solo le dice a este servicio "arranca" o
/// "reinicia", y se queda escuchando cuando este avisa que hay un dato
/// nuevo. Esto se llama separar responsabilidades: cada clase hace una
/// sola cosa y la hace bien.
class AccelerationService {
  // Guardamos la "conexión" (suscripción) a cada stream posible.
  // Solo una de las dos va a estar activa a la vez, según el modo.
  StreamSubscription<AccelerometerEvent>? _rawSubscription;
  StreamSubscription<UserAccelerometerEvent>? _filteredSubscription;

  // El valor más alto de aceleración que hemos visto hasta ahora.
  // Es privado (el guion bajo) para que nadie de afuera lo pueda
  // modificar directamente; solo se puede LEER con el getter de abajo.
  double _maxMagnitude = 0;
  double get maxMagnitude => _maxMagnitude;

  // Estas dos son "funciones callback": la pantalla las va a rellenar
  // para enterarse de lo que pasa adentro del servicio, sin que el
  // servicio tenga que conocer a la pantalla.
  //
  // onReading: se dispara con CADA dato que llega del sensor.
  void Function(double magnitude)? onReading;
  // onNewMax: se dispara SOLO cuando ese dato es un nuevo récord.
  void Function(double newMax)? onNewMax;

  /// Empieza a escuchar el sensor en el modo indicado.
  /// Si ya había una suscripción activa, la cancela primero.
  void start(SensorMode mode) {
    _cancelSubscriptions();

    if (mode == SensorMode.raw) {
      // accelerometerEventStream() = sensor crudo, CON gravedad.
      _rawSubscription = accelerometerEventStream().listen((event) {
        _handleSample(event.x, event.y, event.z);
      });
    } else {
      // userAccelerometerEventStream() = sensor filtrado, SIN gravedad.
      _filteredSubscription = userAccelerometerEventStream().listen((event) {
        _handleSample(event.x, event.y, event.z);
      });
    }
  }

  /// Se ejecuta cada vez que llega un dato nuevo del sensor (varias
  /// veces por segundo). Aquí se hace el cálculo matemático real.
  void _handleSample(double x, double y, double z) {
    // Magnitud del vector de aceleración: raíz(x² + y² + z²).
    final double magnitude = sqrt(x * x + y * y + z * z);

    // Avisamos el dato "en crudo" por si alguien quiere mostrarlo en
    // tiempo real (en nuestra app no lo usamos, pero queda disponible).
    onReading?.call(magnitude);

    // Si este dato es mayor al máximo que teníamos, lo actualizamos
    // y avisamos con onNewMax para que la pantalla se refresque.
    if (magnitude > _maxMagnitude) {
      _maxMagnitude = magnitude;
      onNewMax?.call(_maxMagnitude);
    }
  }

  /// Pone el máximo de nuevo en cero (botón "Reiniciar").
  void reset() {
    _maxMagnitude = 0;
  }

  /// Cancela cualquier suscripción activa, para no tener dos streams
  /// escuchando el sensor al mismo tiempo.
  void _cancelSubscriptions() {
    _rawSubscription?.cancel();
    _filteredSubscription?.cancel();
    _rawSubscription = null;
    _filteredSubscription = null;
  }

  /// Hay que llamar esto desde el dispose() de quien use el servicio,
  /// para apagar el sensor cuando la pantalla se cierra y no gastar
  /// batería de más.
  void dispose() {
    _cancelSubscriptions();
  }
}
