import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// Asegúrate de que estas rutas son correctas en tu proyecto
import 'package:water_tap_front/domain/repository/sensorRepository.dart';
import 'package:water_tap_front/domain/models/dto/sensor_record_model.dart';
// Asumo que tu sensorRepository.dart tiene una función getHistoryData que recibe DateTime
// y que SensorRecordModel tiene la propiedad conductivity (double?)

// --- Instancia del repositorio (asume que está configurado) ---
// *Reemplaza la inicialización si usas GetIt o Provider para inyección.*
final SensorRepository _sensorRepository = SensorRepository();

// Define el modelo de punto de datos para la gráfica (equivalente a ChartDataPoint)
class ChartDataPoint {
  final DateTime timestamp;
  final double conductividad;

  ChartDataPoint({
    required this.timestamp,
    required this.conductividad,
  });
}

class ConductivityChart extends StatefulWidget {
  const ConductivityChart({super.key});

  @override
  State<ConductivityChart> createState() => _ConductivityChartState();
}

class _ConductivityChartState extends State<ConductivityChart> {
  List<ChartDataPoint> _conductivityData = [];
  double _currentConductivity = 0;
  bool _isLoading = true;
  bool _hasError = false;

  // Ticks generados para el eje X (guarda los índices de los puntos a mostrar)
  List<int> _xTicks = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  // Genera los índices de los puntos que corresponden a intervalos de 6 horas.
  void _generateTicks(List<ChartDataPoint> data, DateTime start) {
    if (data.isEmpty) return;

    final List<int> newTicks = [];

    // Iteramos por las 4 marcas de 6 horas (0h, 6h, 12h, 18h)
    for (int i = 0; i < 24; i += 6) {
      final targetTime = start.add(Duration(hours: i));

      // Busca el punto de datos más cercano a la hora objetivo
      int closestIndex = -1;
      int minDiff = 24 * 60 * 60 * 1000; // Un día en ms

      for (int j = 0; j < data.length; j++) {
        final diff = (data[j].timestamp.difference(targetTime)).abs().inMilliseconds;
        if (diff < minDiff) {
          minDiff = diff;
          closestIndex = j;
        }
      }

      if (closestIndex != -1 && !newTicks.contains(closestIndex)) {
        newTicks.add(closestIndex);
      }
    }

    // Asegurar que el último punto siempre se incluya si aún no lo está
    if (data.isNotEmpty && !newTicks.contains(data.length - 1)) {
      newTicks.add(data.length - 1);
    }

    setState(() {
      _xTicks = newTicks;
    });
  }


  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      // 1. Obtener datos (usando la variable 'data' sin tipado explícito, ya corregido)
      final data = await _sensorRepository.getHistoryData(
        from: yesterday,
        to: today,
      );

      // 2. Formatear y limpiar datos
      final formattedData = data
          .map((record) {
        // Manejar nulos: si conductivity es nulo, usamos 0.0 (o el valor que prefieras)
        final conductivity = record.conductivity ?? 0.0;
        return ChartDataPoint(
          timestamp: record.timestamp,
          conductividad: conductivity,
        );
      })
          .toList();

