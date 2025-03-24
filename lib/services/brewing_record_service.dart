// lib/services/brewing_record_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/brewing_record.dart';
import '../models/approximation_pair.dart';

class BrewingRecordService {
  final String _storageKey = 'brewing_record_data';
  final CsvService _csvService;
  
  // 依存性注入パターンを使用
  BrewingRecordService({CsvService? csvService}) 
    : _csvService = csvService ?? CsvService();
  
  // 醸造記録を保存
  Future<void> saveBrewingRecord(BrewingRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedDataJson = prefs.getStringList(_storageKey) ?? [];
      
      List<BrewingRecord> storedData = storedDataJson
          .map((jsonStr) => BrewingRecord.fromJson(json.decode(jsonStr)))
          .toList();
      
      // 既存データの更新または新規追加
      final existingIndex = storedData.indexWhere((item) => item.id == record.id);
      if (existingIndex >= 0) {
        storedData[existingIndex] = record;
      } else {
        storedData.add(record);
      }
      
      // 日付順にソート（新しい順）
      storedData.sort((a, b) => b.date.compareTo(a.date));
      
      // JSONに変換して保存
      final updatedJson = storedData
          .map((item) => json.encode(item.toJson()))
          .toList();
      
      await prefs.setStringList(_storageKey, updatedJson);
    } catch (e) {
      print('醸造記録の保存に失敗しました: $e');
      throw Exception('保存中にエラーが発生しました: $e');
    }
  }
  
  // 瓶詰め情報IDに関連する醸造記録を取得
  Future<List<BrewingRecord>> getRecordsForBottling(String bottlingInfoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedDataJson = prefs.getStringList(_storageKey) ?? [];
      
      List<BrewingRecord> storedData = storedDataJson
          .map((jsonStr) => BrewingRecord.fromJson(json.decode(jsonStr)))
          .toList();
      
      // 瓶詰め情報IDでフィルタリング
      final records = storedData
          .where((record) => record.bottlingInfoId == bottlingInfoId)
          .toList();
      
      // 工程タイプでソート
      records.sort((a, b) => a.processType.index.compareTo(b.processType.index));
      
      return records;
    } catch (e) {
      print('醸造記録の取得に失敗しました: $e');
      return [];
    }
  }
  
  // 割水量計算
  double calculateDilutionAmount({
    required double originalVolume, 
    required double originalAlcohol, 
    required double targetAlcohol
  }) {
    final dilutedVolume = calculateFinalVolume(
      originalVolume: originalVolume,
      originalAlcohol: originalAlcohol,
      targetAlcohol: targetAlcohol
    );
    return dilutedVolume - originalVolume;
  }
  
  // 割水後の総容量計算
  double calculateFinalVolume({
    required double originalVolume, 
    required double originalAlcohol, 
    required double targetAlcohol
  }) {
    // アルコール量は保存される
    // 初期容量 × 初期アルコール度数 = 最終容量 × 目標アルコール度数
    return originalVolume * (originalAlcohol / targetAlcohol);
  }
  
  // 割水前酒量計算
  double calculateOriginalLiquorVolume({
    required double dilutedVolume,
    required double originalAlcohol,
    required double dilutedAlcohol
  }) {
    // 逆の計算: 最終容量 × 目標アルコール度数 = 初期容量 × 初期アルコール度数
    return dilutedVolume * (dilutedAlcohol / originalAlcohol);
  }
  
  // 実際のアルコール度数計算
  double calculateActualAlcohol({
    required double originalVolume, 
    required double originalAlcohol,
    required double dilutionAmount
  }) {
    double pureAlcohol = originalVolume * originalAlcohol / 100;
    double totalVolume = originalVolume + dilutionAmount;
    return (pureAlcohol / totalVolume) * 100;
  }
  
  // 近似値取得
  Future<List<ApproximationPair>> findNearestVolumes(String tankNumber, double volume) async {
  try {
    final rawPairs = await _csvService.findNearestPairsForDilution(tankNumber, volume);
return rawPairs;    // ↑ returnを追加
  } catch (e) {
    print('近似値取得でエラーが発生しました: $e');
    return []; // 例外時は空リストを返す
  }
}
  
  // 近似値から最も近いものを選択
  ApproximationPair findClosestApproximation(List<ApproximationPair> approximations, double targetVolume) {
    if (approximations.isEmpty) {
      throw Exception('近似値リストが空です');
    }
    
    // 最も近い値を探す
    approximations.sort((a, b) => 
      (a.capacity - targetVolume).abs().compareTo((b.capacity - targetVolume).abs()));
    
    return approximations.first;
  }
}

// lib/services/csv_service.dart の改善
class CsvService {
  // 重要な部分のみを抜粋
  
  // より型安全な近似値を取得するためのメソッド
  Future<List<ApproximationPair>> findNearestPairsForDilution(String tankNumber, double targetVolume) async {
    final rawPairs = await _legacyFindNearestPairsForDilution(tankNumber, targetVolume);
    return rawPairs.map((map) => ApproximationPair.fromMap(map)).toList();
  }
  
  // 後方互換性のための元のメソッド
  Future<List<Map<String, double>>> _legacyFindNearestPairsForDilution(String tankNumber, double targetVolume) async {
    // 元の実装をそのまま残す...
    // ただし内部実装の詳細は隠蔽
  return [];
}
}