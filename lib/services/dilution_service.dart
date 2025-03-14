import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dilution_result.dart';
import '../models/dilution_plan.dart';
import '../models/measurement_result.dart';
import 'csv_service.dart';
import 'dilution_history_service.dart';

class DilutionService {
  final CsvService _csvService = CsvService();
  final DilutionHistoryService _historyService = DilutionHistoryService();
  final String _plansStorageKey = 'dilution_plans';

  // Calculate dilution
  // Calculate dilution
Future<DilutionResult> calculateDilution({
  required String tankNumber,
  required double initialVolume,
  required double initialAlcoholPercentage,
  required double targetAlcoholPercentage,
}) async {
  // Calculate water to add (alcohol mass remains constant)
  // Initial alcohol mass = initialVolume * initialAlcoholPercentage
  // Final alcohol mass = finalVolume * targetAlcoholPercentage
  // Since these are equal: initialVolume * initialAlcoholPercentage = finalVolume * targetAlcoholPercentage
  // Solving for finalVolume: finalVolume = initialVolume * (initialAlcoholPercentage / targetAlcoholPercentage)
  
  final double finalVolume = initialVolume * (initialAlcoholPercentage / targetAlcoholPercentage);
  final double waterToAdd = finalVolume - initialVolume;
  
  // Get the final measurement using the CSV service
  final measurementResult = await _csvService.calculateMeasurement(tankNumber, finalVolume);
  
  // Find the nearest available volume/measurement pairs
  final nearestPairs = await _csvService.findNearestPairsForDilution(tankNumber, finalVolume);
  
  // 互換性のために従来のリストも維持
  final nearestVolumes = nearestPairs.map((pair) => pair['capacity']!).toList();
  
  return DilutionResult(
    initialVolume: initialVolume,
    initialAlcoholPercentage: initialAlcoholPercentage,
    targetAlcoholPercentage: targetAlcoholPercentage,
    waterToAdd: waterToAdd,
    finalVolume: finalVolume,
    finalMeasurement: measurementResult?.measurement ?? 0,
    nearestAvailableVolumes: nearestVolumes,
    nearestAvailablePairs: nearestPairs,
    isExactMatch: measurementResult?.isExactMatch ?? false,
  );
}
  
  // Adjust calculation based on selected volume
Future<DilutionResult> adjustCalculation(DilutionResult originalResult, double selectedFinalVolume) async {
  // 選択された容量に対応する検尺値を探す
  double selectedMeasurement = 0;
  
  // 近似値ペアから選択した容量に対応する検尺値を見つける
  for (var pair in originalResult.nearestAvailablePairs) {
    if (pair['capacity'] == selectedFinalVolume) {
      selectedMeasurement = pair['measurement']!;
      break;
    }
  }
  
  // Recalculate water to add
  final adjustedWaterToAdd = selectedFinalVolume - originalResult.initialVolume;
  
  // Recalculate actual alcohol percentage after adjustment
  final adjustedAlcoholPercentage = 
    (originalResult.initialVolume * originalResult.initialAlcoholPercentage) / selectedFinalVolume;
  
  return DilutionResult(
    initialVolume: originalResult.initialVolume,
    initialAlcoholPercentage: originalResult.initialAlcoholPercentage,
    targetAlcoholPercentage: originalResult.targetAlcoholPercentage,
    waterToAdd: originalResult.waterToAdd,
    finalVolume: originalResult.finalVolume,
    finalMeasurement: originalResult.finalMeasurement,
    nearestAvailableVolumes: originalResult.nearestAvailableVolumes,
    nearestAvailablePairs: originalResult.nearestAvailablePairs,
    isExactMatch: originalResult.isExactMatch,
    adjustedWaterToAdd: adjustedWaterToAdd,
    adjustedFinalVolume: selectedFinalVolume,
    adjustedFinalMeasurement: selectedMeasurement,  // 検尺値も更新
    adjustedAlcoholPercentage: adjustedAlcoholPercentage,
  );
}
  
  // Save a dilution plan
  Future<void> saveDilutionPlan(DilutionPlan plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPlansJson = prefs.getStringList(_plansStorageKey) ?? [];
      
      List<DilutionPlan> plans = storedPlansJson
          .map((jsonStr) => DilutionPlan.fromJson(json.decode(jsonStr)))
          .toList();
      
      // Check if we're updating an existing plan
      final existingIndex = plans.indexWhere((p) => p.id == plan.id);
      if (existingIndex >= 0) {
        plans[existingIndex] = plan;
      } else {
        plans.add(plan);
      }
      
      // Save back to prefs
      final updatedPlansJson = plans
          .map((plan) => json.encode(plan.toJson()))
          .toList();
      
      await prefs.setStringList(_plansStorageKey, updatedPlansJson);
    } catch (e) {
      print('Error saving dilution plan: $e');
      throw Exception('保存中にエラーが発生しました');
    }
  }
  
  // Get all dilution plans
  Future<List<DilutionPlan>> getAllDilutionPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPlansJson = prefs.getStringList(_plansStorageKey) ?? [];
      
      return storedPlansJson
          .map((jsonStr) => DilutionPlan.fromJson(json.decode(jsonStr)))
          .toList();
    } catch (e) {
      print('Error loading dilution plans: $e');
      return [];
    }
  }
  
  // Get plans for a specific tank
  Future<List<DilutionPlan>> getPlansForTank(String tankNumber) async {
    final allPlans = await getAllDilutionPlans();
    return allPlans
        .where((plan) => plan.tankNumber == tankNumber)
        .toList();
  }
  
  // Get history for analysis
  Future<List<DilutionPlan>> getDilutionHistory() async {
    return await _historyService.getHistory();
  }
  
  // Get history for a specific tank
  Future<List<DilutionPlan>> getDilutionHistoryForTank(String tankNumber) async {
    return await _historyService.getHistoryForTank(tankNumber);
  }
  
  // Export history to CSV
  Future<String> exportHistoryToCsv() async {
    return await _historyService.exportHistoryToCsv();
  }
  
  // Mark a plan as completed
  Future<void> completePlan(String planId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPlansJson = prefs.getStringList(_plansStorageKey) ?? [];
      
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
        
        // Save back to prefs
        final updatedPlansJson = plans
            .map((plan) => json.encode(plan.toJson()))
            .toList();
        
        await prefs.setStringList(_plansStorageKey, updatedPlansJson);
        
        // Also add to history
        await _historyService.addToHistory(completedPlan);
      }
    } catch (e) {
      print('Error completing dilution plan: $e');
      throw Exception('完了処理中にエラーが発生しました');
    }
  }
  
  // Delete a plan
  Future<void> deletePlan(String planId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPlansJson = prefs.getStringList(_plansStorageKey) ?? [];
      
      List<DilutionPlan> plans = storedPlansJson
          .map((jsonStr) => DilutionPlan.fromJson(json.decode(jsonStr)))
          .toList();
      
      plans.removeWhere((p) => p.id == planId);
      
      // Save back to prefs
      final updatedPlansJson = plans
          .map((plan) => json.encode(plan.toJson()))
          .toList();
      
      await prefs.setStringList(_plansStorageKey, updatedPlansJson);
    } catch (e) {
      print('Error deleting dilution plan: $e');
      throw Exception('削除中にエラーが発生しました');
    }
  }
  
}