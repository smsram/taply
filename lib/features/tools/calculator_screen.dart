import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _input = '';
  String _result = '0';
  double? _firstOperand;
  String? _operator;
  bool _isNewNumber = true;

  void _onDigit(String digit) {
    setState(() {
      if (_isNewNumber) {
        _input = digit;
        _isNewNumber = false;
      } else {
        if (_input.length < 12) {
          _input += digit;
        }
      }
      _result = _input;
    });
  }

  void _onDot() {
    setState(() {
      if (_isNewNumber) {
        _input = '0.';
        _isNewNumber = false;
      } else if (!_input.contains('.')) {
        _input += '.';
      }
      _result = _input;
    });
  }

  void _onOperator(String op) {
    setState(() {
      final current = double.tryParse(_result) ?? 0.0;
      if (_firstOperand == null) {
        _firstOperand = current;
      } else if (!_isNewNumber && _operator != null) {
        _calculate();
      }
      _operator = op;
      _isNewNumber = true;
    });
  }

  void _calculate() {
    if (_firstOperand == null || _operator == null) return;
    final secondOperand = double.tryParse(_result) ?? 0.0;
    double res = 0.0;

    switch (_operator) {
      case '+':
        res = _firstOperand! + secondOperand;
        break;
      case '-':
        res = _firstOperand! - secondOperand;
        break;
      case '×':
        res = _firstOperand! * secondOperand;
        break;
      case '÷':
        if (secondOperand == 0) {
          _result = 'Error';
          _firstOperand = null;
          _operator = null;
          _isNewNumber = true;
          return;
        }
        res = _firstOperand! / secondOperand;
        break;
    }

    // Format output cleanly (strip trailing zeroes if integer)
    if (res % 1 == 0) {
      _result = res.toInt().toString();
    } else {
      _result = res.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '');
    }
    _firstOperand = res;
    _isNewNumber = true;
  }

  void _onEquals() {
    setState(() {
      _calculate();
      _operator = null;
    });
  }

  void _onClear() {
    setState(() {
      _input = '';
      _result = '0';
      _firstOperand = null;
      _operator = null;
      _isNewNumber = true;
    });
  }

  void _onBackspace() {
    setState(() {
      if (_input.isNotEmpty) {
        _input = _input.substring(0, _input.length - 1);
        _result = _input.isEmpty ? '0' : _input;
      }
    });
  }

  void _onToggleSign() {
    setState(() {
      final val = double.tryParse(_result) ?? 0.0;
      final toggled = -val;
      _result = toggled % 1 == 0
          ? toggled.toInt().toString()
          : toggled.toString();
      _input = _result;
    });
  }

  void _onPercentage() {
    setState(() {
      final val = double.tryParse(_result) ?? 0.0;
      final pct = val / 100.0;
      _result = pct.toString();
      _input = _result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculator')),
      body: SafeArea(
        child: Column(
          children: [
            // Display Area
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.base,
                ),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_operator != null && _firstOperand != null)
                      Text(
                        '${_firstOperand! % 1 == 0 ? _firstOperand!.toInt() : _firstOperand} $_operator',
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: context.isDarkMode
                              ? AppColors.darkSecondaryText
                              : AppColors.secondaryText,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _result,
                        style: context.textTheme.headlineLarge?.copyWith(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),

            // Keypad Area
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _buildRow(['C', '±', '%', '÷'], isTopRow: true),
                    _buildRow(['7', '8', '9', '×']),
                    _buildRow(['4', '5', '6', '-']),
                    _buildRow(['1', '2', '3', '+']),
                    _buildRow(['0', '.', '⌫', '=']),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> labels, {bool isTopRow = false}) {
    return Expanded(
      child: Row(
        children: labels.map((label) {
          final isOp = ['÷', '×', '-', '+', '='].contains(label);
          final isSpecial = ['C', '±', '%', '⌫'].contains(label);

          Color? bgColor;
          Color? textColor;

          if (isOp) {
            bgColor = label == '='
                ? (context.isDarkMode
                      ? AppColors.darkPrimary
                      : AppColors.primary)
                : (context.isDarkMode
                      ? AppColors.darkElevatedSurface
                      : const Color(0xFFE0E7FF));
            textColor = label == '='
                ? Colors.white
                : (context.isDarkMode
                      ? const Color(0xFF93C5FD)
                      : AppColors.primary);
          } else if (isSpecial) {
            bgColor = context.isDarkMode
                ? AppColors.darkSurface
                : const Color(0xFFF1F5F9);
            textColor = context.isDarkMode
                ? AppColors.darkPrimaryText
                : AppColors.primaryText;
          }

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Material(
                color: bgColor ?? context.colorScheme.surface,
                borderRadius: AppSpacing.borderRadiusMd,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    if (label == 'C') {
                      _onClear();
                    } else if (label == '⌫') {
                      _onBackspace();
                    } else if (label == '±') {
                      _onToggleSign();
                    } else if (label == '%') {
                      _onPercentage();
                    } else if (label == '.') {
                      _onDot();
                    } else if (label == '=') {
                      _onEquals();
                    } else if (['+', '-', '×', '÷'].contains(label)) {
                      _onOperator(label);
                    } else {
                      _onDigit(label);
                    }
                  },
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: isOp || isSpecial
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: textColor ?? context.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
