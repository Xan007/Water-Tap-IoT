import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// Asegúrate de que estas rutas son correctas en tu proyecto
import 'package:water_tap_front/domain/repository/sensorRepository.dart';
import 'package:water_tap_front/domain/models/dto/sensor_record_model.dart';
import 'package:water_tap_front/presentation/widgets/filter-sidebar.dart';
import 'package:water_tap_front/presentation/widgets/charts/general/dynamic-chart.dart';
import 'package:water_tap_front/presentation/widgets/data-table.dart';

import 'package:water_tap_front/domain/models/entities/filter_state.dart';

// --- Instancia del repositorio (simulada) ---
final SensorRepository _sensorRepository = SensorRepository();

final FilterState _initialFilters = FilterState(
  dateFrom: null,
  dateTo: null,
  timeFrom: null,
  timeTo: null,
  variables: const {
    'pH': false,
    'conductividad': false,
    'turbidez': false,
    'flujo': false,
  },
  range: {
    'pH': VariableRange(min: null, max: null),
    'conductividad': VariableRange(min: null, max: null),
    'turbidez': VariableRange(min: null, max: null),
    'flujo': VariableRange(min: null, max: null),
  },
);

class ChartsPage extends StatefulWidget {
  const ChartsPage({super.key});

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  FilterState _filters = _initialFilters;
  List<SensorRecordModel> _allSensorData = [];
  List<dynamic> _filteredData = []; // Datos formateados para la gráfica (chartData)
  String _searchTerm = "";
  String? _dataError;
  bool _hasInitialData = false;

  void _handleFiltersChange(FilterState newFilters) {
    setState(() {
      _filters = newFilters;
    });

    // Replica la lógica del useEffect: si ya hay datos, re-aplica filtros inmediatamente
    if (_hasInitialData && _allSensorData.isNotEmpty) {
      _applyFilters(_allSensorData, newFilters);
    }
  }

