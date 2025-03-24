import 'package:flutter/material.dart';
import '../models/measurement_result.dart';
import 'approximation_chips.dart';

/// 計算結果を表示するカードウィジェット
class ResultCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Map<String, String> data;
  final String? highlightKey;
  final bool isError;
  final IconData? icon;

  const ResultCard({
    Key? key,
    required this.title,
    this.subtitle,
    required this.data,
    this.highlightKey,
    this.isError = false,
    this.icon,
  }) : super(key: key);

  /// 検尺→容量変換結果カードを作成するファクトリメソッド
  factory ResultCard.measurementToCapacity(MeasurementResult result, String tankNumber) {
    if (result.isOverLimit) {
      return ResultCard(
        title: '検尺上限を越えています',
        data: {
          'タンク番号:': tankNumber,
          '入力した検尺:': '${result.measurement.toStringAsFixed(1)} mm',
          '最大検尺:': '上限を確認してください',
        },
        isError: true,
        icon: Icons.error_outline,
      );
    } else if (result.isOverCapacity) {
      return ResultCard(
        title: '容量をオーバーしています',
        data: {
          'タンク番号:': tankNumber,
          '入力した検尺:': '${result.measurement.toStringAsFixed(1)} mm',
          '最大容量:': '${result.capacity.toStringAsFixed(1)} L',
          '注意:': '検尺が0の時が最大容量です',
        },
        isError: true,
        icon: Icons.error_outline,
      );
    } else {
      return ResultCard(
        title: '検尺から容量の計算結果',
        subtitle: result.isExactMatch 
            ? null 
            : '指定した検尺値に正確にマッチするデータがないため、近似値を表示しています',
        data: {
          'タンク番号:': tankNumber,
          '検尺:': '${result.measurement.toStringAsFixed(1)} mm',
          '容量:': '${result.capacity.toStringAsFixed(1)} L',
        },
        highlightKey: '容量:',
        icon: Icons.check_circle_outline,
      );
    }
  }

  /// 容量→検尺変換結果カードを作成するファクトリメソッド
  factory ResultCard.capacityToMeasurement(MeasurementResult result, String tankNumber) {
    if (result.isOverCapacity) {
      return ResultCard(
        title: '容量をオーバーしています',
        data: {
          'タンク番号:': tankNumber,
          '入力した容量:': '上限を超えています',
          '最大容量:': '${result.capacity.toStringAsFixed(1)} L（検尺: ${result.measurement.toStringAsFixed(1)} mm）',
          '注意:': '検尺が0の時が最大容量です',
        },
        isError: true,
        icon: Icons.error_outline,
      );
    } else if (result.isOverLimit) {
      return ResultCard(
        title: '検尺上限を越えています',
        data: {
          'タンク番号:': tankNumber,
          '入力した容量:': '下限を下回っています',
          '最小容量:': '${result.capacity.toStringAsFixed(1)} L（検尺: ${result.measurement.toStringAsFixed(1)} mm）',
        },
        isError: true,
        icon: Icons.error_outline,
      );
    } else {
      return ResultCard(
        title: '容量から検尺の計算結果',
        subtitle: result.isExactMatch 
            ? null 
            : '指定した容量に正確にマッチするデータがないため、近似値を表示しています',
        data: {
          'タンク番号:': tankNumber,
          '希望容量:': '${result.capacity.toStringAsFixed(1)} L',
          '必要な検尺:': '${result.measurement.toStringAsFixed(1)} mm',
        },
        highlightKey: '必要な検尺:',
        icon: Icons.check_circle_outline,
      );
    }
  }

  /// 割水計算結果カードを作成するファクトリメソッド
  factory ResultCard.dilutionResult({
    required double initialVolume,
    required double initialAlcohol,
    required double targetAlcohol,
    required double waterToAdd,
    required double finalVolume,
    double? finalMeasurement,
    String? tankNumber,
    List<Map<String, double>> approximations = const [],
    double? selectedFinalVolume,
    double? selectedFinalMeasurement,
    double? adjustedWaterToAdd,
    double? actualAlcohol,
    Function(double, double)? onApproximationSelected,
  }) {
    final Map<String, String> data = {
      if (tankNumber != null) 'タンク番号:': tankNumber,
      '現在の容量:': '${initialVolume.toStringAsFixed(1)} L',
      '現在のアルコール度数:': '${initialAlcohol.toStringAsFixed(1)} %',
      '目標アルコール度数:': '${targetAlcohol.toStringAsFixed(1)} %',
      '追加する水量:': '${(selectedFinalVolume != null ? adjustedWaterToAdd : waterToAdd)!.toStringAsFixed(1)} L',
      '割水後の合計容量:': '${(selectedFinalVolume ?? finalVolume).toStringAsFixed(1)} L',
    };
    
    if (finalMeasurement != null || selectedFinalMeasurement != null) {
      data['割水後の検尺:'] = '${(selectedFinalMeasurement ?? finalMeasurement)!.toStringAsFixed(1)} mm';
    }
    
    if (actualAlcohol != null) {
      data['実際のアルコール度数:'] = '${actualAlcohol.toStringAsFixed(2)} %';
    }
    
    return ResultCard(
      title: '割水計算結果',
      data: data,
      highlightKey: '追加する水量:',
      icon: Icons.water_drop,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: isError ? Colors.red[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー部分
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: isError ? Colors.red : Colors.blue[700],
                    size: 24,
                  ),
                  SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isError ? Colors.red[800] : null,
                  ),
                ),
              ],
            ),
            
            Divider(),
            
            // サブタイトル（存在する場合）
            if (subtitle != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  subtitle!,
                  style: TextStyle(
                    color: isError ? Colors.red[800] : Colors.orange[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            
            // データ項目
            ...data.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key),
                  Text(
                    entry.value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: highlightKey != null && entry.key == highlightKey ? 20 : 16,
                      color: highlightKey != null && entry.key == highlightKey
                          ? (isError ? Colors.red[800] : Theme.of(context).primaryColor)
                          : (isError ? Colors.red[800] : null),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}

/// 割水計算結果カード（近似値選択機能付き）
class DilutionResultCard extends StatelessWidget {
  final double initialVolume;
  final double initialAlcohol;
  final double targetAlcohol;
  final double waterToAdd;
  final double finalVolume;
  final double? finalMeasurement;
  final String? tankNumber;
  final List<Map<String, double>> approximations;
  final double? selectedFinalVolume;
  final double? selectedFinalMeasurement;
  final double? adjustedWaterToAdd;
  final double? actualAlcohol;
  final Function(double, double)? onApproximationSelected;
  final bool isExactMatch;

  const DilutionResultCard({
    Key? key,
    required this.initialVolume,
    required this.initialAlcohol,
    required this.targetAlcohol,
    required this.waterToAdd,
    required this.finalVolume,
    this.finalMeasurement,
    this.tankNumber,
    this.approximations = const [],
    this.selectedFinalVolume,
    this.selectedFinalMeasurement,
    this.adjustedWaterToAdd,
    this.actualAlcohol,
    this.onApproximationSelected,
    this.isExactMatch = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '計算結果',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (!isExactMatch)
                  Chip(
                    label: Text('近似値'),
                    backgroundColor: Colors.orange[100],
                  ),
              ],
            ),
            Divider(),
            
            // 結果テーブル
            if (tankNumber != null)
              _buildResultRow('タンク番号:', tankNumber!),
              
            _buildResultRow('現在の容量:', '${initialVolume.toStringAsFixed(1)} L'),
            _buildResultRow('現在のアルコール度数:', '${initialAlcohol.toStringAsFixed(1)} %'),
            _buildResultRow('目標アルコール度数:', '${targetAlcohol.toStringAsFixed(1)} %'),
            
            _buildResultRow(
              '追加する水量:',
              '${(selectedFinalVolume != null ? adjustedWaterToAdd : waterToAdd)!.toStringAsFixed(1)} L',
              highlight: true,
            ),
            
            _buildResultRow(
              '割水後の合計容量:',
              '${(selectedFinalVolume ?? finalVolume).toStringAsFixed(1)} L'
            ),
            
            if (finalMeasurement != null || selectedFinalMeasurement != null)
              _buildResultRow(
                '割水後の検尺:',
                '${(selectedFinalMeasurement ?? finalMeasurement)!.toStringAsFixed(1)} mm'
              ),
              
            if (actualAlcohol != null)
              _buildResultRow(
                '実際のアルコール度数:',
                '${actualAlcohol?.toStringAsFixed(2) ?? "-"} %',
warning: actualAlcohol != null && (actualAlcohol! - targetAlcohol).abs() > 0.1,
              ),
            
            // 近似値選択（データに正確な値がない場合）
            if (!isExactMatch && approximations.isNotEmpty) ...[
              Divider(),
              const Text(
                '近似値を選択:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '計算された合計容量（${finalVolume.toStringAsFixed(1)} L）に最も近い利用可能な値を選択できます。これにより、実際の割水量とアルコール度数が調整されます。',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              SizedBox(height: 12),
              
              // 近似値チップ
              if (onApproximationSelected != null)
                ApproximationChips(
                  approximations: approximations,
                  selectedValue: selectedFinalVolume,
                  selectByCapacity: true,
                  onSelected: onApproximationSelected!,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool highlight = false, bool warning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: highlight ? 20 : 16,
              color: warning 
                ? Colors.orange[700]
                : highlight 
                  ? Colors.blue[700]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}