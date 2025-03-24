import 'tank_data_service.dart';

/// 近似値計算のためのサービスクラス
/// 検尺と容量の近似値処理を扱う
class ApproximationService {
  final TankDataService _tankDataService;
  
  ApproximationService(this._tankDataService);
  
  /// 指定された容量に対する近似値ペア（容量と検尺値）を取得
  /// targetVolume: 目標とする容量
  /// maxResults: 返す結果の最大数
  /// 容量と検尺のペアのリストを返す
  Future<List<Map<String, double>>> findNearestVolumePairs(
      String tankNumber, double targetVolume, {int maxResults = 5}) async {
    final results = await _tankDataService.findNearestCapacityMeasurementPairs(
        tankNumber, targetVolume);
    
    // 必要に応じて結果の数を制限
    if (results.length > maxResults) {
      // 目標値との差分でソート
      results.sort((a, b) => 
        (a['capacity']! - targetVolume).abs().compareTo(
        (b['capacity']! - targetVolume).abs()));
      
      return results.sublist(0, maxResults);
    }
    
    return results;
  }
  
  /// 特定の検尺値に対する近似容量を見つける
  Future<List<Map<String, double>>> findApproximateVolumesByMeasurement(
      String tankNumber, double measurement) async {
    final tank = await _tankDataService.getTankData(tankNumber);
    if (tank == null || tank.measurementData.isEmpty) return [];
    
    // 検尺値でソート
    tank.measurementData.sort((a, b) => a.measurement.compareTo(b.measurement));
    
    // 目標値に最も近いデータポイントを見つける
    int closestIndex = 0;
    double minDiff = double.infinity;
    
    for (int i = 0; i < tank.measurementData.length; i++) {
      double diff = (tank.measurementData[i].measurement - measurement).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestIndex = i;
      }
    }
    
    // 近傍の値を取得（前後2つずつ）
    List<Map<String, double>> results = [];
    for (int offset = -2; offset <= 2; offset++) {
      int index = closestIndex + offset;
      if (index >= 0 && index < tank.measurementData.length) {
        results.add({
          'capacity': tank.measurementData[index].capacity,
          'measurement': tank.measurementData[index].measurement,
        });
      }
    }
    
    return results;
  }
  
  /// 特定の容量に対する近似検尺値を見つける
  Future<List<Map<String, double>>> findApproximateMeasurementsByVolume(
      String tankNumber, double capacity) async {
    final tank = await _tankDataService.getTankData(tankNumber);
    if (tank == null || tank.measurementData.isEmpty) return [];
    
    // 容量でソート
    tank.measurementData.sort((a, b) => a.capacity.compareTo(b.capacity));
    
    // 目標値に最も近いデータポイントを見つける
    int closestIndex = 0;
    double minDiff = double.infinity;
    
    for (int i = 0; i < tank.measurementData.length; i++) {
      double diff = (tank.measurementData[i].capacity - capacity).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestIndex = i;
      }
    }
    
    // 近傍の値を取得（前後2つずつ）
    List<Map<String, double>> results = [];
    for (int offset = -2; offset <= 2; offset++) {
      int index = closestIndex + offset;
      if (index >= 0 && index < tank.measurementData.length) {
        results.add({
          'capacity': tank.measurementData[index].capacity,
          'measurement': tank.measurementData[index].measurement,
        });
      }
    }
    
    return results;
  }
  
  /// 上下2つずつの近似値を取得する汎用関数
  Future<List<Map<String, double>>> getApproximations(
      String tankNumber, double targetValue, bool byMeasurement) async {
    return byMeasurement 
        ? await findApproximateVolumesByMeasurement(tankNumber, targetValue)
        : await findApproximateMeasurementsByVolume(tankNumber, targetValue);
  }
}