import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:water_tap_front/domain/models/entities/filter_state.dart';

// Colores basados en el diseño Tailwind/Shadcn
const Color primaryColor = Color(0xFF5D89BA);
const Color darkPrimaryColor = Color(0xFF1E2952);
const Color onPrimaryColor = Colors.white;

class FilterSidebarProps {
  final FilterState filters;
  final ValueChanged<FilterState> onFiltersChange;
  final VoidCallback? onGenerate;
  final VoidCallback? onReset;
  final String generateButtonText;
  final bool showResetButton;

  const FilterSidebarProps({
    required this.filters,
    required this.onFiltersChange,
    this.onGenerate,
    this.onReset,
    this.generateButtonText = "Generar Gráfica",
    this.showResetButton = true,
  });
}

// ----------------------------------------------------------------------
// 2. Widget de la Barra Lateral
// ----------------------------------------------------------------------

class FilterSidebar extends StatefulWidget {
  final FilterSidebarProps props;

  const FilterSidebar({super.key, required this.props});

  @override
  State<FilterSidebar> createState() => _FilterSidebarState();
}

class _FilterSidebarState extends State<FilterSidebar> {
  // --- Handlers de Cambio de Estado ---

  void _handleDateChange(bool isFrom, DateTime? date) {
    final newFilters = isFrom
        ? widget.props.filters.copyWith(dateFrom: date)
        : widget.props.filters.copyWith(dateTo: date);
    widget.props.onFiltersChange(newFilters);
  }

  void _handleTimeChange(bool isFrom, TimeOfDay? time) {
    final newFilters = isFrom
        ? widget.props.filters.copyWith(timeFrom: time)
        : widget.props.filters.copyWith(timeTo: time);
    widget.props.onFiltersChange(newFilters);
  }

  void _handleVariableCheckboxChange(String variable, bool checked) {
    final newVariables = Map<String, bool>.from(widget.props.filters.variables);
    newVariables[variable] = checked;

    final newFilters = widget.props.filters.copyWith(variables: newVariables);
    widget.props.onFiltersChange(newFilters);
  }

  void _handleRangeChange(String variable, RangeValues values) {
    final newRangeMap = Map<String, VariableRange>.from(widget.props.filters.range);

    // Usamos el copyWith de VariableRange
    final newRange = VariableRange(min: values.start, max: values.end);
    newRangeMap[variable] = newRange;

    final newFilters = widget.props.filters.copyWith(range: newRangeMap);
    widget.props.onFiltersChange(newFilters);
  }

  // --- Widgets de Inputs y Sliders ---

