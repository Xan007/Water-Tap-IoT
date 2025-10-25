import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // NECESARIO para formatear DateTime
import 'package:flutter_svg/flutter_svg.dart';
import 'package:water_tap_front/domain/models/entities/filter_state.dart';

// Asumo que tu clase ChartDataPoint tiene una propiedad 'time' y métodos de acceso a valores.

class DynamicChart extends StatelessWidget {
  final FilterState filters;
  final List<dynamic> chartData;
  final VoidCallback? onSaveChart;

  const DynamicChart({
    super.key,
    required this.filters,
    required this.chartData,
    this.onSaveChart,
  });

  Color _getVariableColor(String variable) {
    switch (variable) {
      case 'pH': return const Color(0xFF002FA7);
      case 'conductividad': return const Color(0xFF89CFF0);
      case 'turbidez':
      case 'turbidity': return const Color(0xFF5D89BA);
      case 'flujo':
      case 'flow': return const Color(0xFF1E2952);
      default: return Colors.grey;
    }
  }

  String _getVariableLabel(String variable) {
    switch (variable) {
      case 'pH': return 'pH';
      case 'conductividad': return 'Conductividad (μS/cm)';
      case 'turbidez': return 'Turbidez (NTU)';
      case 'flujo': return 'Flujo (L/s)';
      default: return variable;
    }
  }

  List<String> get _selectedVariables {
    return filters.variables.entries
        .where((entry) => entry.value == true && entry.key != 'sensor')
        .map((entry) => entry.key)
        .toList();
  }

  int get _interval {
    const maxTicks = 10;
    final totalDataPoints = chartData.length;
    return totalDataPoints > maxTicks ? (totalDataPoints / maxTicks).floor() : 0;
  }

  double? _getChartValue(dynamic dataPoint, String variable) {
    // Implementación de acceso a tus datos (usando el mapa dinámico que pasas)
    return dataPoint[variable] as double?;
  }

  @override
  Widget build(BuildContext context) {
    final selectedVariables = _selectedVariables;
    final hasSelectedVariables = selectedVariables.isNotEmpty;

    // --- Lógica de formateo de fechas y horas ---
    final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');

    final String formattedDateFrom = filters.dateFrom != null
        ? dateFormatter.format(filters.dateFrom!)
        : 'Sin definir';

    final String formattedDateTo = filters.dateTo != null
        ? dateFormatter.format(filters.dateTo!)
        : 'Sin definir';

    // TimeOfDay requiere context para formatear
    final String formattedTimeFrom = filters.timeFrom?.format(context) ?? '00:00';
    final String formattedTimeTo = filters.timeTo?.format(context) ?? '23:59';
    // --- Fin de la lógica de formateo ---


    if (!hasSelectedVariables) {
      return const Card(
        margin: EdgeInsets.zero,
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              "Selecciona al menos una variable para generar la gráfica",
              style: TextStyle(fontSize: 16, color: Color(0xFF5D89BA)),
            ),
          ),
        ),
      );
    }

    if (chartData.isEmpty) {
      return const Card(
        margin: EdgeInsets.zero,
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              "No se encontraron datos que cumplan con los filtros.",
              style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "GRÁFICA GENERADA A PARTIR DE FILTROS",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E2952),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16.0,
                      runSpacing: 8.0,
                      children: selectedVariables.map((variable) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _getVariableColor(variable),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getVariableLabel(variable),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF5D89BA),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),

                if (onSaveChart != null)
                  ElevatedButton.icon(
                    onPressed: onSaveChart,
                    icon: const Icon(Icons.save, size: 20),
                    label: const Text("Guardar gráfica", style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2952),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 384,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 16),
                child: LineChart(
                  _buildLineChartData(selectedVariables),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.only(left: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // *** LÍNEA CORREGIDA PARA DATETIME ***
                  Text(
                    'Período: $formattedDateFrom - $formattedDateTo',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF5D89BA)),
                  ),
                  // *** LÍNEA CORREGIDA PARA TIMEOFDAY ***
                  Text(
                    'Horario: $formattedTimeFrom - $formattedTimeTo',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF5D89BA)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildLineChartData(List<String> selectedVariables) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) => const FlLine(
          color: Color(0xFFE1E5F2),
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (value) => const FlLine(
          color: Color(0xFFE1E5F2),
          strokeWidth: 1,
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
            interval: _interval.toDouble() + 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= chartData.length) return const Text('');

              if (index % (_interval + 1) == 0 || index == chartData.length - 1) {
                return SideTitleWidget(
                  meta: meta,
                  space: 8.0,
                  child: Text(
                    (chartData[index] as dynamic)['time'].toString() ,
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
          bottom: BorderSide(color: Color(0xFF5D89BA)),
          left: BorderSide(color: Color(0xFF5D89BA)),
        ),
      ),

      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final variable = selectedVariables[spot.barIndex!];

              return LineTooltipItem(
                '${_getVariableLabel(variable)}:\n${spot.y.toStringAsFixed(2)}',
                TextStyle(
                  color: _getVariableColor(variable),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              );
            }).toList();
          },
        ),
      ),

      lineBarsData: List<LineChartBarData>.generate(selectedVariables.length, (index) {
        final variable = selectedVariables[index];
        final color = _getVariableColor(variable);

        return LineChartBarData(
          spots: chartData.asMap().entries.map((entry) {
            final x = entry.key.toDouble();
            final y = _getChartValue(entry.value, variable) ?? 0.0;
            return FlSpot(x, y);
          }).toList(),

          isCurved: true,
          color: color,
          barWidth: 2,
          dotData: const FlDotData(show: false),

          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.8),
                color.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        );
      }),
    );
  }
}