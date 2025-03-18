import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/tank_data.dart';
import '../models/measurement_result.dart';

class CsvService {
  String _cleanTankNumber(String tankNumber) {
  if (tankNumber == "仕込水タンク") return tankNumber;
  
  // グループ化して正しい正規表現パターンを使用
String cleaned = tankNumber.replaceAll(RegExp('No\\.|N0\\.', caseSensitive: false), '').trim();
  
  return cleaned;
}
  
  // 横長CSVを読み込むための改良版パーサー - 元のコードをそのまま維持
  Future<List<TankData>> loadTankData() async {
    try {
      // アセットからCSVファイルをバイトとして読み込んでUTF-8でデコード
      final ByteData byteData = await rootBundle.load('assets/tank_quick_reference.csv');
      final List<int> bytes = byteData.buffer.asUint8List();
      final String csvString = utf8.decode(bytes);
      
      // 結果を格納するリスト
      List<TankData> allTankData = [];
      
      // CSVを行ごとにパース
      final List<String> lines = csvString.split('\n');
      
      // ヘッダー行を別途取得（デバッグ用）
      if (lines.isEmpty) {
        print('CSVファイルに内容がありません');
        return [];
      }
      
      final List<String> headers = lines[0].split(',');
      
      // 各行を処理
      for (int i = 1; i < lines.length; i++) { // ヘッダー行をスキップ
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        final List<String> values = line.split(',');
        
        // 横長CSVから複数のタンクデータを抽出
        // 3列ごとに1つのタンクデータとして処理
        for (int col = 0; col < values.length - 2; col += 3) {
          if (col + 2 >= values.length) break; // 不完全なセットをスキップ
          
          // 値が空でないかチェック
          if (values[col].trim().isEmpty) continue;
          
          try {
            // タンク番号、容量、検尺を抽出
            String tankNumber = values[col].trim();
            
            // 数値変換を安全に行う
            double capacity = 0.0;
            double measurement = 0.0;
            
            try {
              if (values[col + 1].trim().isNotEmpty) {
                capacity = double.parse(values[col + 1].trim());
              }
            } catch (e) {
              print('容量のパースに失敗: ${values[col + 1]} - $e');
            }
            
            try {
              if (values[col + 2].trim().isNotEmpty) {
                measurement = double.parse(values[col + 2].trim());
              }
            } catch (e) {
              print('検尺のパースに失敗: ${values[col + 2]} - $e');
            }
            
            // タンクデータオブジェクトを作成して追加
            if (tankNumber.isNotEmpty) {
              final tankData = TankData(
                tankNumber: tankNumber,
                capacity: capacity,
                measurement: measurement,
              );
              allTankData.add(tankData);
            }
          } catch (e) {
            print('データセットのパースに失敗: $e');
          }
        }
      }
      
      return allTankData;
    } catch (e) {
      print('CSVデータ読み込みエラー: $e');
      return [];
    }
  }
  
  // 利用可能なタンク番号の一覧を取得 - 元のコードを維持
  Future<List<String>> getAvailableTankNumbers() async {
    final allData = await loadTankData();
    final Set<String> tankNumbers = {};
    
    for (var data in allData) {
      tankNumbers.add(data.tankNumber);
    }
    
    // 元のソートロジックを維持
    return tankNumbers.toList()..sort();
  }
  
  // 特定のタンク番号のデータを取得 - 元のコードを維持
  Future<List<TankData>> getDataForTank(String tankNumber) async {
    final allData = await loadTankData();
    return allData.where((data) => data.tankNumber == tankNumber).toList();
  }
  
