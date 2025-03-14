import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dilution_plan.dart';

class DilutionHistoryService {
  final String _historyStorageKey = 'dilution_history';
  
  // 履歴に追加（割水計画が完了した時に呼び出す）
  Future<void> addToHistory(DilutionPlan plan) async {
    if (!plan.isCompleted) {
      throw Exception('完了していない計画は履歴に追加できません');
    }
    
    try {
      var history = await getHistory();
      
      // 同じIDの計画がすでに履歴にある場合は更新
      final existingIndex = history.indexWhere((p) => p.id == plan.id);
      if (existingIndex >= 0) {
        history[existingIndex] = plan;
      } else {
        history.add(plan);
      }
      
      // 最大100件に制限
      if (history.length > 100) {
        history.sort((a, b) => b.completionDate!.compareTo(a.completionDate!));
        history = history.take(100).toList();
      }
      
      await _saveHistory(history);
    } catch (e) {
      print('履歴の追加に失敗しました: $e');
      throw Exception('履歴の追加に失敗しました');
    }
  }
  
  // 履歴を取得
  Future<List<DilutionPlan>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedHistoryJson = prefs.getStringList(_historyStorageKey) ?? [];
      
      return storedHistoryJson
          .map((jsonStr) => DilutionPlan.fromJson(json.decode(jsonStr)))
          .toList();
    } catch (e) {
      print('履歴の取得に失敗しました: $e');
      return [];
    }
  }
  
  // タンク別の履歴を取得
  Future<List<DilutionPlan>> getHistoryForTank(String tankNumber) async {
    final history = await getHistory();
    return history
        .where((plan) => plan.tankNumber == tankNumber)
        .toList();
  }
  
  // 日付範囲での履歴取得
  Future<List<DilutionPlan>> getHistoryByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final history = await getHistory();
    return history
        .where((plan) => 
            plan.completionDate != null &&
            plan.completionDate!.isAfter(startDate) &&
            plan.completionDate!.isBefore(endDate.add(Duration(days: 1))))
        .toList();
  }
  
  // 特定の銘柄での履歴取得
  Future<List<DilutionPlan>> getHistoryBySakeName(String sakeName) async {
    if (sakeName.isEmpty) return [];
    
    final history = await getHistory();
    return history
        .where((plan) => 
            plan.sakeName.toLowerCase().contains(sakeName.toLowerCase()))
        .toList();
  }
  
  // 履歴をCSV形式で出力
  Future<String> exportHistoryToCsv() async {
    final history = await getHistory();
    
    // ヘッダー行
    final csvRows = [
      '計画ID,タンク番号,銘柄,担当者,初期容量(L),初期アルコール度(%),目標アルコール度(%),実際のアルコール度(%),追加水量(L),最終容量(L),計画日,完了日'
    ];
    
    // データ行
    for (var plan in history) {
      csvRows.add(
        '${plan.id},${plan.tankNumber},${_escapeCsvField(plan.sakeName)},${_escapeCsvField(plan.personInCharge)},'
        '${plan.initialVolume},${plan.initialAlcoholPercentage},${plan.targetAlcoholPercentage},'
        '${plan.targetAlcoholPercentage},${plan.waterToAdd},${plan.finalVolume},'
        '${_formatDateForCsv(plan.plannedDate)},${plan.completionDate != null ? _formatDateForCsv(plan.completionDate!) : ""}'
      );
    }
    
    return csvRows.join('\n');
  }
  
  // 履歴を保存（内部用）
  Future<void> _saveHistory(List<DilutionPlan> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final historyJson = history
          .map((plan) => json.encode(plan.toJson()))
          .toList();
      
      await prefs.setStringList(_historyStorageKey, historyJson);
    } catch (e) {
      print('履歴の保存に失敗しました: $e');
      throw Exception('履歴の保存に失敗しました');
    }
  }
  
  // CSV用の文字列エスケープ
  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
  
  // CSV用の日付フォーマット
  String _formatDateForCsv(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  // 履歴をクリア（主に開発用）
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyStorageKey);
    } catch (e) {
      print('履歴のクリアに失敗しました: $e');
      throw Exception('履歴のクリアに失敗しました');
    }
  }
}