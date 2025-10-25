import 'dart:async';
import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// 1. Modelo de Datos (Interface Alert)
// -----------------------------------------------------------------------------

enum AlertType { high, low, anomaly, trend }
enum AlertSeverity { critical, warning, info }

class Alert {
  final int id;
  final AlertType type;
  final String title;
  final String description;
  final String timestamp;
  final String value;
  final AlertSeverity severity;

  Alert({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.value,
    required this.severity,
  });
}

// -----------------------------------------------------------------------------
// 2. Mock Data
// -----------------------------------------------------------------------------

final List<Alert> mockAlerts = [
  Alert(
    id: 1,
    type: AlertType.high,
    title: "Nivel de pH elevado",
    description: "El pH ha superado los límites normales en el sensor #3",
    timestamp: "Hace 5 min",
    value: "8.9",
    severity: AlertSeverity.critical,
  ),
  Alert(
    id: 2,
    type: AlertType.anomaly,
    title: "Anomalía en turbidez",
    description: "Valores inusuales detectados en la estación principal",
    timestamp: "Hace 12 min",
    value: "15.2 NTU",
    severity: AlertSeverity.warning,
  ),
  Alert(
    id: 3,
    type: AlertType.trend,
    title: "Tendencia descendente en conductividad",
    description: "Disminución continua en las últimas 2 horas",
    timestamp: "Hace 25 min",
    value: "-12%",
    severity: AlertSeverity.info,
  ),
  Alert(
    id: 4,
    type: AlertType.low,
    title: "Flujo bajo detectado",
    description: "El caudal está por debajo del mínimo requerido",
    timestamp: "Hace 1 hora",
    value: "2.1 L/s",
    severity: AlertSeverity.warning,
  ),
];

// -----------------------------------------------------------------------------
// 3. Componente AlertsCarousel (StatefulWidget)
// -----------------------------------------------------------------------------

class AlertsCarousel extends StatefulWidget {
  const AlertsCarousel({super.key});

  @override
  State<AlertsCarousel> createState() => _AlertsCarouselState();
}

class _AlertsCarouselState extends State<AlertsCarousel> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Equivalente a useEffect(() => setInterval(...), [])
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % mockAlerts.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Equivalente a getIcon
  Icon _getIcon(AlertType type) {
    IconData iconData;
    switch (type) {
      case AlertType.high:
        iconData = Icons.trending_up;
        break;
      case AlertType.low:
        iconData = Icons.trending_down;
        break;
      case AlertType.anomaly:
        iconData = Icons.warning_amber; // Similar a AlertTriangle
        break;
      case AlertType.trend:
        iconData = Icons.info_outline; // Similar a AlertCircle
        break;
    }
    return Icon(iconData, size: 20, color: Colors.white);
  }

  // Equivalente a getSeverityColor (Devuelve un Color para Flutter)
  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red.shade500;
      case AlertSeverity.warning:
        return Colors.yellow.shade500;
      case AlertSeverity.info:
        return const Color(0xFF89CFF0); // #89CFF0
    }
  }

  // Devuelve el color del texto basado en la severidad (para warning/info)
  Color _getTextColor(AlertSeverity severity) {
    return severity == AlertSeverity.warning ? Colors.black : const Color(0xFF1E2952); // #1E2952
  }

  @override
  Widget build(BuildContext context) {
    // Usamos LayoutBuilder para obtener el ancho del widget y calcular el desplazamiento.
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Título y Paginación (Dots)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Alertas Recientes",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E2952), // text-[#1E2952]
                    ),
                  ),

                  // Paginación (Dots)
                  Row(
                    children: List.generate(mockAlerts.length, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        child: Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _currentIndex
                                ? const Color(0xFF002FA7) // bg-[#002FA7]
                                : const Color(0xFFE1E5F2), // bg-[#E1E5F2]
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Carrusel Animado (Recreando transform: translateX)
            ClipRRect(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                // Aplicamos la traslación horizontal
                transform: Matrix4.translationValues(
                  -(_currentIndex * cardWidth),
                  0,
                  0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: mockAlerts.map((alert) {
                    return SizedBox(
                      width: cardWidth, // Cada tarjeta ocupa el ancho completo
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0), // Separación entre tarjetas
                        child: _buildAlertCard(alert),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Widget auxiliar para construir cada tarjeta de alerta
  Widget _buildAlertCard(Alert alert) {
    final severityColor = _getSeverityColor(alert.severity);
    final severityTextColor = _getTextColor(alert.severity);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE1E5F2), width: 1), // border-[#E1E5F2]
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono de la Alerta (Lucide Icon + Severidad Color)
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: severityColor,
              ),
              child: _getIcon(alert.type), // El ícono ya tiene color blanco
            ),
            const SizedBox(width: 12),

            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Expanded(
                        child: Text(
                          alert.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E2952), // text-[#1E2952]
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Valor (Badge) y Timestamp
                      Row(
                        children: [
                          // Badge (Recreación del componente Badge de Shadcn)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE1E5F2), // bg-[#E1E5F2]
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              alert.value,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1E2952), // text-[#1E2952]
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Timestamp
                          Text(
                            alert.timestamp,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5D89BA), // text-[#5D89BA]
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Descripción
                  Text(
                    alert.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: severityTextColor, // Usa el color del texto basado en la severidad
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}