  Widget _buildDateInput(bool isFrom) {
    final DateTime? currentDate = isFrom ? widget.props.filters.dateFrom : widget.props.filters.dateTo;
    final String label = isFrom ? 'Fecha Inicio' : 'Fecha Fin';
    final String formattedDate = currentDate != null ? DateFormat('yyyy-MM-dd').format(currentDate) : '';

    return Flexible(
      child: InkWell(
        onTap: () async {
          final selectedDate = await showDatePicker(
            context: context,
            initialDate: currentDate ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            builder: (context, child) => Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(primary: darkPrimaryColor),
              ),
              child: child!,
            ),
          );
          _handleDateChange(isFrom, selectedDate);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: onPrimaryColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            formattedDate.isNotEmpty ? formattedDate : label,
            style: TextStyle(
              color: formattedDate.isNotEmpty ? Colors.black : Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInput(bool isFrom) {
    final TimeOfDay? currentTime = isFrom ? widget.props.filters.timeFrom : widget.props.filters.timeTo;
    final TimeOfDay initialTime = isFrom ? const TimeOfDay(hour: 0, minute: 0) : const TimeOfDay(hour: 23, minute: 59);

    // Formatear el texto
    final String formattedTime = currentTime?.format(context) ?? (isFrom ? '00:00' : '23:59');

    return Flexible(
      child: InkWell(
        onTap: () async {
          final selectedTime = await showTimePicker(
            context: context,
            initialTime: currentTime ?? initialTime,
            builder: (context, child) => Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(primary: darkPrimaryColor),
              ),
              child: child!,
            ),
          );
          _handleTimeChange(isFrom, selectedTime);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: onPrimaryColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            formattedTime,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRangeSlider(String variableName, String label, double minLimit, double maxLimit) {
    final VariableRange? currentRange = widget.props.filters.range[variableName];
    final double min = currentRange?.min ?? minLimit;
    final double max = currentRange?.max ?? maxLimit;

    final double step = variableName == 'pH' ? 0.1 : 1;
    final int effectiveDivisions = ((maxLimit - minLimit) / step).round();

    return Container(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: onPrimaryColor, fontSize: 13)),
          const SizedBox(height: 8),
          RangeSlider(
            min: minLimit,
            max: maxLimit,
            values: RangeValues(min, max),
            divisions: effectiveDivisions,
            activeColor: onPrimaryColor,
            inactiveColor: onPrimaryColor.withOpacity(0.3),
            onChanged: (RangeValues newValues) {
              _handleRangeChange(variableName, newValues);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min: ${min.toStringAsFixed(step == 0.1 ? 1 : 0)}',
                style: TextStyle(fontSize: 12, color: onPrimaryColor.withOpacity(0.8)),
              ),
              Text(
                'Max: ${max.toStringAsFixed(step == 0.1 ? 1 : 0)}',
                style: TextStyle(fontSize: 12, color: onPrimaryColor.withOpacity(0.8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usamos widget.props.filters para acceder al estado inmutable pasado por el padre
    final FilterState filters = widget.props.filters;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 8,
      color: primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 256,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- 1. Título ---
            const Text(
              "Filtros",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: onPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),

            // --- 2. Filtro de Fecha ---
            const Text("Fecha", style: TextStyle(color: onPrimaryColor)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildDateInput(true),
                const SizedBox(width: 8),
                Container(width: 16, height: 2, color: onPrimaryColor),
                const SizedBox(width: 8),
                _buildDateInput(false),
              ],
            ),
            const SizedBox(height: 16),

            // --- 3. Filtro de Hora ---
            const Text("Hora", style: TextStyle(color: onPrimaryColor)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTimeInput(true),
                const SizedBox(width: 16),
                _buildTimeInput(false),
              ],
            ),
            const SizedBox(height: 16),

            // --- Separador ---
            Divider(color: onPrimaryColor.withOpacity(0.3)),
            const SizedBox(height: 16),

            // --- 4. Filtros de Variables y Rangos ---
            const Text("Variables", style: TextStyle(color: onPrimaryColor)),
            const SizedBox(height: 8),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // pH
                _buildVariableFilter('pH', 'pH', filters.variables['pH']!, () =>
                    _buildRangeSlider('pH', 'Rango de pH (0-14)', 0, 14)),

                // Conductividad
                _buildVariableFilter('conductividad', 'Conductividad', filters.variables['conductividad']!, () =>
                    _buildRangeSlider('conductividad', 'Rango de Conductividad (0-1000)', 0, 1000)),

                // Turbidez
                _buildVariableFilter('turbidez', 'Turbidez', filters.variables['turbidez']!, () =>
                    _buildRangeSlider('turbidez', 'Rango de Turbidez (0-10)', 0, 10)),

                // Flujo
                _buildVariableFilter('flujo', 'Flujo', filters.variables['flujo']!, () =>
                    _buildRangeSlider('flujo', 'Rango de Flujo (0-100)', 0, 100)),
              ],
            ),

            const SizedBox(height: 24),

            // --- 5. Botones ---
            if (widget.props.onGenerate != null)
              ElevatedButton(
                onPressed: widget.props.onGenerate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkPrimaryColor,
                  foregroundColor: onPrimaryColor,
                  minimumSize: const Size(double.infinity, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  elevation: 0,
                ),
                child: Text(widget.props.generateButtonText),
              ),

            if (widget.props.showResetButton && widget.props.onReset != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: OutlinedButton(
                  onPressed: widget.props.onReset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: onPrimaryColor,
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: onPrimaryColor),
                    minimumSize: const Size(double.infinity, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text("Resetear Filtros"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper para construir la sección de Checkbox + Slider
  Widget _buildVariableFilter(String variableKey, String label, bool isChecked, Widget Function() rangeSliderBuilder) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _handleVariableCheckboxChange(variableKey, !isChecked),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isChecked ? onPrimaryColor : Colors.transparent,
                    border: Border.all(color: onPrimaryColor, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isChecked
                      ? const Icon(Icons.check, size: 12, color: primaryColor)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: onPrimaryColor, fontSize: 14)),
              ],
            ),
          ),
          if (isChecked) rangeSliderBuilder(),
        ],
      ),
    );
  }
}