// lib/core/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/dilution_plan.dart';
import '../../models/bottling_info.dart';

class StorageService {
  // キー定義
  static const String _dilutionPlansKey = 'dilution_plans';
  static const String _dilutionHistoryKey = 'dilution_history';
  static const String _bottlingInfoKey = 'bottling_info_data';
  static const String _lastTankKey = 'last_selected_tank';
  static const String _themeKey = 'app_theme';
  
  // 割水計画を保存
  Future<void> saveDilutionPlan(DilutionPlan plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPlansJson = prefs.getStringList(_dilutionPlansKey) ?? [];
      
      List<DilutionPlan> plans = storedPlansJson
          .map((jsonStr) => DilutionPlan.fromJson(json.decode(jsonStr)))
          .toList();
      
      // 既存の計画を更新または新規追加
      final existingIndex = plans.indexWhere((p) => p.id == plan.id);
      if (existingIndex >= 0) {
        plans[existingIndex] = plan;
      } else {
        plans.add(plan);
      }
      
      // JSONに変換して保存
      final updatedPlansJson = plans
          .map((plan) => json.encode(plan.toJson()))
          .toList();
      
      await prefs.setStringList(_dilutionPlansKey, updatedPlansJson);
    } catch (e) {
      print('割水計画の保存に失敗しました: $e');
      throw Exception('保存中にエラーが発生しました');
    }
  }
  
  // 全ての割水計画を取得
  Future<List<DilutionPlan>> getAllDilutionPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPlansJson = prefs.getStringList(_dilutionPlansKey) ?? [];
      
      return storedPlansJson
          .map((jsonStr) => DilutionPlan.fromJson(json.decode(jsonStr)))
          .toList();
    } catch (e) {
      print('割水計画の取得に失敗しました: $e');
      return [];
    }
  }
  
  // 特定タンクの割水計画を取得
  Future<List<DilutionPlan>> getPlansForTank(String tankNumber) async {
    final allPlans = await getAllDilutionPlans();
    return allPlans
        .where((plan) => plan.tankNumber == tankNumber)
        .toList();
  }
  
  // 割水計画を削除
  Future<void> deleteDilutionPlan(String planId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPlansJson = prefs.getStringList(_dilutionPlansKey) ?? [];
      
      List<DilutionPlan> plans = storedPlansJson
          .map((jsonStr) => DilutionPlan.fromJson(json.decode(jsonStr)))
          .toList();
      
      plans.removeWhere((p) => p.id == planId);
      
      // JSONに変換して保存
      final updatedPlansJson = plans
          .map((plan) => json.encode(plan.toJson()))
          .toList();
      
      await prefs.setStringList(_dilutionPlansKey, updatedPlansJson);
    } catch (e) {
      print('割水計画の削除に失敗しました: $e');
      throw Exception('削除中にエラーが発生しました');
    }
  }
  
  // 割水計画を完了済みとしてマーク
  Future<void> completeDilutionPlan(String planId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPlansJson = prefs.getStringList(_dilutionPlansKey) ?? [];
      
      List<DilutionPlan> plans = storedPlansJson
          .map((jsonStr) => DilutionPlan.fromJson(json.decode(jsonStr)))
          .toList();
      
      final index = plans.indexWhere((p) => p.id == planId);
      if (index >= 0) {
        final completedPlan = plans[index].copyWith(
          isCompleted: true,
          completionDate: DateTime.now(),
        );
        
        plans[index] = completedPlan;
        
        // JSONに変換して保存
        final updatedPlansJson = plans
            .map((plan) => json.encode(plan.toJson()))
            .toList();
        
        await prefs.setStringList(_dilutionPlansKey, updatedPlansJson);
        
        // 履歴にも追加
        await _addToDilutionHistory(completedPlan);
      } else {
        throw Exception('指定されたIDの計画が見つかりません');
      }
    } catch (e) {
      print('割水計画の完了処理に失敗しました: $e');
      throw Exception('完了処理中にエラーが発生しました');
    }
  }
  
  // 履歴に割水計画を追加
  Future<void> _addToDilutionHistory(DilutionPlan plan) async {
    if (!plan.isCompleted) {
      throw Exception('完了していない計画は履歴に追加できません');
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedHistoryJson = prefs.getStringList(_dilutionHistoryKey) ?? [];
      
      List<DilutionPlan> history = storedHistoryJson
          .map((jsonStr) => DilutionPlan.fromJson(json.decode(jsonStr)))
          .toList();
      
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
      
      // JSONに変換して保存
      final updatedHistoryJson = history
          .map((plan) => json.encode(plan.toJson()))
          .toList();
      
      await prefs.setStringList(_dilutionHistoryKey, updatedHistoryJson);
    } catch (e) {
      print('履歴の追加に失敗しました: $e');
      throw Exception('履歴の追加に失敗しました');
    }
  }
  
  // 割水履歴の取得
  Future<List<DilutionPlan>> getDilutionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedHistoryJson = prefs.getStringList(_dilutionHistoryKey) ?? [];
      
      return storedHistoryJson
          .map((jsonStr) => DilutionPlan.fromJson(json.decode(jsonStr)))
          .toList();
    } catch (e) {
      print('履歴の取得に失敗しました: $e');
      return [];
    }
  }
  
  // === 瓶詰め情報関連 ===
  
  // 瓶詰め情報を保存
  Future<void> saveBottlingInfo(BottlingInfo info) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedDataJson = prefs.getStringList(_bottlingInfoKey) ?? [];
      
      List<BottlingInfo> storedData = storedDataJson
          .map((jsonStr) => BottlingInfo.fromJson(json.decode(jsonStr)))
          .toList();
      
      // 既存データの更新または新規追加
      final existingIndex = storedData.indexWhere((item) => item.id == info.id);
      if (existingIndex >= 0) {
        storedData[existingIndex] = info;
      } else {
        storedData.add(info);
      }
      
      // 日付順にソート（新しい順）
      storedData.sort((a, b) => b.date.compareTo(a.date));
      
      // JSONに変換して保存
      final updatedJson = storedData
          .map((item) => json.encode(item.toJson()))
          .toList();
      
      await prefs.setStringList(_bottlingInfoKey, updatedJson);
    } catch (e) {
      print('瓶詰め情報の保存に失敗しました: $e');
      throw Exception('保存中にエラーが発生しました');
    }
  }
  
  // 全ての瓶詰め情報を取得
  Future<List<BottlingInfo>> getAllBottlingInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedDataJson = prefs.getStringList(_bottlingInfoKey) ?? [];
      
      List<BottlingInfo> storedData = storedDataJson
          .map((jsonStr) => BottlingInfo.fromJson(json.decode(jsonStr)))
          .toList();
      
      // 日付順にソート（新しい順）
      storedData.sort((a, b) => b.date.compareTo(a.date));
      
      return storedData;
    } catch (e) {
      print('瓶詰め情報の取得に失敗しました: $e');
      return [];
    }
  }
  
  // IDで瓶詰め情報を取得
  Future<BottlingInfo?> getBottlingInfo(String id) async {
    try {
      final allData = await getAllBottlingInfo();
      return allData.firstWhere((item) => item.id == id);
    } catch (e) {
      print('瓶詰め情報の取得に失敗しました: $e');
      return null;
    }
  }
  
  // 瓶詰め情報を削除
  Future<bool> deleteBottlingInfo(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedDataJson = prefs.getStringList(_bottlingInfoKey) ?? [];
      
      List<BottlingInfo> storedData = storedDataJson
          .map((jsonStr) => BottlingInfo.fromJson(json.decode(jsonStr)))
          .toList();
      
      storedData.removeWhere((item) => item.id == id);
      
      final updatedJson = storedData
          .map((item) => json.encode(item.toJson()))
          .toList();
      
      await prefs.setStringList(_bottlingInfoKey, updatedJson);
      return true;
    } catch (e) {
      print('瓶詰め情報の削除に失敗しました: $e');
      return false;
    }
  }
  
  // === 設定関連 ===
  
  // 最後に選択したタンクを保存
  Future<void> saveLastSelectedTank(String tankNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastTankKey, tankNumber);
  }
  
  // 最後に選択したタンクを読み込み
  Future<String?> getLastSelectedTank() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastTankKey);
  }
  
  // テーマ設定を保存（0: ライト、1: ダーク、2: システム設定）
  Future<void> saveThemeSetting(int themeSetting) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, themeSetting);
  }
  
  // テーマ設定を読み込み
  Future<int> getThemeSetting() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_themeKey) ?? 2; // デフォルト: システム設定
  }
}