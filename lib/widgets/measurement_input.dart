import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'approximation_chips.dart';

/// 検尺/容量入力フィールド
/// 数値入力とその近似値表示を組み合わせたウィジェット
class MeasurementInput extends StatelessWidget {
  // テキストコントローラ
  final TextEditingController controller;
  
  // ラベル
  final String label;
  
  // 入力ヒント
  final String hint;
  
  // アイコン
  final IconData icon;
  
  // 単位（L または mm）
  final String unit;
  
  // 値変更時のコールバック
  final Function(String)? onChanged;
  
  // 近似値リスト
  final List<Map<String, double>> approximations;
  
  // 近似値選択時のコールバック
  final Function(double, double)? onApproximationSelected;
  
  // 近似値をロード中かどうか
  final bool isLoadingApproximations;
  
  // 入力検証
  final String? Function(String?)? validator;

  const MeasurementInput({
    Key? key,
    required this.controller,
    required this.label,
    this.hint = '',
    required this.icon,
    required this.unit,
    this.onChanged,
    this.approximations = const [],
    this.onApproximationSelected,
    this.isLoadingApproximations = false,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 数値入力フィールド
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '$label ($unit)',
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixText: unit,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          onChanged: onChanged,
          validator: validator,
        ),
        
        // 近似値チップ（存在する場合のみ表示）
        if (approximations.isNotEmpty || isLoadingApproximations)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (approximations.isNotEmpty || isLoadingApproximations)
                  Text(
                    '近似値:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                SizedBox(height: 4),
                ApproximationChips(
                  approximations: approximations,
                  selectedValue: null, // 値入力時は選択状態にしない
                  selectByCapacity: unit == 'L', // 単位に応じて選択方法を切り替え
                  onSelected: (value, pairedValue) {
                    // 選択された値をコントローラにセット
                    controller.text = value.toString();
                    // コールバックがあれば呼び出し
                    if (onApproximationSelected != null) {
                      onApproximationSelected!(value, pairedValue);
                    }
                  },
                  isLoading: isLoadingApproximations,
                  useSmallChips: true,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 検尺/容量入力ペア
/// 検尺と容量の入力フィールドを対応させて表示・処理するウィジェット
class MeasurementInputPair extends StatelessWidget {
  // 検尺コントローラ
  final TextEditingController measurementController;
  
  // 容量コントローラ
  final TextEditingController volumeController;
  
  // タンク番号
  final String? tankNumber;
  
  // 検尺変更時コールバック
  final Function(double?)? onMeasurementChanged;
  
  // 容量変更時コールバック
  final Function(double?)? onVolumeChanged;
  
  // 検尺→容量変換ボタンクリック時
  final VoidCallback? onCalculateVolume;
  
  // 容量→検尺変換ボタンクリック時
  final VoidCallback? onCalculateMeasurement;
  
  // 検尺の近似値
  final List<Map<String, double>> measurementApproximations;
  
  // 容量の近似値
  final List<Map<String, double>> volumeApproximations;
  
  // 近似値ロード状態
  final bool isLoadingMeasurementApproximations;
  final bool isLoadingVolumeApproximations;
  
  // 検尺近似値選択時コールバック
  final Function(double, double)? onMeasurementApproximationSelected;
  
  // 容量近似値選択時コールバック
  final Function(double, double)? onVolumeApproximationSelected;

  const MeasurementInputPair({
    Key? key,
    required this.measurementController,
    required this.volumeController,
    this.tankNumber,
    this.onMeasurementChanged,
    this.onVolumeChanged,
    this.onCalculateVolume,
    this.onCalculateMeasurement,
    this.measurementApproximations = const [],
    this.volumeApproximations = const [],
    this.isLoadingMeasurementApproximations = false,
    this.isLoadingVolumeApproximations = false,
    this.onMeasurementApproximationSelected,
    this.onVolumeApproximationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 容量入力
            Expanded(
              child: MeasurementInput(
                controller: volumeController,
                label: '容量',
                hint: '例: 2500',
                icon: Icons.water_drop,
                unit: 'L',
                onChanged: (value) {
                  if (onVolumeChanged != null) {
                    onVolumeChanged!(double.tryParse(value));
                  }
                },
                approximations: volumeApproximations,
                isLoadingApproximations: isLoadingVolumeApproximations,
                onApproximationSelected: onVolumeApproximationSelected,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '容量を入力してください';
                  }
                  if (double.tryParse(value) == null) {
                    return '有効な数値を入力してください';
                  }
                  return null;
                },
              ),
            ),
            
            SizedBox(width: 16),
            
            // 検尺入力
            Expanded(
              child: MeasurementInput(
                controller: measurementController,
                label: '検尺',
                hint: '例: 1250',
                icon: Icons.straighten,
                unit: 'mm',
                onChanged: (value) {
                  if (onMeasurementChanged != null) {
                    onMeasurementChanged!(double.tryParse(value));
                  }
                },
                approximations: measurementApproximations,
                isLoadingApproximations: isLoadingMeasurementApproximations,
                onApproximationSelected: onMeasurementApproximationSelected,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '検尺を入力してください';
                  }
                  if (double.tryParse(value) == null) {
                    return '有効な数値を入力してください';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        
        SizedBox(height: 12),
        
        // 変換ボタン
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 容量→検尺変換
              ElevatedButton.icon(
                icon: Icon(Icons.arrow_forward, size: 16),
                label: Text('容量から検尺'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue[700],
                ),
                onPressed: tankNumber == null ? null : onCalculateMeasurement,
              ),
              
              SizedBox(width: 8),
              
              // 検尺→容量変換
              ElevatedButton.icon(
                icon: Icon(Icons.arrow_back, size: 16),
                label: Text('検尺から容量'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green[700],
                ),
                onPressed: tankNumber == null ? null : onCalculateVolume,
              ),
            ],
          ),
        ),
      ],
    );
  }
}