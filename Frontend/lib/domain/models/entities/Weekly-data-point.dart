
class WeeklyDataPoint {
  final String day;
  final String date;
  final double pH;
  final double turbidez;
  final double conductividad;
  final double flujo;

  WeeklyDataPoint({
    required this.day,
    required this.date,
    required this.pH,
    required this.turbidez,
    required this.conductividad,
    required this.flujo,
  });
}