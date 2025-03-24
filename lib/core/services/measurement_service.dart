import '/models/measurement_result.dart';
import '/models/measurement_data.dart';
import 'tank_data_service.dart';

class MeasurementService {
  final TankDataService _tankDataService;
  
  MeasurementService(this._tankDataService);
  
  // 検尺から容量を計算
  Future<MeasurementResult?> calculateCapacity(String tankNumber, double measurement) async {
    final tankData = await _tankDataService.getTankData(tankNumber);
    if (tankData == null || tankData.measurementData.isEmpty) return null;
    
    // データを検尺値でソート
    tankData.measurementData.sort((a, b) => a.measurement.compareTo(b.measurement));
    
    // 最大検尺値（タンクが空の時）
    final maxMeasurement = tankData.measurementData.last.measurement;
    
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
        capacity: tankData.measurementData.first.capacity, // 最大容量
        isExactMatch: false,
        isOverCapacity: true, // 容量オーバー
      );
    }
    
    // 完全一致するデータを探す
    for (var data in tankData.measurementData) {
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
    
    for (int i = 0; i < tankData.measurementData.length - 1; i++) {
      if (tankData.measurementData[i].measurement <= measurement && measurement <= tankData.measurementData[i + 1].measurement) {
        lowerPoint = tankData.measurementData[i];
        upperPoint = tankData.measurementData[i + 1];
        break;
      }
    }
    
    if (lowerPoint == null || upperPoint == null) {
      // 補間できないが、範囲内の場合
      if (measurement <= tankData.measurementData.first.measurement) {
        return MeasurementResult(
          measurement: measurement,
          capacity: tankData.measurementData.first.capacity,
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
  
  // 容量から検尺を計算
  Future<MeasurementResult?> calculateMeasurement(String tankNumber, double targetCapacity) async {
    final tankData = await _tankDataService.getTankData(tankNumber);
    if (tankData == null || tankData.measurementData.isEmpty) return null;
    
    // データを容量でソート
    tankData.measurementData.sort((a, b) => a.capacity.compareTo(b.capacity));
    
    // 最大容量を取得
    final maxCapacity = await _tankDataService.getMaxCapacity(tankNumber);
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
    if (targetCapacity < tankData.measurementData.first.capacity) {
      return MeasurementResult(
        measurement: tankData.measurementData.last.measurement, // 最大検尺値（タンクが空に近い状態）
        capacity: tankData.measurementData.first.capacity,
        isExactMatch: false,
        isOverLimit: true, // 検尺上限オーバー
      );
    }
    
    // 完全一致するデータを探す
    for (var data in tankData.measurementData) {
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
    
    for (int i = 0; i < tankData.measurementData.length - 1; i++) {
      if (tankData.measurementData[i].capacity <= targetCapacity && targetCapacity <= tankData.measurementData[i + 1].capacity) {
        lowerPoint = tankData.measurementData[i];
        upperPoint = tankData.measurementData[i + 1];
        break;
      }
    }
    
    if (lowerPoint == null || upperPoint == null) return null;
    
    // 線形補間で検尺値を計算
    final ratio = (targetCapacity - lowerPoint.capacity) / (upperPoint.capacity - lowerPoint.capacity);
    final calculatedMeasurement = lowerPoint.measurement + ratio * (upperPoint.measurement - lowerPoint.measurement);
    
    return MeasurementResult(
      measurement: calculatedMeasurement,
      capacity: targetCapacity,
      isExactMatch: false,
    );
  }
}