import 'package:flutter/material.dart';

class VariableRange {
  final double? min;
  final double? max;
  VariableRange({this.min, this.max});

  VariableRange copyWith({double? min, double? max}) {
    return VariableRange(
      min: min ?? this.min,
      max: max ?? this.max,
    );
  }
}

class FilterState {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final TimeOfDay? timeFrom;
  final TimeOfDay? timeTo;
  final Map<String, bool> variables;
  final Map<String, VariableRange> range;

  FilterState({
    this.dateFrom,
    this.dateTo,
    this.timeFrom,
    this.timeTo,
    required this.variables,
    required this.range,
  });

  FilterState copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    TimeOfDay? timeFrom,
    TimeOfDay? timeTo,
    Map<String, bool>? variables,
    Map<String, VariableRange>? range,
  }) {
    return FilterState(
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      timeFrom: timeFrom ?? this.timeFrom,
      timeTo: timeTo ?? this.timeTo,
      variables: variables ?? Map.from(this.variables),
      range: range ?? Map.from(this.range),
    );
  }
}

// Modelo simplificado para los datos de la gráfica
class ChartDataPoint {
  final String time;
  final double pH;
  final double conductividad;
  final double turbidez;
  final double flujo;

  ChartDataPoint({
    required this.time,
    required this.pH,
    required this.conductividad,
    required this.turbidez,
    required this.flujo,
  });

  double? getValue(String variable) {
    switch (variable) {
      case 'pH':
        return pH;
      case 'conductividad':
        return conductividad;
      case 'turbidez':
        return turbidez;
      case 'flujo':
        return flujo;
      default:
        return null;
    }
  }
}