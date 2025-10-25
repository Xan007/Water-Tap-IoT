import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'package:intl/intl.dart';

// Asume que estos imports ya están configurados
import '../../../../domain/repository/sensorRepository.dart';
import '../../../../domain/models/dto/sensor_record_model.dart';
import '../../../../domain/models/entities/Weekly-data-point.dart';

final SensorRepository _sensorRepository = SensorRepository();

class WeeklyChart extends StatefulWidget {
  const WeeklyChart({super.key});

  @override
  State<WeeklyChart> createState() => _WeeklyChartState();
}

class _WeeklyChartState extends State<WeeklyChart> {
  List<WeeklyDataPoint> _weeklyData = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchAndAggregateData();
  }

  // --- Lógica de Datos Restaurada ---

  // Lógica de agregación (Traducción de aggregateDataByDay de JS)
  List<WeeklyDataPoint> _aggregateDataByDay(List<SensorRecordModel> data) {
    if (data.isEmpty) {
      return [];
    }

    final daysOfWeek = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"];
    final Map<String, List<SensorRecordModel>> dailyRecords = {};

    for (var record in data) {
      final date = record.timestamp;
      final dayKey = DateFormat('yyyy-MM-dd').format(date);
      dailyRecords.putIfAbsent(dayKey, () => []).add(record);
    }

    final List<WeeklyDataPoint> aggregated = dailyRecords.entries.map((entry) {
      final dayRecords = entry.value;
      final date = dayRecords.first.timestamp;

      final avgPH = dayRecords.map((r) => r.ph!).reduce((a, b) => a + b) / dayRecords.length;
      final avgTurbidez = dayRecords.map((r) => r.turbidity!).reduce((a, b) => a + b) / dayRecords.length;
      final avgConductividad = dayRecords.map((r) => r.conductivity!).reduce((a, b) => a + b) / dayRecords.length;
      final avgFlujo = dayRecords.map((r) => r.flowRate!).reduce((a, b) => a + b) / dayRecords.length;

      return WeeklyDataPoint(
        day: daysOfWeek[date.weekday % 7],
        date: DateFormat('d/M').format(date),
        pH: double.parse(avgPH.toStringAsFixed(2)),
        turbidez: double.parse(avgTurbidez.toStringAsFixed(2)),
        conductividad: double.parse(avgConductividad.toStringAsFixed(2)),
        flujo: double.parse(avgFlujo.toStringAsFixed(2)),
      );
    }).toList();

    aggregated.sort((a, b) {
      final dateA = DateFormat('d/M').parse(a.date);
      final dateB = DateFormat('d/M').parse(b.date);
      return dateA.compareTo(dateB);
    });

    return aggregated;
  }

  // Lógica para obtener y agregar datos (Restaurada)
  Future<void> _fetchAndAggregateData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final today = DateTime.now();
      final oneWeekAgo = today.subtract(const Duration(days: 7));

      final data = await _sensorRepository.getHistoryData(
        from: oneWeekAgo,
        to: today,
      );

      final aggregatedData = _aggregateDataByDay(data);

      if (mounted) {
        setState(() {
          _weeklyData = aggregatedData;
          _isLoading = false;
        });
      }
    } catch (error) {
      debugPrint("Error al obtener datos semanales históricos: $error");
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }
  // --- Fin Lógica de Datos Restaurada ---

  Color _getBarColor(String dataKey) {
    switch (dataKey) {
      case 'pH': return const Color(0xFF002FA7);
      case 'turbidez': return const Color(0xFF89CFF0);
      case 'conductividad': return const Color(0xFF5D89BA);
      case 'flujo': return const Color(0xFF1E2952);
      default: return Colors.grey;
    }
  }

  String _getBarName(String dataKey) {
    switch (dataKey) {
      case 'pH': return 'pH';
      case 'turbidez': return 'Turbidez (NTU)';
      case 'conductividad': return 'Conductividad (μS/cm)';
      case 'flujo': return 'Flujo (L/s)';
      default: return dataKey;
    }
  }

  List<BarChartGroupData> _buildBarGroups(List<WeeklyDataPoint> data) {
    const dataKeys = ['pH', 'turbidez', 'conductividad', 'flujo'];
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: dataKeys.asMap().entries.map((keyEntry) {
          final dataKey = keyEntry.value;
          double value;
          switch(dataKey) {
            case 'pH': value = point.pH; break;
            case 'turbidez': value = point.turbidez; break;
            case 'conductividad': value = point.conductividad; break;
            case 'flujo': value = point.flujo; break;
            default: value = 0;
          }

          return BarChartRodData(
            toY: value,
            color: _getBarColor(dataKey),
            width: 8,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(3),
              topRight: Radius.circular(3),
            ),
          );
        }).toList(),
        barsSpace: 4,
      );
    }).toList();
  }

  // --- Widget Principal ---

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_hasError) {
      content = const Center(
        child: Text("Error al cargar los datos.", style: TextStyle(color: Colors.red)),
      );
    } else if (_weeklyData.isEmpty) {
      content = const Center(
        child: Text("No hay datos disponibles para la última semana.", style: TextStyle(color: Color(0xFF5D89BA))),
      );
    } else {
      content = BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          groupsSpace: 16.0,
          maxY: _weeklyData.map((d) => [d.pH, d.turbidez, d.conductividad, d.flujo])
              .expand((e) => e).reduce((a, b) => a > b ? a : b) * 1.1,

          barGroups: _buildBarGroups(_weeklyData),

          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            getDrawingHorizontalLine: (value) => const FlLine(
              color: Color(0xFFE1E5F2),
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),

          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

            // Eje X (Días de la semana y fecha)
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= _weeklyData.length) return const Text('');
                  final dataPoint = _weeklyData[index];

                  return SideTitleWidget(
                    meta: meta, // Requerido en fl_chart 1.1.1
                    space: 4.0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(dataPoint.day, style: const TextStyle(fontSize: 12, color: Color(0xFF5D89BA))),
                        Text(dataPoint.date, style: const TextStyle(fontSize: 10, color: Color(0xFF5D89BA))),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Eje Y
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: (_weeklyData.map((d) => [d.pH, d.turbidez, d.conductividad, d.flujo])
                    .expand((e) => e).reduce((a, b) => a > b ? a : b) / 4).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
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
              )
          ),

          // Configuración del Tooltip (propiedades obsoletas eliminadas)
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                const dataKeys = ['pH', 'turbidez', 'conductividad', 'flujo'];
                final variable = dataKeys[rodIndex];

                return BarTooltipItem(
                  '${_getBarName(variable)}\n',
                  const TextStyle(color: Color(0xFF1E2952), fontWeight: FontWeight.bold, fontSize: 14),
                  children: [
                    TextSpan(
                      text: rod.toY.toStringAsFixed(2),
                      style: TextStyle(color: _getBarColor(variable), fontSize: 13, fontWeight: FontWeight.normal),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Datos Medios Diarios",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E2952),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Promedios de la última semana",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF5D89BA),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 320,
              child: content,
            ),

            if (!_isLoading && !_hasError && _weeklyData.isNotEmpty)
              _buildCustomLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomLegend() {
    const legendItems = ['pH', 'turbidez', 'conductividad', 'flujo'];

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Wrap(
        spacing: 20.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.center,
        children: legendItems.map((key) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getBarColor(key),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _getBarName(key),
                style: const TextStyle(fontSize: 12, color: Color(0xFF5D89BA)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}