      // 3. Ordenar por tiempo (si no vienen ordenados)
      formattedData.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // 4. Actualizar estado
      if (mounted) {
        setState(() {
          _conductivityData = formattedData;
          _isLoading = false;
          if (formattedData.isNotEmpty) {
            _currentConductivity = formattedData.last.conductividad;
            _generateTicks(formattedData, yesterday);
          }
        });
      }
    } catch (error) {
      debugPrint("Error al obtener datos de conductividad históricos: $error");
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  // --- Lógica del Chart ---

  bool get _isInRange => _currentConductivity >= 100 && _currentConductivity <= 200;

  LineChartData _buildAreaChartData(List<ChartDataPoint> data) {
    return LineChartData(
      // 1. TouchData (Tooltip)
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final dataPoint = data[spot.x.toInt()];
              return LineTooltipItem(
                // Formatter para el valor
                '${spot.y.toStringAsFixed(2)} μS/cm',
                const TextStyle(color: Color(0xFF5D89BA), fontWeight: FontWeight.bold),
                children: [
                  // Formatter para la etiqueta (hora)
                  TextSpan(
                    text: '\n${DateFormat('HH:mm').format(dataPoint.timestamp)}',
                    style: const TextStyle(color: Color(0xFF1E2952), fontSize: 13, fontWeight: FontWeight.normal),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),

      // 2. GridData (CartesianGrid)
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFE1E5F2), strokeWidth: 1),
        getDrawingVerticalLine: (value) => const FlLine(color: Color(0xFFE1E5F2), strokeWidth: 1),
      ),

      // 3. TitlesData (XAxis, YAxis)
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

        // Eje X
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 20,
            interval: 1.0, // Intervalo 1.0 para poder iterar sobre los índices de data
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (!_xTicks.contains(index)) return const SizedBox.shrink(); // Solo muestra los ticks generados
              if (index < 0 || index >= data.length) return const Text('');

              final dateTime = data[index].timestamp;
              final timeString = DateFormat('HH:mm').format(dateTime);

              return SideTitleWidget(
                meta: meta,
                space: 4.0,
                child: Text(
                  timeString,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF5D89BA)),
                ),
              );
            },
          ),
        ),

        // Eje Y
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(0),
                style: const TextStyle(fontSize: 10, color: Color(0xFF5D89BA)),
              );
            },
          ),
        ),
      ),

      // 4. BorderData
      borderData: FlBorderData(
        show: true,
        border: const Border(
          bottom: BorderSide(color: Color(0xFF5D89BA), width: 1),
          left: BorderSide(color: Color(0xFF5D89BA), width: 1),
          top: BorderSide.none,
          right: BorderSide.none,
        ),
      ),

      // 5. AreaChart Data
      lineBarsData: [
        LineChartBarData(
          // Mapea los datos: X es el índice de la lista, Y es el valor de conductividad
          spots: data.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value.conductividad)).toList(),
          isCurved: true,
          color: const Color(0xFF5D89BA), // stroke="#5D89BA"
          barWidth: 2,
          dotData: const FlDotData(show: false), // Ocultar los puntos para un AreaChart limpio

          // Relleno de área (equivalente a Area y <defs> con linearGradient)
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF5D89BA).withOpacity(0.8), // offset="5%", stopOpacity={0.8}
                const Color(0xFF5D89BA).withOpacity(0.1), // offset="95%", stopOpacity={0.1}
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],

      // Asegurar que el eje X vaya de 0 a la longitud de los datos
      minX: 0,
      maxX: data.length > 0 ? (data.length - 1).toDouble() : 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget chartContent;

    if (_isLoading) {
      chartContent = const Center(child: CircularProgressIndicator());
    } else if (_hasError) {
      chartContent = const Center(
        child: Text("Error al cargar los datos.", style: TextStyle(color: Colors.red)),
      );
    } else if (_conductivityData.isEmpty) {
      chartContent = const Center(
        child: Text("No hay datos de conductividad disponibles.", style: TextStyle(color: Color(0xFF5D89BA))),
      );
    } else {
      chartContent = LineChart(_buildAreaChartData(_conductivityData));
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Título y Valor Actual ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Conductividad", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E2952))),
                    Text("Últimas 24 horas", style: TextStyle(fontSize: 14, color: Color(0xFF5D89BA))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${_currentConductivity.toStringAsFixed(2)} μS/cm",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5D89BA)),
                    ),
                    Text(
                      _isInRange ? 'Normal' : 'Moderado',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isInRange ? const Color(0xFF22C55E) : const Color(0xFFEAB308), // text-green-600 vs text-yellow-600
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- Gráfica ---
            SizedBox(
              height: 192, // Equivalente a h-48
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 16), // Espacio para el eje Y
                child: chartContent,
              ),
            ),

            // --- Rango Típico ---
            const SizedBox(height: 8),
            const Center(
              child: Text(
                "Rango típico: 100 - 200 μS/cm",
                style: TextStyle(fontSize: 12, color: Color(0xFF5D89BA)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}