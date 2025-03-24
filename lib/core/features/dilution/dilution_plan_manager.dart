import 'package:flutter/material.dart';
import '/core/services/storage_service.dart';
import '/models/measurement_result.dart';

/// 割水計画を管理するクラス
/// 計画の一覧表示、完了、削除などを担当
class DilutionPlanManager extends ChangeNotifier {
  final StorageService _storageService;
  
  // 状態変数
  bool _isLoading = false;
  List<DilutionPlan> _activePlans = [];
  List<DilutionPlan> _completedPlans = [];
  int _selectedTabIndex = 0;
  
  // ゲッター
  bool get isLoading => _isLoading;
  List<DilutionPlan> get activePlans => _activePlans;
  List<DilutionPlan> get completedPlans => _completedPlans;
  int get selectedTabIndex => _selectedTabIndex;
  
  // タンク番号でグループ化されたプラン
  Map<String, List<DilutionPlan>> get activePlansByTank {
    final Map<String, List<DilutionPlan>> result = {};
    
    for (final plan in _activePlans) {
      if (!result.containsKey(plan.tankNumber)) {
        result[plan.tankNumber] = [];
      }
      result[plan.tankNumber]!.add(plan);
    }
    
    return result;
  }
  
  // コンストラクタ
  DilutionPlanManager({required StorageService storageService}) 
      : _storageService = storageService {
    // 初期化時にデータを読み込む
    loadPlans();
  }
  
  /// タブを選択
  void selectTab(int tabIndex) {
    _selectedTabIndex = tabIndex;
    notifyListeners();
  }
  
  /// 計画を読み込む
  Future<void> loadPlans() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final allPlans = await _storageService.getAllDilutionPlans();
      
      // 完了/未完了で分類
      _activePlans = allPlans.where((plan) => !plan.isCompleted).toList();
      _completedPlans = allPlans.where((plan) => plan.isCompleted).toList();
      
      // 日付でソート
      _activePlans.sort((a, b) => a.plannedDate.compareTo(b.plannedDate));
      _completedPlans.sort((a, b) => b.completionDate!.compareTo(a.completionDate!));
    } catch (e) {
      print('計画の読み込みに失敗: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 計画を完了としてマーク
  Future<void> completePlan(String planId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _storageService.completeDilutionPlan(planId);
      await loadPlans(); // リロード
    } catch (e) {
      print('計画の完了処理に失敗: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 計画を削除
  Future<void> deletePlan(String planId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _storageService.deleteDilutionPlan(planId);
      await loadPlans(); // リロード
    } catch (e) {
      print('計画の削除に失敗: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 特定のタンクの計画を取得
  List<DilutionPlan> getPlansForTank(String tankNumber) {
    return _activePlans.where((plan) => plan.tankNumber == tankNumber).toList();
  }
}