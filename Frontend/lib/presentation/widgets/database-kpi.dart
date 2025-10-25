import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Necesario para toLocaleTimeString

// Importamos el SensorRepository que contiene la lógica de datos
import '../../domain/repository/sensorRepository.dart';
import '../../domain/models/dto/sensor_record_model.dart';
// Ajusta los imports según la ubicación real de tus archivos

// Usamos el repository que ya definimos
final SensorRepository _sensorRepository = SensorRepository();

class DatabaseKPI extends StatefulWidget {
  const DatabaseKPI({super.key});

  @override
  State<DatabaseKPI> createState() => _DatabaseKPIState();
}

class _DatabaseKPIState extends State<DatabaseKPI> {
  int _count = 0;
  DateTime _lastUpdateTime = DateTime.now();
  StreamSubscription<List<SensorRecordModel>>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Equivalente al useEffect y a fetchInitialCount
  Future<void> _initializeData() async {
    await _fetchInitialCount();
    _openStream();
  }

  Future<void> _fetchInitialCount() async {
    try {
      final now = DateTime.now();
      // Calcular la fecha de inicio (inicio del día de hoy)
      final today = DateTime(now.year, now.month, now.day);

      // La función getHistoryData espera objetos DateTime/Instant, no Strings ISO
      final initialData = await _sensorRepository.getHistoryData(
        from: today,
        to: now,
      );

      if (mounted) {
        setState(() {
          _count = initialData.length;
        });
      }
    } catch (error) {
      // Manejo de error equivalente a console.error
      debugPrint("Error fetching initial data count: $error");
    }
  }

  // Equivalente a const eventSource = streamSensorData(...)
  void _openStream() {
    // Suscribirse al Stream SSE devuelto por el repositorio
    _streamSubscription = _sensorRepository.streamSensorData().listen(
          (data) {
        // Callback para el Stream
        if (mounted) {
          setState(() {
            // data es List<SensorRecordModel>, actualizamos el conteo sumando la longitud
            _count += data.length;
            _lastUpdateTime = DateTime.now();
          });
        }
      },
      onError: (error) {
        debugPrint('Error en el stream SSE: $error');
        // Aquí puedes mostrar un Toast o SnackBar
      },
      onDone: () {
        debugPrint('Stream SSE cerrado.');
      },
    );
  }

  @override
  void dispose() {
    // Equivalente a return () => eventSource.close();
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Formateador para la hora (toLocaleTimeString)
    final timeFormatter = DateFormat('HH:mm');
    final formattedTime = timeFormatter.format(_lastUpdateTime);

    // Formateador para el conteo (toLocaleString)
    final countFormatter = NumberFormat.decimalPattern('es_ES');

    return Card(
      elevation: 8,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // Recreación del Card y el degradado de fondo (bg-gradient-to-br)
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          // from-[#1E2952] to-[#002FA7]
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E2952), // from-[#1E2952]
              Color(0xFF002FA7), // to-[#002FA7]
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sección superior: Iconos, Título y Tendencia
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icono y Título
                Row(
                  children: [
                    // Icono (p-3 bg-[#89CFF0]/20 rounded-lg)
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF89CFF0).withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.storage_rounded, // Equivalente a Database
                        color: Color(0xFF89CFF0), // text-[#89CFF0]
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Total de Datos",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF89CFF0), // text-[#89CFF0]
                          ),
                        ),
                        Text(
                          "En Base de Datos",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70, // text-white/70
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Tendencia estática
                Row(
                  children: const [
                    Icon(
                      Icons.trending_up, // Equivalente a TrendingUp
                      color: Color(0xFF90EE90), // Color similar a text-green-300
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "+2.3%",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF90EE90),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Conteo de Datos
            Text(
              // Aplicamos el formato de miles (toLocaleString('es-ES'))
              countFormatter.format(_count),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Registros actualizados en tiempo real",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70, // text-white/70
              ),
            ),

            const SizedBox(height: 20),

            // Separador (border-t border-white/20)
            const Divider(
              color: Colors.white30,
              height: 1,
              thickness: 1,
            ),
            const SizedBox(height: 12),

            // Última Actualización
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Última actualización:",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70, // text-white/70
                  ),
                ),
                Text(
                  formattedTime,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF89CFF0), // text-[#89CFF0]
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}