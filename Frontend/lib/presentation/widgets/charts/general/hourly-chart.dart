import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// Asegúrate de que estas rutas son correctas en tu proyecto
import 'package:water_tap_front/domain/repository/sensorRepository.dart';
import 'package:water_tap_front/domain/models/dto/sensor_record_model.dart';

// --- Instancia del repositorio (asume que está configurado) ---
// *Reemplaza la inicialización si usas GetIt o Provider para inyección.*
final SensorRepository _sensorRepository = SensorRepository();

// Define el modelo de punto de datos para la gráfica
class HourlyDataPoint {
  final String hour;
  final double pH;
  final double turbidez;
  final double conductividad;
  final double flujo;

  HourlyDataPoint({
    required this.hour,
    required this.pH,
    required this.turbidez,
    required this.conductividad,
    required this.flujo,
  });
}

class HourlyChart extends StatefulWidget {
  const HourlyChart({super.key});

  @override
  State<HourlyChart> createState() => _HourlyChartState();
}

class _HourlyChartState extends State<HourlyChart> {
  List<HourlyDataPoint> _hourlyData = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchAndAggregateData();
  }

  // CORRECCIÓN 1: Ajuste el selector para aceptar un tipo de retorno nulo (double?)
  double _safeReduce(List<SensorRecordModel> records, double? Function(SensorRecordModel) selector) {
    // Mapea la lista, filtra los valores nulos, y convierte a List<double>
    final values = records.map(selector).where((v) => v != null).cast<double>().toList();
    // Si no hay valores, devuelve 0.0. De lo contrario, calcula el promedio.
    return values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;
  }

  // Lógica para agregar datos por hora
  List<HourlyDataPoint> _aggregateDataByHour(List<SensorRecordModel> data) {
    if (data.isEmpty) {
      return [];
    }

    final Map<String, List<SensorRecordModel>> hourlyRecords = {};

    for (var record in data) {
      final date = record.timestamp;
      final hourKey = DateFormat('HH:mm').format(date);
      hourlyRecords.putIfAbsent(hourKey, () => []).add(record);
    }

    final List<HourlyDataPoint> aggregated = hourlyRecords.entries.map((entry) {
      final recordsInHour = entry.value;

      // Usando la función corregida _safeReduce
      final avgPH = _safeReduce(recordsInHour, (r) => r.ph);
      final avgTurbidez = _safeReduce(recordsInHour, (r) => r.turbidity);
      final avgConductividad = _safeReduce(recordsInHour, (r) => r.conductivity);
      final avgFlujo = _safeReduce(recordsInHour, (r) => r.flowRate);

      return HourlyDataPoint(
        hour: entry.key,
        pH: double.parse(avgPH.toStringAsFixed(2)),
        turbidez: double.parse(avgTurbidez.toStringAsFixed(2)),
        conductividad: double.parse(avgConductividad.toStringAsFixed(2)),
        flujo: double.parse(avgFlujo.toStringAsFixed(2)),
      );
    }).toList();

    aggregated.sort((a, b) => a.hour.compareTo(b.hour));

    return aggregated;
  }

  // Lógica para obtener el historial
  Future<void> _fetchAndAggregateData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      // CORRECCIÓN 2: Eliminación del tipado explícito 'List<SensorRecordModel>'
      // El tipo se infiere automáticamente y evita el error de sintaxis.
      final data = await _sensorRepository.getHistoryData(
        from: yesterday,
        to: today,
      );

      final aggregatedData = _aggregateDataByHour(data);

      if (mounted) {
        setState(() {
          _hourlyData = aggregatedData;
          _isLoading = false;
        });
      }
    } catch (error) {
      debugPrint("Error al obtener datos horarios históricos: $error");
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  // ... (Resto del código de _buildChart, _buildLegend y build) ...

  // Función para construir la gráfica (sin cambios, excepto el mapeo de barKey)
  Widget _buildChart(List<HourlyDataPoint> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          "No hay datos disponibles para las últimas 24 horas.",
          style: TextStyle(color: Color(0xFF5D89BA)),
        ),
      );
    }

    double maxYValue = 0;
    if (data.isNotEmpty) {
      final allValues = data.expand((p) => [p.pH, p.turbidez, p.conductividad, p.flujo]).toList();
      maxYValue = allValues.reduce((a, b) => a > b ? a : b);
    }

    const maxTicks = 10;
    final interval = data.length > maxTicks ? (data.length / maxTicks).floor() : 1;

    const dataKeys = ['pH', 'turbidez', 'conductividad', 'flujo'];


    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                String name;
                Color color;

                final dataIndex = spot.barIndex;
                final dataKey = dataKeys[dataIndex];

                switch (dataKey) {
                  case 'pH':
                    name = 'pH';
                    color = const Color(0xFF002FA7);
                    break;
                  case 'turbidez':
                    name = 'Turbidez (NTU)';
                    color = const Color(0xFF89CFF0);
                    break;
                  case 'conductividad':
                    name = 'Conductividad (μS/cm)';
                    color = const Color(0xFF5D89BA);
                    break;
                  case 'flujo':
                    name = 'Flujo (L/s)';
                    color = const Color(0xFF1E2952);
                    break;
                  default:
                    name = dataKey;
                    color = Colors.grey;
                }

                return LineTooltipItem(
                  '$name:\n${spot.y.toStringAsFixed(2)}',
                  TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: interval.toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const Text('');
                if (index % interval == 0 || index == data.length - 1) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 8.0,
                    child: Text(
                      data[index].hour,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5D89BA)),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: (maxYValue / 4).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5D89BA)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: Color(0xFF5D89BA), width: 1),
            left: BorderSide(color: Color(0xFF5D89BA), width: 1),
            top: BorderSide.none,
            right: BorderSide.none,
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFE1E5F2), strokeWidth: 1),
          getDrawingVerticalLine: (value) => const FlLine(color: Color(0xFFE1E5F2), strokeWidth: 1),
        ),
        lineBarsData: [
          LineChartBarData(spots: data.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value.pH)).toList(), isCurved: true, color: const Color(0xFF002FA7), barWidth: 2, dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 3, color: const Color(0xFF002FA7), strokeWidth: 2, strokeColor: Colors.transparent))),
          LineChartBarData(spots: data.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value.turbidez)).toList(), isCurved: true, color: const Color(0xFF89CFF0), barWidth: 2, dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 3, color: const Color(0xFF89CFF0), strokeWidth: 2, strokeColor: Colors.transparent))),
          LineChartBarData(spots: data.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value.conductividad)).toList(), isCurved: true, color: const Color(0xFF5D89BA), barWidth: 2, dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 3, color: const Color(0xFF5D89BA), strokeWidth: 2, strokeColor: Colors.transparent))),
          LineChartBarData(spots: data.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value.flujo)).toList(), isCurved: true, color: const Color(0xFF1E2952), barWidth: 2, dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 3, color: const Color(0xFF1E2952), strokeWidth: 2, strokeColor: Colors.transparent))),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    const legendItems = [
      {'name': 'pH', 'color': Color(0xFF002FA7)},
      {'name': 'Turbidez (NTU)', 'color': Color(0xFF89CFF0)},
      {'name': 'Conductividad (μS/cm)', 'color': Color(0xFF5D89BA)},
      {'name': 'Flujo (L/s)', 'color': Color(0xFF1E2952)},
    ];

    return Wrap(
      spacing: 20.0,
      runSpacing: 8.0,
      children: legendItems.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: item['color'] as Color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 6),
            Text(item['name'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF5D89BA))),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_hasError) {
      content = const Center(child: Text("Error al cargar los datos.", style: TextStyle(color: Colors.red)));
    } else {
      content = SizedBox(
        height: 320,
        child: Padding(
          padding: const EdgeInsets.only(right: 16, top: 16),
          child: _buildChart(_hourlyData),
        ),
      );
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
            const Text("Registro Últimas 24H", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E2952))),
            const Text("Datos por hora - múltiples variables", style: TextStyle(fontSize: 14, color: Color(0xFF5D89BA))),
            const SizedBox(height: 16),
            content,
            const SizedBox(height: 16),
            if (!_isLoading && !_hasError && _hourlyData.isNotEmpty) _buildLegend(),
          ],
        ),
      ),
    );
  }
}