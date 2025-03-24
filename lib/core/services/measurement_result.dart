import '../../models/measurement_result.dart';
import 'tank_data_service.dart';

/// 検尺と容量の変換、計算を行うサービスクラス
class MeasurementService {
  final TankDataService _tankDataService;
  
  MeasurementService(this._tankDataService);
  
  /// 検尺値から容量を計算
  Future<MeasurementResult?> calculateCapacityFromMeasurement(
      String tankNumber, double measurement) async {
    return await _tankDataService.calculateCapacity(tankNumber, measurement);
  }
  
  /// 容量から検尺値を計算
  Future<MeasurementResult?> calculateMeasurementFromCapacity(
      String tankNumber, double capacity) async {
    return await _tankDataService.calculateMeasurement(tankNumber, capacity);
  }
  
  /// 割水計算
  /// 初期容量と初期アルコール度数から、目標アルコール度数に調整するための水量を計算
  DilutionCalcResult calculateDilution({
    required double initialVolume,
    required double initialAlcoholPercentage, 
    required double targetAlcoholPercentage,
  }) {
    // アルコール総量を保存原理
    // 初期アルコール総量 = 初期容量 * 初期アルコール度数
    // 最終アルコール総量 = 最終容量 * 最終アルコール度数
    // 保存原理より: 初期アルコール総量 = 最終アルコール総量
    // 初期容量 * 初期アルコール度数 = 最終容量 * 最終アルコール度数
    // 最終容量 = 初期容量 * (初期アルコール度数 / 最終アルコール度数)
    
    final double finalVolume = initialVolume * (initialAlcoholPercentage / targetAlcoholPercentage);
    final double waterToAdd = finalVolume - initialVolume;
    
    return DilutionCalcResult(
      initialVolume: initialVolume,
      initialAlcoholPercentage: initialAlcoholPercentage,
      targetAlcoholPercentage: targetAlcoholPercentage,
      waterToAdd: waterToAdd,
      finalVolume: finalVolume,
    );
  }
  
  /// 実際のアルコール度数計算
  /// 割水後の実際のアルコール度数を計算
  double calculateActualAlcohol({
    required double originalLiquorVolume,
    required double originalAlcoholPercentage,
    required double dilutionAmount,
  }) {
    // アルコール総量 = 元酒容量 * 元酒アルコール度数 / 100
    double alcoholAmount = originalLiquorVolume * originalAlcoholPercentage / 100;
    
    // 最終容量 = 元酒容量 + 割水量
    double finalVolume = originalLiquorVolume + dilutionAmount;
    
    // 実際のアルコール度数 = アルコール総量 / 最終容量 * 100
    return (alcoholAmount / finalVolume) * 100;
  }
  
  /// 割水前元酒量を計算
  /// 割水後の容量とアルコール度数から、元の酒量を計算
  double calculateOriginalLiquorVolume({
    required double dilutedVolume,
    required double originalAlcoholPercentage,
    required double dilutedAlcoholPercentage,
  }) {
    // 元酒量 = 割水後容量 * (割水後アルコール度数 / 元酒アルコール度数)
    return dilutedVolume * (dilutedAlcoholPercentage / originalAlcoholPercentage);
  }
  
  /// 最も近い容量-検尺ペアを取得
  Future<List<Map<String, double>>> findNearestCapacityMeasurementPairs(
      String tankNumber, double targetVolume) async {
    return await _tankDataService.findNearestCapacityMeasurementPairs(
        tankNumber, targetVolume);
  }
}

/// 割水計算結果クラス
class DilutionCalcResult {
  final double initialVolume;
  final double initialAlcoholPercentage;
  final double targetAlcoholPercentage;
  final double waterToAdd;
  final double finalVolume;
  
  DilutionCalcResult({
    required this.initialVolume,
    required this.initialAlcoholPercentage,
    required this.targetAlcoholPercentage,
    required this.waterToAdd,
    required this.finalVolume,
  });
}