import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// Asegúrate de que estas rutas son correctas en tu proyecto
import 'package:water_tap_front/domain/repository/sensorRepository.dart';
import 'package:water_tap_front/domain/models/dto/sensor_record_model.dart';

// --- Instancia del repositorio ---
final SensorRepository _sensorRepository = SensorRepository();

// Define el modelo de punto de datos
class ChartDataPoint {
  final DateTime timestamp;
  final double flujo;

  ChartDataPoint({
    required this.timestamp,
    required this.flujo,
  });
}

class FlowChart extends StatefulWidget {
  const FlowChart({super.key});

  @override
  State<FlowChart> createState() => _FlowChartState();
}

class _FlowChartState extends State<FlowChart> {
  List<ChartDataPoint> _flowData = [];
  double _currentFlow = 0;
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

    // Iteramos por las 5 marcas de 6 horas (0h, 6h, 12h, 18h, 24h)
    for (int i = 0; i <= 24; i += 6) {
      final targetTime = start.add(Duration(hours: i));

      int closestIndex = -1;
      int minDiff = 24 * 60 * 60 * 1000;

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

    // Asegurar que el último punto (24h) esté incluido
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
        // Manejar nulos: si flowRate es nulo, usamos 0.0
        final flowRate = record.flowRate ?? 0.0;
        return ChartDataPoint(
          timestamp: record.timestamp,
          flujo: flowRate,
        );
      })
          .toList();

      formattedData.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (mounted) {
        setState(() {
          _flowData = formattedData;
          _isLoading = false;
          if (formattedData.isNotEmpty) {
            _currentFlow = formattedData.last.flujo;
            _generateTicks(formattedData, yesterday);
          }
        });
      }
    } catch (error) {
      debugPrint("Error al obtener datos de flujo históricos: $error");
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  // --- Lógica de Rango y Chart ---

  bool get _isInRange => _currentFlow >= 5.0;

  LineChartData _buildAreaChartData(List<ChartDataPoint> data) {
    // Definimos el color principal del gráfico
    const Color mainColor = Color(0xFF1E2952);

    return LineChartData(
      // 1. TouchData (Tooltip)
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final dataPoint = data[spot.x.toInt()];
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(2)} L/s',
                TextStyle(color: mainColor, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: '\n${DateFormat('HH:mm').format(dataPoint.timestamp)}',
                    style: const TextStyle(color: Color(0xFF5D89BA), fontSize: 13, fontWeight: FontWeight.normal),
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
            interval: 1.0,
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
                value.toStringAsFixed(1),
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
          spots: data.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value.flujo)).toList(),
          isCurved: true,
          color: mainColor, // stroke="#1E2952"
          barWidth: 2,
          dotData: const FlDotData(show: false),

          // Relleno de área (equivalente a Area y <defs> con linearGradient)
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                mainColor.withOpacity(0.9), // offset="5%", stopOpacity={0.9}
                mainColor.withOpacity(0.6), // offset="95%", stopOpacity={0.6}
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],

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
    } else if (_flowData.isEmpty) {
      chartContent = const Center(
        child: Text("No hay datos de flujo disponibles.", style: TextStyle(color: Color(0xFF5D89BA))),
      );
    } else {
      chartContent = LineChart(_buildAreaChartData(_flowData));
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
                    Text("Flujo de Agua", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E2952))),
                    Text("Últimas 24 horas", style: TextStyle(fontSize: 14, color: Color(0xFF5D89BA))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${_currentFlow.toStringAsFixed(2)} L/s",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E2952)), // Color principal
                    ),
                    Text(
                      _isInRange ? 'Adecuado' : 'Bajo',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isInRange ? const Color(0xFF22C55E) : const Color(0xFFEF4444), // text-green-600 vs text-red-600
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

            // --- Requisito Mínimo ---
            const SizedBox(height: 8),
            const Center(
              child: Text(
                "Flujo mínimo requerido: 5.0 L/s",
                style: TextStyle(fontSize: 12, color: Color(0xFF5D89BA)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}