import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/brewing_record.dart';
import 'csv_service.dart';

class BrewingRecordService {
  final String _storageKey = 'brewing_record_data';
  final CsvService _csvService = CsvService();
  
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
      throw Exception('保存中にエラーが発生しました');
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
  double calculateDilutionAmount(
    double originalVolume, 
    double originalAlcohol, 
    double targetAlcohol
  ) {
    final dilutedVolume = originalVolume * (originalAlcohol / targetAlcohol);
    return dilutedVolume - originalVolume;
  }
  
  // 割水前酒量計算
  double calculateOriginalLiquorVolume(
    double dilutedVolume,
    double originalAlcohol,
    double dilutedAlcohol
  ) {
    return dilutedVolume * (dilutedAlcohol / originalAlcohol);
  }
  
  // 実際のアルコール度数計算
  double calculateActualAlcohol(
    double originalVolume, 
    double originalAlcohol,
    double dilutionAmount
  ) {
    double pureAlcohol = originalVolume * originalAlcohol / 100;
    double totalVolume = originalVolume + dilutionAmount;
    return (pureAlcohol / totalVolume) * 100;
  }
  
  // 近似値取得（CsvServiceの関数を活用）
  Future<List<Map<String, double>>> findNearestVolumes(
    String tankNumber, 
    double volume
  ) async {
    return await _csvService.findNearestPairsForDilution(tankNumber, volume);
  }
}