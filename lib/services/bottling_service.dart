import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bottling_info.dart';

class BottlingService {
  final String _storageKey = 'bottling_info_data';
  
  // 瓶詰め情報を保存
  Future<void> saveBottlingInfo(BottlingInfo info) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedDataJson = prefs.getStringList(_storageKey) ?? [];
      
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
      
      await prefs.setStringList(_storageKey, updatedJson);
    } catch (e) {
      print('瓶詰め情報の保存に失敗しました: $e');
      throw Exception('保存中にエラーが発生しました');
    }
  }
  
  // 全ての瓶詰め情報を取得
  Future<List<BottlingInfo>> getAllBottlingInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedDataJson = prefs.getStringList(_storageKey) ?? [];
      
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
      final storedDataJson = prefs.getStringList(_storageKey) ?? [];
      
      List<BottlingInfo> storedData = storedDataJson
          .map((jsonStr) => BottlingInfo.fromJson(json.decode(jsonStr)))
          .toList();
      
      storedData.removeWhere((item) => item.id == id);
      
      final updatedJson = storedData
          .map((item) => json.encode(item.toJson()))
          .toList();
      
      await prefs.setStringList(_storageKey, updatedJson);
      return true;
    } catch (e) {
      print('瓶詰め情報の削除に失敗しました: $e');
      return false;
    }
  }
  
  // 瓶詰め情報の実際アルコール度数を更新
  Future<void> updateActualAlcoholPercentage(
      String id, double actualAlcoholPercentage) async {
    try {
      final info = await getBottlingInfo(id);
      if (info != null) {
        final updatedInfo = info.copyWith(
          actualAlcoholPercentage: actualAlcoholPercentage,
        );
        await saveBottlingInfo(updatedInfo);
      }
    } catch (e) {
      print('瓶詰め情報の更新に失敗しました: $e');
      throw Exception('更新中にエラーが発生しました');
    }
  }
}