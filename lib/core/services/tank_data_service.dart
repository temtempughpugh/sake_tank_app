import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/tank.dart';
import '../../models/measurement_result.dart';

/// タンクデータを管理する中核サービス
/// アセットからのCSVデータ読み込み、タンク情報の検索、
/// 検尺・容量計算などの機能を提供
class TankDataService {
  // タンクデータのキャッシュ
  List<Tank>? _allTankData;
  
  /// タンク番号をクリーニング（標準形式に変換）
  String cleanTankNumber(String tankNumber) {
    if (tankNumber == "仕込水タンク") return tankNumber;
    
    // No.またはN0.というプレフィックスを削除し、空白をトリム
    return tankNumber.replaceAll(RegExp('No\\.|N0\\.', caseSensitive: false), '').trim();
  }
  
  /// 全タンクデータの読み込み
  Future<List<Tank>> loadAllTankData() async {
    // キャッシュがあれば返す
    if (_allTankData != null) {
      return _allTankData!;
    }
    
    try {
      // アセットからCSVファイルをバイトとして読み込んでUTF-8でデコード
      final ByteData byteData = await rootBundle.load('assets/tank_quick_reference.csv');
      final List<int> bytes = byteData.buffer.asUint8List();
      final String csvString = utf8.decode(bytes);
      
      // 結果を格納するリスト
      List<Tank> tankData = [];
      
      // CSVを行ごとにパース
      final List<String> lines = csvString.split('\n');
      
      // ヘッダー行をスキップ
      if (lines.isEmpty) {
        print('CSVファイルに内容がありません');
        return [];
      }
      
      // 各行を処理
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        final List<String> values = line.split(',');
        
        // 横長CSVから複数のタンクデータを抽出（3列ごとに1つのタンクデータ）
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
              final measurementData = MeasurementData(
                capacity: capacity,
                measurement: measurement
              );
              
              // 既存のタンクを探す
              final existingTankIndex = tankData.indexWhere(
                (t) => t.tankNumber == tankNumber
              );
              
              if (existingTankIndex >= 0) {
                // 既存タンクに計測データを追加
                tankData[existingTankIndex].measurementData.add(measurementData);
              } else {
                // 新しいタンクを作成
                final tank = Tank(
                  tankNumber: tankNumber,
                  measurementData: [measurementData]
                );
                tankData.add(tank);
              }
            }
          } catch (e) {
            print('データセットのパースに失敗: $e');
          }
        }
      }
      
      // 各タンクのデータを検尺値でソート
      for (var tank in tankData) {
        tank.measurementData.sort((a, b) => a.measurement.compareTo(b.measurement));
      }
      
      // キャッシュに保存
      _allTankData = tankData;
      
      return tankData;
    } catch (e) {
      print('CSVデータ読み込みエラー: $e');
      return [];
    }
  }
  
  /// 利用可能なタンク番号一覧を取得
  Future<List<String>> getAvailableTankNumbers() async {
    final allData = await loadAllTankData();
    return allData.map((tank) => tank.tankNumber).toList();
  }
  
  /// 特定のタンク番号のデータを取得
  Future<Tank?> getTankData(String tankNumber) async {
    final allData = await loadAllTankData();
    try {
      return allData.firstWhere((tank) => tank.tankNumber == tankNumber);
    } catch (e) {
      print('タンク $tankNumber のデータが見つかりません');
      return null;
    }
  }
  
  /// 特定のタンクの最大容量を取得（検尺が0の時の容量）
  Future<double?> getMaxCapacity(String tankNumber) async {
    final tank = await getTankData(tankNumber);
    if (tank == null || tank.measurementData.isEmpty) return null;
    
    // 検尺値でソート（昇順）
    tank.measurementData.sort((a, b) => a.measurement.compareTo(b.measurement));
    
    // 検尺値が0のデータを探す
    for (var data in tank.measurementData) {
      if (data.measurement == 0) {
        return data.capacity;
      }
    }
    
    // 検尺値が0のデータがない場合、最小検尺値のデータを返す
    return tank.measurementData.first.capacity;
  }
  
  /// 特定のタンクの最大検尺値を取得
  Future<double?> getMaxMeasurement(String tankNumber) async {
    final tank = await getTankData(tankNumber);
    if (tank == null || tank.measurementData.isEmpty) return null;
    
    // 検尺値でソート（降順）
    tank.measurementData.sort((a, b) => b.measurement.compareTo(a.measurement));
    
    return tank.measurementData.first.measurement;
  }
  
  /// 検尺から容量を計算
  Future<MeasurementResult?> calculateCapacity(String tankNumber, double measurement) async {
    final tank = await getTankData(tankNumber);
    if (tank == null || tank.measurementData.isEmpty) return null;
    
    // データを検尺値でソート
    tank.measurementData.sort((a, b) => a.measurement.compareTo(b.measurement));
    
    // 最大検尺値（タンクが空の時）
    final maxMeasurement = tank.measurementData.last.measurement;
    
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
        capacity: tank.measurementData.first.capacity, // 最大容量
        isExactMatch: false,
        isOverCapacity: true, // 容量オーバー
      );
    }
    
    // 完全一致するデータを探す
    for (var data in tank.measurementData) {
      if (data.measurement == measurement) {
        return MeasurementResult(
          measurement: data.measurement,
          capacity: data.capacity,
          isExactMatch: true,
        );
      }
    }
    
    // 線形補間のために前後のデータポイントを見つける
    MeasurementData? lowerPoint;
    MeasurementData? upperPoint;
    
    for (int i = 0; i < tank.measurementData.length - 1; i++) {
      if (tank.measurementData[i].measurement <= measurement && 
          measurement <= tank.measurementData[i + 1].measurement) {
        lowerPoint = tank.measurementData[i];
        upperPoint = tank.measurementData[i + 1];
        break;
      }
    }
    
    if (lowerPoint == null || upperPoint == null) {
      // 補間できないが、範囲内の場合
      if (measurement <= tank.measurementData.first.measurement) {
        return MeasurementResult(
          measurement: measurement,
          capacity: tank.measurementData.first.capacity,
          isExactMatch: false,
        );
      }
      return null;
    }
    
    // 線形補間で容量を計算
    final ratio = (measurement - lowerPoint.measurement) / 
                 (upperPoint.measurement - lowerPoint.measurement);
    final calculatedCapacity = lowerPoint.capacity + 
                              ratio * (upperPoint.capacity - lowerPoint.capacity);
    
    return MeasurementResult(
      measurement: measurement,
      capacity: calculatedCapacity,
      isExactMatch: false,
    );
  }
  
  /// 容量から検尺を計算
  Future<MeasurementResult?> calculateMeasurement(String tankNumber, double targetCapacity) async {
    final tank = await getTankData(tankNumber);
    if (tank == null || tank.measurementData.isEmpty) return null;
    
    // データを容量でソート
    tank.measurementData.sort((a, b) => a.capacity.compareTo(b.capacity));
    
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
    if (targetCapacity < tank.measurementData.first.capacity) {
      return MeasurementResult(
        measurement: tank.measurementData.last.measurement, // 最大検尺値（タンクが空に近い状態）
        capacity: tank.measurementData.first.capacity,
        isExactMatch: false,
        isOverLimit: true, // 検尺上限オーバー
      );
    }
    
    // 完全一致するデータを探す
    for (var data in tank.measurementData) {
      if (data.capacity == targetCapacity) {
        return MeasurementResult(
          measurement: data.measurement,
          capacity: data.capacity,
          isExactMatch: true,
        );
      }
    }
    
    // 容量に最も近い2つのデータポイントを見つける
    MeasurementData? lowerPoint;
    MeasurementData? upperPoint;
    
    for (int i = 0; i < tank.measurementData.length - 1; i++) {
      if (tank.measurementData[i].capacity <= targetCapacity && 
          targetCapacity <= tank.measurementData[i + 1].capacity) {
        lowerPoint = tank.measurementData[i];
        upperPoint = tank.measurementData[i + 1];
        break;
      }
    }
    
    if (lowerPoint == null || upperPoint == null) return null;
    
    // 線形補間で検尺値を計算
    final ratio = (targetCapacity - lowerPoint.capacity) / 
                 (upperPoint.capacity - lowerPoint.capacity);
    final calculatedMeasurement = lowerPoint.measurement + 
                                ratio * (upperPoint.measurement - lowerPoint.measurement);
    
    return MeasurementResult(
      measurement: calculatedMeasurement,
      capacity: targetCapacity,
      isExactMatch: false,
    );
  }
  
  /// 希望容量に最も近い利用可能な容量-検尺ペアを探す
  Future<List<Map<String, double>>> findNearestCapacityMeasurementPairs(
      String tankNumber, double targetCapacity) async {
    final tank = await getTankData(tankNumber);
    if (tank == null || tank.measurementData.isEmpty) return [];
    
    // 容量でソート
    tank.measurementData.sort((a, b) => a.capacity.compareTo(b.capacity));
    
    // 完全一致を確認
    bool hasExactMatch = tank.measurementData.any((data) => data.capacity == targetCapacity);
    
    // 結果リスト
    List<Map<String, double>> result = [];
    
    if (hasExactMatch) {
      // 完全一致がある場合、その値と前後の値を追加（最大3つ）
      MeasurementData? lowerData;
      MeasurementData? exactData;
      MeasurementData? upperData;
      
      for (int i = 0; i < tank.measurementData.length; i++) {
        if (tank.measurementData[i].capacity == targetCapacity) {
          exactData = tank.measurementData[i];
          
          // 一つ前の値を追加
          if (i > 0) {
            lowerData = tank.measurementData[i - 1];
          }
          // 一つ後の値を追加
          if (i < tank.measurementData.length - 1) {
            upperData = tank.measurementData[i + 1];
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
      MeasurementData? lowerData;
      MeasurementData? upperData;
      
      for (int i = 0; i < tank.measurementData.length - 1; i++) {
        if (tank.measurementData[i].capacity <= targetCapacity && 
            targetCapacity <= tank.measurementData[i + 1].capacity) {
          lowerData = tank.measurementData[i];
          upperData = tank.measurementData[i + 1];
          break;
        }
      }
      
      // 全てのデータがtargetCapacityより小さい場合
      if (upperData == null && tank.measurementData.isNotEmpty) {
        lowerData = tank.measurementData.last;
      }
      
      // 全てのデータがtargetCapacityより大きい場合
      if (lowerData == null && tank.measurementData.isNotEmpty) {
        upperData = tank.measurementData.first;
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