  void _handleSearchChange(String newSearchTerm) {
    setState(() {
      _searchTerm = newSearchTerm;
    });
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  void _applyFilters(List<SensorRecordModel> data, FilterState currentFilters) {
    if (currentFilters.dateFrom == null || currentFilters.dateTo == null) return;

    final DateTime dateFrom = currentFilters.dateFrom!;
    final DateTime dateTo = currentFilters.dateTo!;
    final TimeOfDay timeFrom = currentFilters.timeFrom ?? const TimeOfDay(hour: 0, minute: 0);
    final TimeOfDay timeTo = currentFilters.timeTo ?? const TimeOfDay(hour: 23, minute: 59);

    final DateTime startDateTime = _combineDateAndTime(dateFrom, timeFrom);
    final DateTime endDateTime = _combineDateAndTime(dateTo, timeTo);

    // --- 1. Filtrado por Fecha, Hora y Rangos de Variables ---
    List<SensorRecordModel> tempFilteredData = data.where((record) {
      final recordTimestamp = record.timestamp.millisecondsSinceEpoch;

      // Filtro de Fecha/Hora
      final bool isWithinDateTimeRange = recordTimestamp >= startDateTime.millisecondsSinceEpoch &&
          recordTimestamp <= endDateTime.millisecondsSinceEpoch;

      // Filtro de Rangos de Variables
      final range = currentFilters.range;

      bool isWithinRange(double? value, String key) {
        final VariableRange? varRange = range[key];
        final min = varRange?.min;
        final max = varRange?.max;

        if (value == null) return true;

        final bool minCheck = min == null || value >= min;
        final bool maxCheck = max == null || value <= max;
        return minCheck && maxCheck;
      }

      final bool isWithinVariableRanges =
          isWithinRange(record.ph, 'pH') &&
              isWithinRange(record.conductivity, 'conductividad') &&
              isWithinRange(record.turbidity, 'turbidez') &&
              isWithinRange(record.flowRate, 'flujo');

      return isWithinDateTimeRange && isWithinVariableRanges;
    }).toList();

    // --- 2. Formatear para Gráfica (chartData) ---
    final DateFormat formatter = DateFormat('dd/MM HH:mm');

    final chartData = tempFilteredData.map((record) {
      return {
        'time': formatter.format(record.timestamp),
        'timestamp': record.timestamp,
        'pH': record.ph ?? 0.0,
        'conductividad': record.conductivity ?? 0.0,
        'turbidez': record.turbidity ?? 0.0,
        'flujo': record.flowRate ?? 0.0,
      };
    }).toList();

    // --- 3. Lógica de Error ---
    String? newError;

    final anyRangeSet = currentFilters.range.values.any((r) => r.min != null || r.max != null);

    if (chartData.isEmpty && (currentFilters.variables.values.any((v) => v) || anyRangeSet)) {
      newError = "No se encontraron datos que cumplan con los filtros de fecha, hora y/o rangos de variables.";
    } else if (chartData.isEmpty && _hasInitialData && _dataError == null) {
      newError = "No se encontraron datos en el rango seleccionado después de aplicar los filtros.";
    }

    setState(() {
      _filteredData = chartData;
      _dataError = newError;
    });
  }

  Future<void> _handleGenerate() async {
    final DateTime? apiDateFrom = _filters.dateFrom;
    final DateTime? apiDateTo = _filters.dateTo;

    if (apiDateFrom == null || apiDateTo == null) {
      setState(() {
        _dataError = "Por favor, selecciona un rango de fechas.";
        _allSensorData = [];
        _filteredData = [];
      });
      return;
    }

    setState(() {
      _dataError = null;
    });

    try {
      final List<SensorRecordModel> data = await _sensorRepository.getHistoryData(
        from: apiDateFrom,
        to: apiDateTo.add(const Duration(days: 1)).subtract(const Duration(minutes: 1)),
      );

      if (data.isEmpty) {
        setState(() {
          _dataError = "No se encontraron datos en el rango de fechas seleccionado en la API.";
          _allSensorData = [];
          _filteredData = [];
          _hasInitialData = true;
        });
        return;
      }

      if (mounted) {
        setState(() {
          _allSensorData = data;
          _hasInitialData = true;
        });
        _applyFilters(data, _filters);
      }
    } catch (error) {
      debugPrint("Error al obtener datos históricos: $error");
      if (mounted) {
        setState(() {
          _dataError = "Error al cargar los datos. Intenta de nuevo más tarde.";
          _allSensorData = [];
          _filteredData = [];
          _hasInitialData = true;
        });
      }
    }
  }

  void _handleReset() {
    setState(() {
      _filters = _initialFilters;
      _allSensorData = [];
      _filteredData = [];
      _searchTerm = "";
      _dataError = null;
      _hasInitialData = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Datos filtrados para la tabla (se recalcula en cada build)
    final List<SensorRecordModel> dataToTable = _allSensorData.where((record) {
      if (!_hasInitialData || _filters.dateFrom == null || _filters.dateTo == null) return false;

      final recordTimestamp = record.timestamp.millisecondsSinceEpoch;
      final currentFilters = _filters;

      final dateFrom = currentFilters.dateFrom!;
      final dateTo = currentFilters.dateTo!;
      final timeFrom = currentFilters.timeFrom ?? const TimeOfDay(hour: 0, minute: 0);
      final timeTo = currentFilters.timeTo ?? const TimeOfDay(hour: 23, minute: 59);

      final startDateTime = _combineDateAndTime(dateFrom, timeFrom);
      final endDateTime = _combineDateAndTime(dateTo, timeTo);

      final bool isWithinDateTimeRange = recordTimestamp >= startDateTime.millisecondsSinceEpoch &&
          recordTimestamp <= endDateTime.millisecondsSinceEpoch;

      final range = currentFilters.range;

      bool isWithinRange(double? value, String key) {
        final VariableRange? varRange = range[key];
        final min = varRange?.min;
        final max = varRange?.max;

        if (value == null) return true;

        final bool minCheck = min == null || value >= min;
        final bool maxCheck = max == null || value <= max;
        return minCheck && maxCheck;
      }

      final bool isWithinVariableRanges =
          isWithinRange(record.ph, 'pH') &&
              isWithinRange(record.conductivity, 'conductividad') &&
              isWithinRange(record.turbidity, 'turbidez') &&
              isWithinRange(record.flowRate, 'flujo');

      return isWithinDateTimeRange && isWithinVariableRanges;
    }).toList();


    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sidebar de Filtros: Usa FilterSidebarProps para el parámetro 'props'
          FilterSidebar(
            props: FilterSidebarProps(
              filters: _filters,
              onFiltersChange: _handleFiltersChange,
              onGenerate: _handleGenerate,
              onReset: _handleReset,
              generateButtonText: "Generar Gráfica",
            ),
          ),

          const SizedBox(width: 32),

          // 2. Contenido Principal
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_dataError != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 100),
                        child: Text(
                          _dataError!,
                          style: const TextStyle(color: Colors.red, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else if (_filteredData.isNotEmpty)
                    Column(
                      children: [
                        DynamicChart(
                          filters: _filters,
                          chartData: _filteredData,
                        ),

                        const SizedBox(height: 32),

                        DataTableWidget(
                          filters: _filters,
                          data: dataToTable, // Datos filtrados para la tabla
                          searchTerm: _searchTerm,
                          onSearchChange: _handleSearchChange,
                        ),
                      ],
                    )
                  else if (!_hasInitialData)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 100),
                          child: Text(
                            "Selecciona las fechas y presiona 'Generar Gráfica' para cargar los datos.",
                            style: TextStyle(color: Color(0xFF5D89BA), fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}