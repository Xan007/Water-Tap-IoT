import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Asegúrate de que estas rutas son correctas
import 'package:water_tap_front/domain/models/entities/filter_state.dart';
import 'package:water_tap_front/domain/models/dto/sensor_record_model.dart';

// Definición de colores
const Color primaryColor = Color(0xFF5D89BA);
const Color darkPrimaryColor = Color(0xFF1E2952);
const Color lightBlue = Color(0xFFF0FFFF);
const Color lighterBorder = Color(0xFFE1E5F2);

// --- 1. CLASE INTERMEDIA (VIEW MODEL) ---
// Combina el modelo de datos inmutable (SensorRecordModel) con el estado de la UI (status).
class TableRecordViewModel {
  final SensorRecordModel record;
  final String status;

  TableRecordViewModel({required this.record, required this.status});
}

// --- 2. Widget de Badge (Componente UI) ---

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case 'normal':
        bgColor = const Color(0xFFD9F4D9);
        textColor = const Color(0xFF1F7A1F);
        text = 'Normal';
        break;
      case 'warning':
        bgColor = const Color(0xFFFFF7D6);
        textColor = const Color(0xFF8B5A00);
        text = 'Advertencia';
        break;
      case 'alert':
        bgColor = const Color(0xFFFFDADA);
        textColor = const Color(0xFF990000);
        text = 'Alerta';
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        text = 'Desconocido';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// --- 3. Lógica de Estado y Reglas de Negocio ---

String calculateStatus(SensorRecordModel item) {
  final pH = item.ph ?? 7.0;
  final turbidity = item.turbidity ?? 0.0;
  final conductivity = item.conductivity ?? 0.0;
  final flow = item.flowRate ?? 0.0;

  if (pH < 6.5 || pH > 8.5 || turbidity > 4 || flow < 5) {
    return 'alert';
  } else if (pH < 7 || pH > 8 || turbidity > 3 || conductivity > 180) {
    return 'warning';
  }
  return 'normal';
}

// --- 4. El Widget principal DataTableWidget ---

class DataTableWidget extends StatelessWidget {
  final FilterState filters;
  final String searchTerm;
  final ValueChanged<String> onSearchChange;
  final VoidCallback? onExport;
  final List<SensorRecordModel> data;

