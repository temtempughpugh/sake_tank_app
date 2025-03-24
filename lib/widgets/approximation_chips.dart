import 'package:flutter/material.dart';

/// 近似値選択のためのチップセットウィジェット
/// 容量や検尺の近似値を表示し、選択できるようにする
class ApproximationChips extends StatelessWidget {
  // 選択対象の近似値ペアのリスト (capacity, measurement)
  final List<Map<String, double>> approximations;
  
  // 現在選択されている値（null可）
  final double? selectedValue;
  
  // 容量と検尺のどちらで選択するか
  final bool selectByCapacity;
  
  // 値が選択された時のコールバック
  final Function(double value, double pairedValue) onSelected;
  
  // ロード中かどうか
  final bool isLoading;
  
  // サイズ調整用（小さいチップを表示するか）
  final bool useSmallChips;
  
  // 丸め桁数
  final int decimalPlaces;

  const ApproximationChips({
    Key? key,
    required this.approximations,
    this.selectedValue,
    required this.selectByCapacity,
    required this.onSelected,
    this.isLoading = false,
    this.useSmallChips = false,
    this.decimalPlaces = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 40,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('近似値を読み込み中...', 
            style: TextStyle(
              fontSize: 12, 
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    if (approximations.isEmpty) {
      return SizedBox.shrink();
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 6.0,
      children: approximations.map((pair) {
        // 選択対象の値と対応するペア値を取得
        final targetValue = selectByCapacity ? pair['capacity']! : pair['measurement']!;
        final pairedValue = selectByCapacity ? pair['measurement']! : pair['capacity']!;
        
        // 目標値を表示するテキスト
        final displayText = '${targetValue.toStringAsFixed(decimalPlaces)} ${selectByCapacity ? 'L' : 'mm'}';
        
        // 選択状態
        final isSelected = selectedValue == targetValue;
        
        return useSmallChips
            ? _buildCompactChip(context, targetValue, pairedValue, displayText, isSelected)
            : _buildStandardChip(context, targetValue, pairedValue, displayText, isSelected);
      }).toList(),
    );
  }

  Widget _buildStandardChip(BuildContext context, double value, double pairedValue, 
                          String label, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onSelected(value, pairedValue);
        }
      },
      selectedColor: Colors.blue[100],
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue[800] : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildCompactChip(BuildContext context, double value, double pairedValue, 
                         String label, bool isSelected) {
    return InkWell(
      onTap: () => onSelected(value, pairedValue),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.blue[800] : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}