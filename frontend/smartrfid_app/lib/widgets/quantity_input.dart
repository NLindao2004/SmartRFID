import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuantityInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? helperText;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool autofocus;
  final int? maxValue;
  final int? minValue;
  final TextInputAction? textInputAction;
  final VoidCallback? onChanged;
  final VoidCallback? onEditingComplete;
  final bool showIncrementButtons;
  final IconData? prefixIcon;

  const QuantityInput({
    super.key,
    required this.controller,
    this.label = 'Cantidad',
    this.helperText,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
    this.maxValue,
    this.minValue,
    this.textInputAction,
    this.onChanged,
    this.onEditingComplete,
    this.showIncrementButtons = true,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                enabled: enabled,
                autofocus: autofocus,
                keyboardType: TextInputType.number,
                textInputAction: textInputAction ?? TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  if (maxValue != null) 
                    _MaxValueTextInputFormatter(maxValue!),
                ],
                decoration: InputDecoration(
                  labelText: label,
                  helperText: helperText,
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(prefixIcon ?? Icons.numbers),
                  suffixIcon: showIncrementButtons ? null : _buildClearButton(),
                  errorMaxLines: 2,
                ),
                validator: validator ?? _defaultValidator,
                onChanged: (value) => onChanged?.call(),
                onEditingComplete: onEditingComplete,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Botones de incremento/decremento
            if (showIncrementButtons) ...[
              const SizedBox(width: 8),
              Column(
                children: [
                  _IncrementButton(
                    icon: Icons.add,
                    onPressed: enabled ? _increment : null,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 4),
                  _IncrementButton(
                    icon: Icons.remove,
                    onPressed: enabled ? _decrement : null,
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ],
        ),
        
        // Botones de cantidad rápida
        if (enabled) ...[
          const SizedBox(height: 8),
          _buildQuickQuantityButtons(context), // ✅ CORREGIDO: pasar context
        ],
      ],
    );
  }

  Widget _buildClearButton() {
    return IconButton(
      icon: const Icon(Icons.clear),
      onPressed: enabled ? () {
        controller.clear();
        onChanged?.call();
      } : null,
    );
  }

  // ✅ CORREGIDO: Agregar BuildContext como parámetro
  Widget _buildQuickQuantityButtons(BuildContext context) {
    final quickValues = [1, 5, 10, 25, 50, 100];
    
    // ✅ CORREGIDO: Extraer el tema fuera del map
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final currentText = controller.text;
    
    return Wrap(
      spacing: 4,
      children: quickValues.map((value) {
        if (maxValue != null && value > maxValue!) return const SizedBox.shrink();
        
        // ✅ CORREGIDO: Usar variables extraídas en lugar de context directamente
        final isSelected = currentText == value.toString();
        
        return InkWell(
          onTap: () {
            controller.text = value.toString();
            onChanged?.call();
            HapticFeedback.selectionClick();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
              color: isSelected 
                  ? primaryColor.withOpacity(0.1)
                  : null,
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? primaryColor
                    : Colors.grey.shade600,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _increment() {
    final currentValue = int.tryParse(controller.text) ?? 0;
    final newValue = currentValue + 1;
    
    if (maxValue == null || newValue <= maxValue!) {
      controller.text = newValue.toString();
      onChanged?.call();
      HapticFeedback.selectionClick();
    }
  }

  void _decrement() {
    final currentValue = int.tryParse(controller.text) ?? 0;
    final newValue = currentValue - 1;
    final minVal = minValue ?? 0;
    
    if (newValue >= minVal) {
      controller.text = newValue.toString();
      onChanged?.call();
      HapticFeedback.selectionClick();
    }
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese una cantidad';
    }
    
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Ingrese un número válido';
    }
    
    final minVal = minValue ?? 0;
    if (intValue < minVal) {
      return 'La cantidad debe ser mayor o igual a $minVal';
    }
    
    if (maxValue != null && intValue > maxValue!) {
      return 'La cantidad no puede ser mayor a $maxValue';
    }
    
    return null;
  }
}

// Widget para botones de incremento/decremento
class _IncrementButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  const _IncrementButton({
    required this.icon,
    this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: onPressed != null ? color.withOpacity(0.1) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Icon(
            icon,
            size: 20,
            color: onPressed != null ? color : Colors.grey,
          ),
        ),
      ),
    );
  }
}

// Formateador personalizado para valor máximo
class _MaxValueTextInputFormatter extends TextInputFormatter {
  final int maxValue;

  _MaxValueTextInputFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final intValue = int.tryParse(newValue.text);
    if (intValue == null || intValue > maxValue) {
      return oldValue;
    }

    return newValue;
  }
}

// Widget especializado para entrada de peso
class WeightInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;
  final double? maxWeight;
  final double? minWeight;
  final String? Function(String?)? validator;
  final bool enabled;

  const WeightInput({
    super.key,
    required this.controller,
    this.label = 'Peso',
    this.unit = 'kg',
    this.maxWeight,
    this.minWeight,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.scale),
        suffixText: unit,
        helperText: _buildHelperText(),
      ),
      validator: validator ?? _defaultWeightValidator,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String? _buildHelperText() {
    if (minWeight != null && maxWeight != null) {
      return 'Entre $minWeight y $maxWeight $unit';
    } else if (minWeight != null) {
      return 'Mínimo $minWeight $unit';
    } else if (maxWeight != null) {
      return 'Máximo $maxWeight $unit';
    }
    return null;
  }

  String? _defaultWeightValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese el peso';
    }
    
    final doubleValue = double.tryParse(value);
    if (doubleValue == null) {
      return 'Ingrese un peso válido';
    }
    
    if (minWeight != null && doubleValue < minWeight!) {
      return 'El peso debe ser mayor o igual a $minWeight $unit';
    }
    
    if (maxWeight != null && doubleValue > maxWeight!) {
      return 'El peso no puede ser mayor a $maxWeight $unit';
    }
    
    return null;
  }
}

// Widget para selección de cantidad con slider
class QuantitySlider extends StatefulWidget {
  final int value;
  final int min;
  final int max;
  final String label;
  final ValueChanged<int> onChanged;
  final bool enabled;

  const QuantitySlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.label = 'Cantidad',
    this.enabled = true,
  });

  @override
  State<QuantitySlider> createState() => _QuantitySliderState();
}

class _QuantitySliderState extends State<QuantitySlider> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.value.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Slider(
          value: widget.value.toDouble(),
          min: widget.min.toDouble(),
          max: widget.max.toDouble(),
          divisions: widget.max - widget.min,
          onChanged: widget.enabled ? (value) {
            widget.onChanged(value.round());
            HapticFeedback.selectionClick();
          } : null,
        ),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.min.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              widget.max.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}