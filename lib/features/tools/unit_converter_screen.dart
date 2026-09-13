import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';

enum ConversionType { length, weight, temperature }

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  ConversionType _type = ConversionType.length;
  final TextEditingController _inputController = TextEditingController(
    text: '1',
  );
  String _fromUnit = 'Meters';
  String _toUnit = 'Feet';
  String _result = '3.2808';

  final Map<ConversionType, List<String>> _units = {
    ConversionType.length: [
      'Meters',
      'Kilometers',
      'Centimeters',
      'Feet',
      'Inches',
      'Miles',
    ],
    ConversionType.weight: ['Kilograms', 'Grams', 'Pounds', 'Ounces'],
    ConversionType.temperature: ['Celsius', 'Fahrenheit', 'Kelvin'],
  };

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_convert);
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _convert() {
    final value = double.tryParse(_inputController.text) ?? 0.0;
    double calculated = 0.0;

    if (_type == ConversionType.length) {
      // Base: meters
      double inMeters = 0.0;
      switch (_fromUnit) {
        case 'Meters':
          inMeters = value;
          break;
        case 'Kilometers':
          inMeters = value * 1000;
          break;
        case 'Centimeters':
          inMeters = value / 100;
          break;
        case 'Feet':
          inMeters = value * 0.3048;
          break;
        case 'Inches':
          inMeters = value * 0.0254;
          break;
        case 'Miles':
          inMeters = value * 1609.344;
          break;
      }
      switch (_toUnit) {
        case 'Meters':
          calculated = inMeters;
          break;
        case 'Kilometers':
          calculated = inMeters / 1000;
          break;
        case 'Centimeters':
          calculated = inMeters * 100;
          break;
        case 'Feet':
          calculated = inMeters / 0.3048;
          break;
        case 'Inches':
          calculated = inMeters / 0.0254;
          break;
        case 'Miles':
          calculated = inMeters / 1609.344;
          break;
      }
    } else if (_type == ConversionType.weight) {
      // Base: kilograms
      double inKg = 0.0;
      switch (_fromUnit) {
        case 'Kilograms':
          inKg = value;
          break;
        case 'Grams':
          inKg = value / 1000;
          break;
        case 'Pounds':
          inKg = value * 0.45359237;
          break;
        case 'Ounces':
          inKg = value * 0.0283495;
          break;
      }
      switch (_toUnit) {
        case 'Kilograms':
          calculated = inKg;
          break;
        case 'Grams':
          calculated = inKg * 1000;
          break;
        case 'Pounds':
          calculated = inKg / 0.45359237;
          break;
        case 'Ounces':
          calculated = inKg / 0.0283495;
          break;
      }
    } else {
      // Temperature
      if (_fromUnit == _toUnit) {
        calculated = value;
      } else if (_fromUnit == 'Celsius' && _toUnit == 'Fahrenheit') {
        calculated = (value * 9 / 5) + 32;
      } else if (_fromUnit == 'Celsius' && _toUnit == 'Kelvin') {
        calculated = value + 273.15;
      } else if (_fromUnit == 'Fahrenheit' && _toUnit == 'Celsius') {
        calculated = (value - 32) * 5 / 9;
      } else if (_fromUnit == 'Fahrenheit' && _toUnit == 'Kelvin') {
        calculated = (value - 32) * 5 / 9 + 273.15;
      } else if (_fromUnit == 'Kelvin' && _toUnit == 'Celsius') {
        calculated = value - 273.15;
      } else if (_fromUnit == 'Kelvin' && _toUnit == 'Fahrenheit') {
        calculated = (value - 273.15) * 9 / 5 + 32;
      }
    }

    setState(() {
      _result = calculated
          .toStringAsFixed(4)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    });
  }

  void _onTypeChanged(ConversionType type) {
    setState(() {
      _type = type;
      _fromUnit = _units[type]![0];
      _toUnit = _units[type]![1];
      _convert();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unit Converter')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.base),
          children: [
            SegmentedButton<ConversionType>(
              segments: const [
                ButtonSegment(
                  value: ConversionType.length,
                  label: Text('Length'),
                ),
                ButtonSegment(
                  value: ConversionType.weight,
                  label: Text('Weight'),
                ),
                ButtonSegment(
                  value: ConversionType.temperature,
                  label: Text('Temp'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (set) => _onTypeChanged(set.first),
            ),
            const SizedBox(height: AppSpacing.lg),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  children: [
                    TextField(
                      controller: _inputController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        labelText: 'From Value',
                        suffixIcon: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _fromUnit,
                            items: _units[_type]!
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _fromUnit = val);
                                _convert();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    IconButton(
                      icon: const Icon(Icons.swap_vert_rounded),
                      onPressed: () {
                        setState(() {
                          final tmp = _fromUnit;
                          _fromUnit = _toUnit;
                          _toUnit = tmp;
                          _convert();
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.base),
                      decoration: BoxDecoration(
                        color: context.colorScheme.onSurface.withOpacity(0.04),
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Converted Result',
                                style: context.textTheme.labelMedium,
                              ),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _toUnit,
                                  items: _units[_type]!
                                      .map(
                                        (u) => DropdownMenuItem(
                                          value: u,
                                          child: Text(u),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _toUnit = val);
                                      _convert();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '$_result $_toUnit',
                            style: context.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: context.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