  const DataTableWidget({
    super.key,
    required this.filters,
    required this.searchTerm,
    required this.onSearchChange,
    required this.data,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {

    // 1. Mapear los datos brutos a ViewModels y aplicar la lógica de búsqueda
    final List<TableRecordViewModel> filteredData = (data)
        .map((item) => TableRecordViewModel(
      record: item,
      status: calculateStatus(item), // Calculamos el status y lo almacenamos en el ViewModel
    ))
        .where((viewModel) =>
    viewModel.record.timestamp.toIso8601String().toLowerCase().contains(searchTerm.toLowerCase()) ||
        (viewModel.record.sensorId.toString()).contains(searchTerm))
        .toList();


    final visibleColumns = {
      'pH': filters.variables['pH'] ?? false,
      'turbidez': filters.variables['turbidez'] ?? false,
      'conductividad': filters.variables['conductividad'] ?? false,
      'flujo': filters.variables['flujo'] ?? false,
    };

    // Formateo de las fechas y horas para el pie de página
    final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
    final String formattedDateFrom = filters.dateFrom != null
        ? dateFormatter.format(filters.dateFrom!)
        : 'Sin definir';
    final String formattedDateTo = filters.dateTo != null
        ? dateFormatter.format(filters.dateTo!)
        : 'Sin definir';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header y Búsqueda
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Datos de Monitoreo",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: darkPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Mostrando ${filteredData.length} registros",
                          style: const TextStyle(fontSize: 14, color: primaryColor),
                        ),
                      ],
                    ),
                    if (onExport != null)
                      ElevatedButton.icon(
                        onPressed: onExport,
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text("Exportar CSV"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Input de búsqueda
                TextField(
                  onChanged: onSearchChange,
                  decoration: InputDecoration(
                    hintText: "Buscar por sensor, estación o fecha...",
                    hintStyle: const TextStyle(color: primaryColor),
                    prefixIcon: const Icon(Icons.search, color: primaryColor, size: 18),
                    filled: true,
                    fillColor: lightBlue.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: lighterBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: lighterBorder),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // Tabla de Datos
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 32,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 48,
              headingRowColor: MaterialStateProperty.resolveWith((states) => lightBlue.withOpacity(0.8)),
              columns: [
                const DataColumn(
                  label: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold, color: darkPrimaryColor)),
                ),
                if (visibleColumns['pH']!)
                  const DataColumn(
                    label: Text('pH', style: TextStyle(fontWeight: FontWeight.bold, color: darkPrimaryColor)),
                  ),
                if (visibleColumns['turbidez']!)
                  const DataColumn(
                    label: Text('Turbidez (NTU)', style: TextStyle(fontWeight: FontWeight.bold, color: darkPrimaryColor)),
                  ),
                if (visibleColumns['conductividad']!)
                  const DataColumn(
                    label: Text('Conductividad (μS/cm)', style: TextStyle(fontWeight: FontWeight.bold, color: darkPrimaryColor)),
                  ),
                if (visibleColumns['flujo']!)
                  const DataColumn(
                    label: Text('Flujo (L/s)', style: TextStyle(fontWeight: FontWeight.bold, color: darkPrimaryColor)),
                  ),
                const DataColumn(
                  label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold, color: darkPrimaryColor)),
                ),
              ],
              rows: filteredData.isEmpty
                  ? [
                DataRow(cells: [
                  DataCell(
                    Center(
                      child: Text(
                        'No se encontraron datos que cumplan con los filtros.',
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
                      ),
                    ),
                    // Esto es una solución para centrar el texto de "No data"
                  ),
                  ...List.generate(
                    (visibleColumns.values.where((v) => v).length) + 1,
                        (_) => const DataCell(SizedBox.shrink()),
                  ),
                ])
              ]
                  : filteredData.map((viewModel) {
                final item = viewModel.record;
                final isPhAlert = item.ph != null && (item.ph! < 6.5 || item.ph! > 8.5);
                final isTurbidityAlert = item.turbidity != null && item.turbidity! > 4;
                final isConductivityWarning = item.conductivity != null && item.conductivity! > 200;
                final isFlowAlert = item.flowRate != null && item.flowRate! < 5;

                return DataRow(
                  cells: [
                    // Timestamp
                    DataCell(
                      Text(
                        DateFormat('yyyy-MM-dd HH:mm:ss').format(item.timestamp),
                        style: const TextStyle(fontSize: 12, fontFamily: 'RobotoMono', color: primaryColor),
                      ),
                    ),
                    // pH
                    if (visibleColumns['pH']!)
                      DataCell(
                        Text(
                          item.ph?.toStringAsFixed(2) ?? 'N/A',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isPhAlert ? Colors.red.shade600 : const Color(0xFF002FA7),
                          ),
                        ),
                      ),
                    // Turbidez
                    if (visibleColumns['turbidez']!)
                      DataCell(
                        Text(
                          item.turbidity?.toStringAsFixed(2) ?? 'N/A',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isTurbidityAlert ? Colors.red.shade600 : const Color(0xFF89CFF0),
                          ),
                        ),
                      ),
                    // Conductividad
                    if (visibleColumns['conductividad']!)
                      DataCell(
                        Text(
                          item.conductivity?.toStringAsFixed(1) ?? 'N/A',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isConductivityWarning ? Colors.amber.shade600 : primaryColor,
                          ),
                        ),
                      ),
                    // Flujo
                    if (visibleColumns['flujo']!)
                      DataCell(
                        Text(
                          item.flowRate?.toStringAsFixed(1) ?? 'N/A',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isFlowAlert ? Colors.red.shade600 : darkPrimaryColor,
                          ),
                        ),
                      ),
                    // Estado
                    DataCell(
                      StatusBadge(status: viewModel.status), // Usamos el status del ViewModel
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: const Border(top: BorderSide(color: lighterBorder)),
              color: lightBlue.withOpacity(0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Período: $formattedDateFrom - $formattedDateTo',
                  style: const TextStyle(fontSize: 14, color: primaryColor),
                ),
                Text(
                  'Última actualización: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
                  style: const TextStyle(fontSize: 14, color: primaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}