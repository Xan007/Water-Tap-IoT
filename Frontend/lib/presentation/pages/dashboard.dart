import 'package:flutter/material.dart';

// Importaciones de los componentes REALES
import 'package:water_tap_front/presentation/widgets/alerts-carousel.dart';
import 'package:water_tap_front/presentation/widgets/database-kpi.dart';
import 'package:water_tap_front/presentation/widgets/charts/specific/ph-chart.dart';
import 'package:water_tap_front/presentation/widgets/charts/specific/turbidity-chart.dart';
import 'package:water_tap_front/presentation/widgets/charts/specific/conductivity-chart.dart';
import 'package:water_tap_front/presentation/widgets/charts/specific/flow-chart.dart';
import 'package:water_tap_front/presentation/widgets/charts/general/weekly-chart.dart';


const Color darkPrimaryColor = Color(0xFF1E2952);
const Color primaryColor = Color(0xFF5D89BA);
const Color lightBackground = Color(0xFFF0FFFF);
const Color lighterBorder = Color(0xFFE1E5F2);
const Color secondaryColor = Color(0xFF89CFF0);


class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          '© 2025 WaterTap - Sistema de Monitoreo de Calidad del Agua',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Última actualización: ${DateTime.now().toLocaleString()}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: primaryColor,
          ),
        ),
      ],
    );
  }
}

extension on DateTime {
  String toLocaleString() {
    return '${year}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Widget _buildSmallKPI(BuildContext context, String title, String value, Color indicatorColor, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: lighterBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? darkPrimaryColor,
                ),
              ),
            ],
          ),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: indicatorColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 1024;

    return Scaffold(
      backgroundColor: lightBackground,
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1280),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const AlertsCarousel(),

                LayoutBuilder(
                  builder: (context, constraints) {
                    if (isLargeScreen) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Expanded(flex: 1, child: DatabaseKPI()),
                          SizedBox(width: 24),
                          Expanded(flex: 2, child: WeeklyChart()),
                        ],
                      );
                    } else {
                      return const Column(
                        children: [
                          DatabaseKPI(),
                          SizedBox(height: 24),
                          WeeklyChart(),
                        ],
                      );
                    }
                  },
                ),

                const SizedBox(height: 24),

                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Monitoreo por Variables - Últimas 24H",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: darkPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Análisis detallado de cada parámetro de calidad del agua",
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                GridView.count(
                  crossAxisCount: screenWidth < 768 ? 1 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: isLargeScreen ? 1.6 : 1.2,
                  children: const <Widget>[
                    PHChart(),
                    TurbidityChart(),
                    ConductivityChart(),
                    FlowChart(),
                  ],
                ),

                const SizedBox(height: 32),

                GridView.count(
                  crossAxisCount: screenWidth < 768
                      ? 1
                      : screenWidth < 1024
                      ? 2
                      : 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: isLargeScreen ? 2.8 : 2.0,
                  children: [
                    _buildSmallKPI(
                        context, 'Sensores Activos', '24', Colors.green.shade500),
                    _buildSmallKPI(
                        context, 'Estaciones', '8', secondaryColor),
                    _buildSmallKPI(
                        context, 'Alertas Activas', '3', Colors.amber.shade500, valueColor: const Color(0xFF002FA7)),
                    _buildSmallKPI(
                        context, 'Uptime Sistema', '94%', Colors.green.shade500, valueColor: Colors.green.shade600),
                  ],
                ),

                const SizedBox(height: 32),

                const FooterWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}