  // 特定のタンクの最大容量を取得（検尺が0の時の容量）
  Future<double?> getMaxCapacity(String tankNumber) async {
    final tankData = await getDataForTank(tankNumber);
    if (tankData.isEmpty) return null;
    
    // 検尺値でソート
    tankData.sort((a, b) => a.measurement.compareTo(b.measurement));
    
    // 検尺値が0のデータを探す
    for (var data in tankData) {
      if (data.measurement == 0) {
        return data.capacity;
      }
    }
    
    // 検尺値が0のデータがない場合、最小検尺値のデータを返す
    return tankData.first.capacity;
  }
  
  // 特定のタンクの最大検尺値を取得
  Future<double?> getMaxMeasurement(String tankNumber) async {
    final tankData = await getDataForTank(tankNumber);
    if (tankData.isEmpty) return null;
    
    // 検尺値でソート
    tankData.sort((a, b) => b.measurement.compareTo(a.measurement));
    
    return tankData.first.measurement;
  }
  
  // 検尺から容量を計算（上限値判定を追加）
  Future<MeasurementResult?> calculateCapacity(String tankNumber, double measurement) async {
    final tankData = await getDataForTank(tankNumber);
    if (tankData.isEmpty) return null;
    
    // データを検尺値でソート
    tankData.sort((a, b) => a.measurement.compareTo(b.measurement));
    
    // 最大検尺値（タンクが空の時）
    final maxMeasurement = tankData.last.measurement;
    
    // 検尺値が最大値を超えている場合はエラー
    if (measurement > maxMeasurement) {
      return MeasurementResult(
        measurement: measurement,
        capacity: 0, // 容量なし
        isExactMatch: false,
        isOverLimit: true, // 検尺上限オーバー
      );
    }
    
    // 検尺値が0より小さい場合（あり得ないケース）
    if (measurement < 0) {
      return MeasurementResult(
        measurement: 0,
        capacity: tankData.first.capacity, // 最大容量
        isExactMatch: false,
        isOverCapacity: true, // 容量オーバー
      );
    }
    
    // 完全一致するデータを探す
    for (var data in tankData) {
      if (data.measurement == measurement) {
        return MeasurementResult(
          measurement: data.measurement,
          capacity: data.capacity,
          isExactMatch: true,
        );
      }
    }
    
    // 線形補間のために前後のデータポイントを見つける
    TankData? lowerPoint;
    TankData? upperPoint;
    
    for (int i = 0; i < tankData.length - 1; i++) {
      if (tankData[i].measurement <= measurement && measurement <= tankData[i + 1].measurement) {
        lowerPoint = tankData[i];
        upperPoint = tankData[i + 1];
        break;
      }
    }
    
    if (lowerPoint == null || upperPoint == null) {
      // 補間できないが、範囲内の場合
      if (measurement <= tankData.first.measurement) {
        return MeasurementResult(
          measurement: measurement,
          capacity: tankData.first.capacity,
          isExactMatch: false,
        );
      }
      return null;
    }
    
    // 線形補間で容量を計算
    final ratio = (measurement - lowerPoint.measurement) / (upperPoint.measurement - lowerPoint.measurement);
    final calculatedCapacity = lowerPoint.capacity + ratio * (upperPoint.capacity - lowerPoint.capacity);
    
    return MeasurementResult(
      measurement: measurement,
      capacity: calculatedCapacity,
      isExactMatch: false,
    );
  }
  
