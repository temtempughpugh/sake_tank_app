// lib/widgets/manual_input_field.dart
import 'package:flutter/material.dart';

/// 手動入力フィールドウィジェット
/// 
/// 表示モードと編集モードを切り替え可能なフィールド
class ManualInputField extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final TextEditingController controller;
  final bool isManualMode;
  final ValueChanged<bool> onManualModeChanged;
  final ValueChanged<String> onValueChanged;
  final Color? valueColor;
  final double fontSize;
  final TextInputType keyboardType;
  
  const ManualInputField({
    Key? key,
    required this.label,
    required this.value,
    required this.suffix,
    required this.controller,
    required this.isManualMode,
    required this.onManualModeChanged,
    required this.onValueChanged,
    this.valueColor,
    this.fontSize = 14,
    this.keyboardType = TextInputType.number,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Text(label),
          const SizedBox(width: 8),
          Expanded(
            child: isManualMode
                ? TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      suffixText: suffix,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: keyboardType,
                    onChanged: onValueChanged,
                  )
                : Text(
                    value,
                    style: TextStyle(
                      color: valueColor,
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                  ),
          ),
          Switch(
            value: isManualMode,
            onChanged: onManualModeChanged,
            activeColor: valueColor ?? Colors.blue,
          ),
        ],
      ),
    );
  }
}