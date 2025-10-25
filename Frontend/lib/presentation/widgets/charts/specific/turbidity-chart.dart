import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// Asegúrate de que estas rutas son correctas en tu proyecto
import 'package:water_tap_front/domain/repository/sensorRepository.dart';
import 'package:water_tap_front/domain/models/dto/sensor_record_model.dart';
// Asumo que tu sensorRepository.dart tiene una función getHistoryData
// y que SensorRecordModel tiene la propiedad turbidity (double?)

// --- Instancia del repositorio ---
final SensorRepository _sensorRepository = SensorRepository();

// Define el modelo de punto de datos
class ChartDataPoint {
  final DateTime timestamp;
  final double turbidez;

  ChartDataPoint({
    required this.timestamp,
    required this.turbidez,
  });
}

class TurbidityChart extends StatefulWidget {
  const TurbidityChart({super.key});

  @override
  State<TurbidityChart> createState() => _TurbidityChartState();
}

class _TurbidityChartState extends State<TurbidityChart> {
  List<ChartDataPoint> _turbidityData = [];
  double _currentTurbidity = 0;
  bool _isLoading = true;
  bool _hasError = false;

  // Ticks generados para el eje X (guarda los índices de los puntos a mostrar)
  List<int> _xTicks = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  // Genera los índices de los puntos que corresponden a intervalos para un eje legible.
  void _generateTicks(List<ChartDataPoint> data, DateTime start) {
    if (data.isEmpty) return;

    final List<int> newTicks = [];
    // Usamos una lógica similar a la de Recharts: mostrar ~5 ticks uniformemente espaciados.
    final interval = (data.length / 5).floor();

    for (int i = 0; i < data.length; i += interval) {
      if (!newTicks.contains(i)) {
        newTicks.add(i);
      }
    }

    // Asegurar que el último punto esté incluido
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

      final data = await _sensorRepository.getHistoryData(
        from: yesterday,
        to: today,
      );

      final formattedData = data
          .map((record) {
        // Manejar nulos: si turbidity es nulo, usamos 0.0
        final turbidityValue = record.turbidity ?? 0.0;
        return ChartDataPoint(
          timestamp: record.timestamp,
          turbidez: turbidityValue,
        );
      })
          .toList();

      formattedData.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (mounted) {
        setState(() {
          _turbidityData = formattedData;
          _isLoading = false;
          if (formattedData.isNotEmpty) {
            _currentTurbidity = formattedData.last.turbidez;
            _generateTicks(formattedData, yesterday);
          }
        });
      }
    } catch (error) {
      debugPrint("Error al obtener datos de turbidez históricos: $error");
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  // --- Lógica de Rango y Chart ---

  bool get _isInRange => _currentTurbidity <= 4.0;

  LineChartData _buildAreaChartData(List<ChartDataPoint> data) {
    // Definimos el color principal del gráfico: Celeste
    const Color mainColor = Color(0xFF89CFF0);
    const Color axisColor = Color(0xFF5D89BA);

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
                '${spot.y.toStringAsFixed(2)} NTU',
                TextStyle(color: mainColor, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: '\nTurbidez',
                    style: const TextStyle(color: Color(0xFF1E2952), fontSize: 13, fontWeight: FontWeight.normal),
                  ),
                  TextSpan(
                    text: '\n${DateFormat('HH:mm').format(dataPoint.timestamp)}',
                    style: TextStyle(color: axisColor, fontSize: 13, fontWeight: FontWeight.normal),
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
            interval: 1.0, // Necesario para mapear por índice
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (!_xTicks.contains(index)) return const SizedBox.shrink();
              if (index < 0 || index >= data.length) return const Text('');

              final dateTime = data[index].timestamp;
              final timeString = DateFormat('HH:mm').format(dateTime);

              return SideTitleWidget(
                meta: meta,
                space: 4.0,
                child: Text(
                  timeString,
                  style: TextStyle(fontSize: 10, color: axisColor),
                ),
              );
            },
          ),
        ),

        // Eje Y: Fijo a [0, 4]
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1.0, // Ticks en 0, 1, 2, 3, 4
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(0),
                style: TextStyle(fontSize: 10, color: axisColor),
              );
            },
          ),
        ),
      ),

      // 4. BorderData
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: axisColor, width: 1),
          left: BorderSide(color: axisColor, width: 1),
          top: BorderSide.none,
          right: BorderSide.none,
        ),
      ),

      // 5. AreaChart Data
      lineBarsData: [
        LineChartBarData(
          spots: data.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value.turbidez)).toList(),
          isCurved: true,
          color: mainColor, // stroke="#89CFF0"
          barWidth: 3,
          dotData: const FlDotData(show: false),

          // Relleno de área (equivalente a Area y <defs> con linearGradient)
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                mainColor.withOpacity(0.8), // offset="5%", stopOpacity={0.8}
                mainColor.withOpacity(0.1), // offset="95%", stopOpacity={0.1}
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],

      minX: 0,
      maxX: data.length > 0 ? (data.length - 1).toDouble() : 0,

      // Dominio del eje Y (YAxis domain=[0, 4])
      minY: 0,
      maxY: 4,
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
    } else if (_turbidityData.isEmpty) {
      chartContent = const Center(
        child: Text("No hay datos de turbidez disponibles.", style: TextStyle(color: Color(0xFF5D89BA))),
      );
    } else {
      chartContent = LineChart(_buildAreaChartData(_turbidityData));
    }

    // Colores para el estado
    final Color statusColor = _isInRange ? const Color(0xFF22C55E) : const Color(0xFFEF4444); // green-600 vs red-600

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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Turbidez", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E2952))),
                    Text("Últimas 24 horas", style: TextStyle(fontSize: 14, color: Color(0xFF5D89BA))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${_currentTurbidity.toStringAsFixed(2)} NTU",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF89CFF0)), // Color principal
                    ),
                    Text(
                      _isInRange ? 'Aceptable' : 'Alto',
                      style: TextStyle(
                        fontSize: 14,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- Gráfica ---
            SizedBox(
              height: 192,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 16),
                child: chartContent,
              ),
            ),

            // --- Límite Recomendado ---
            const SizedBox(height: 8),
            const Center(
              child: Text(
                "Límite recomendado: ≤ 4.0 NTU",
                style: TextStyle(fontSize: 12, color: Color(0xFF5D89BA)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}