  // 容量から検尺を計算（より少ない容量になる検尺値を選択）
  Future<MeasurementResult?> calculateMeasurement(String tankNumber, double targetCapacity) async {
    final tankData = await getDataForTank(tankNumber);
    if (tankData.isEmpty) return null;
    
    // データを容量でソート
    tankData.sort((a, b) => a.capacity.compareTo(b.capacity));
    
    // 最大容量を取得（検尺が0の時の容量）
    final maxCapacity = await getMaxCapacity(tankNumber);
    if (maxCapacity == null) return null;
    
    // 容量が最大値を超えている場合
    if (targetCapacity > maxCapacity) {
      return MeasurementResult(
        measurement: 0, // 検尺0（満タン）
        capacity: maxCapacity,
        isExactMatch: false,
        isOverCapacity: true, // 容量オーバー
      );
    }
    
    // 下限チェック（容量が最小値より小さい場合）
    if (targetCapacity < tankData.first.capacity) {
      return MeasurementResult(
        measurement: tankData.last.measurement, // 最大検尺値（タンクが空に近い状態）
        capacity: tankData.first.capacity,
        isExactMatch: false,
        isOverLimit: true, // 検尺上限オーバー
      );
    }
    
    // 完全一致するデータを探す
    for (var data in tankData) {
      if (data.capacity == targetCapacity) {
        return MeasurementResult(
          measurement: data.measurement,
          capacity: data.capacity,
          isExactMatch: true,
        );
      }
    }
    
    // 容量に最も近い2つのデータポイントを見つける
    TankData? lowerPoint;
    TankData? upperPoint;
    
    for (int i = 0; i < tankData.length - 1; i++) {
      if (tankData[i].capacity <= targetCapacity && targetCapacity <= tankData[i + 1].capacity) {
        lowerPoint = tankData[i];
        upperPoint = tankData[i + 1];
        break;
      }
    }
    
    if (lowerPoint == null || upperPoint == null) return null;
    
    // ユーザーの要望に従い、容量が少なくなる方（検尺値が大きい方）を選択
    return MeasurementResult(
      measurement: upperPoint.measurement,
      capacity: upperPoint.capacity,
      isExactMatch: false,
    );
  }
  
  // 計算されたDilutionResultを元に最適な近似値を取得
  Future<List<Map<String, double>>> findNearestPairsForDilution(String tankNumber, double targetVolume) async {
    final tankData = await getDataForTank(tankNumber);
    if (tankData.isEmpty) return [];
    
    // 容量でソート
    tankData.sort((a, b) => a.capacity.compareTo(b.capacity));
    
    // 完全一致を確認
    bool hasExactMatch = tankData.any((data) => data.capacity == targetVolume);
    
    // 結果リスト
    List<Map<String, double>> result = [];
    
    if (hasExactMatch) {
      // 完全一致がある場合、その値と前後の値を追加（最大3つ）
      TankData? lowerData;
      TankData? exactData;
      TankData? upperData;
      
      for (int i = 0; i < tankData.length; i++) {
        if (tankData[i].capacity == targetVolume) {
          exactData = tankData[i];
          
          // 一つ前の値を追加
          if (i > 0) {
            lowerData = tankData[i - 1];
          }
          // 一つ後の値を追加
          if (i < tankData.length - 1) {
            upperData = tankData[i + 1];
          }
          break;
        }
      }
      
      if (lowerData != null) {
        result.add({
          'capacity': lowerData.capacity,
          'measurement': lowerData.measurement
        });
      }
      
      if (exactData != null) {
        result.add({
          'capacity': exactData.capacity,
          'measurement': exactData.measurement
        });
      }
      
      if (upperData != null) {
        result.add({
          'capacity': upperData.capacity,
          'measurement': upperData.measurement
        });
      }
    } else {
      // 完全一致がない場合、最も近い上下の値を追加（最大2つ）
      TankData? lowerData;
      TankData? upperData;
      
      for (int i = 0; i < tankData.length; i++) {
        if (tankData[i].capacity > targetVolume) {
          if (i > 0) {
            lowerData = tankData[i - 1];
          }
          upperData = tankData[i];
          break;
        }
      }
      
      // 全てのデータがtargetVolumeより小さい場合
      if (upperData == null && tankData.isNotEmpty) {
        lowerData = tankData.last;
      }
      
      if (lowerData != null) {
        result.add({
          'capacity': lowerData.capacity,
          'measurement': lowerData.measurement
        });
      }
      
      if (upperData != null) {
        result.add({
          'capacity': upperData.capacity,
          'measurement': upperData.measurement
        });
      }
    }
    
    return result;
  }
}