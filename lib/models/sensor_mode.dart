// Este enum representa en qué modo está trabajando el sensor.
// Lo usamos en vez de un simple booleano (true/false) porque así el
// código se lee solo: "SensorMode.raw" dice más que "modoCrudo = true".
enum SensorMode {
  raw, // Acelerómetro "crudo": incluye la gravedad en la lectura.
  filtered, // Acelerómetro filtrado: la gravedad ya fue restada por el OS.
}
