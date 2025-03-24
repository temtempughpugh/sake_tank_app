// lib/features/dilution/dilution_controller.dart
import 'package:flutter/material.dart';
import '/core/services/tank_data_service.dart';
import '/core/services/measurement_service.dart';
import '/core/services/approximation_service.dart';
import '/core/services/storage_service.dart';
import '/models/dilution_plan.dart';
import '/models/dilution_result.dart';
import '/models/measurement_capacity_pair.dart';

class DilutionController extends ChangeNotifier {
  final TankDataService _tankDataService;
  final MeasurementService _measurementService;
  final ApproximationService _approximationService;
  final StorageService _storageService;
  
  // 状態変数
  bool _isLoading = false;
  bool _isCalculating = false;
  String? _errorMessage;
  
  // 入力フィールド
  String? selectedTank;
  TextEditingController initialVolumeController = TextEditingController();
  TextEditingController measurementController = TextEditingController();
  TextEditingController initialAlcoholController = TextEditingController();
  TextEditingController targetAlcoholController = TextEditingController();
  TextEditingController sakeNameController = TextEditingController();
  TextEditingController personInChargeController = TextEditingController();
  
  // 近似値関連
  List<Map<String, double>> _volumeApproximations = [];
  List<Map<String, double>> _measurementApproximations = [];
  bool _isLoadingVolumeApproximations = false;
  bool _isLoadingMeasurementApproximations = false;
  bool _isUpdatingVolume = false;
  bool _isUpdatingMeasurement = false;
  
  // 計算結果
  DilutionResult? _dilutionResult;
  double? _selectedFinalVolume;
  double? _selectedFinalMeasurement;
  
  // 編集モード
  bool _isEditMode = false;
  String? _editPlanId;
  
  // ゲッター
  bool get isLoading => _isLoading;
  bool get isCalculating => _isCalculating;
  String? get errorMessage => _errorMessage;
  bool get isEditMode => _isEditMode;
  
  List<Map<String, double>> get volumeApproximations => _volumeApproximations;
  List<Map<String, double>> get measurementApproximations => _measurementApproximations;
  bool get isLoadingVolumeApproximations => _isLoadingVolumeApproximations;
  bool get isLoadingMeasurementApproximations => _isLoadingMeasurementApproximations;
  
  DilutionResult? get dilutionResult => _dilutionResult;
  double? get selectedFinalVolume => _selectedFinalVolume;
  double? get selectedFinalMeasurement => _selectedFinalMeasurement;
  
  // 初期化値
  double? initialVolume;
  double? initialMeasurement;
  double? initialAlcoholPercentage;
  double? targetAlcoholPercentage;
  
  DilutionController({
    required TankDataService tankDataService,
    required MeasurementService measurementService,
    required ApproximationService approximationService,
    required StorageService storageService,
  }) : 
    _tankDataService = tankDataService,
    _measurementService = measurementService,
    _approximationService = approximationService,
    _storageService = storageService {
    // リスナー追加
    initialVolumeController.addListener(_handleVolumeChanged);
    measurementController.addListener(_handleMeasurementChanged);
  }
  
  @override
  void dispose() {
    // リスナー削除
    initialVolumeController.removeListener(_handleVolumeChanged);
    measurementController.removeListener(_handleMeasurementChanged);
    
    // コントローラー破棄
    initialVolumeController.dispose();
    measurementController.dispose();
    initialAlcoholController.dispose();
    targetAlcoholController.dispose();
    sakeNameController.dispose();
    personInChargeController.dispose();
    
    super.dispose();
  }
  
  // 初期化 (編集モード)
  void initWithPlan(DilutionPlan plan) {
    _isEditMode = true;
    _editPlanId = plan.id;
    
    // タンク選択
    selectedTank = plan.tankNumber;
    
    // フォーム値をセット
    initialVolumeController.text = plan.initialVolume.toString();
    measurementController.text = plan.initialMeasurement.toString();
    initialAlcoholController.text = plan.initialAlcoholPercentage.toString();
    targetAlcoholController.text = plan.targetAlcoholPercentage.toString();
    sakeNameController.text = plan.sakeName;
    personInChargeController.text = plan.personInCharge;
    
    // 計算用の値もセット
    initialVolume = plan.initialVolume;
    initialMeasurement = plan.initialMeasurement;
    initialAlcoholPercentage = plan.initialAlcoholPercentage;
    targetAlcoholPercentage = plan.targetAlcoholPercentage;
    
    // 自動計算を実行
    calculateDilution();
  }
  
  // タンク選択時
  void selectTank(String tank) {
    selectedTank = tank;
    notifyListeners();
    
    // 最終タンク保存
    _storageService.saveLastSelectedTank(tank);
  }
  
  // 容量入力時の処理
  void _handleVolumeChanged() {
    if (_isUpdatingVolume) return;  // ループ防止
    
    final volumeText = initialVolumeController.text;
    initialVolume = double.tryParse(volumeText);
    
    if (initialVolume != null) {
      _findMeasurementFromVolume();
    } else {
      _volumeApproximations = [];
    }
  }
  
  // 検尺入力時の処理
  void _handleMeasurementChanged() {
    if (_isUpdatingMeasurement) return;  // ループ防止
    
    final measurementText = measurementController.text;
    initialMeasurement = double.tryParse(measurementText);
    
    if (initialMeasurement != null) {
      _findVolumeFromMeasurement();
    } else {
      _measurementApproximations = [];
    }
  }
  
  // 容量から検尺を計算
  Future<void> calculateMeasurementFromVolume() async {
    if (selectedTank == null) {
      _errorMessage = 'タンクを選択してください';
      notifyListeners();
      return;
    }
    
    final volume = double.tryParse(initialVolumeController.text);
    if (volume == null) {
      _errorMessage = '有効な容量（数値）を入力してください';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await _measurementService.calculateMeasurement(selectedTank!, volume);
      if (result != null) {
        _isUpdatingMeasurement = true;
        initialMeasurement = result.measurement;
        measurementController.text = result.measurement.toStringAsFixed(1);
        _isUpdatingMeasurement = false;
      } else {
        _errorMessage = 'この容量に対応する検尺データが見つかりません';
      }
    } catch (e) {
      _errorMessage = '計算中にエラーが発生しました: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 検尺から容量を計算
  Future<void> calculateVolumeFromMeasurement() async {
    if (selectedTank == null) {
      _errorMessage = 'タンクを選択してください';
      notifyListeners();
      return;
    }
    
    final measurement = double.tryParse(measurementController.text);
    if (measurement == null) {
      _errorMessage = '有効な検尺値（数値）を入力してください';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await _measurementService.calculateCapacity(selectedTank!, measurement);
      if (result != null) {
        _isUpdatingVolume = true;
        initialVolume = result.capacity;
        initialVolumeController.text = result.capacity.toStringAsFixed(1);
        _isUpdatingVolume = false;
      } else {
        _errorMessage = 'この検尺値に対応する容量データが見つかりません';
      }
    } catch (e) {
      _errorMessage = '計算中にエラーが発生しました: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 近似値検索: 容量→検尺
  Future<void> _findMeasurementFromVolume() async {
    if (selectedTank == null || initialVolume == null) {
      _measurementApproximations = [];
      notifyListeners();
      return;
    }
    
    _isLoadingMeasurementApproximations = true;
    notifyListeners();
    
    // 遅延処理（連続入力時の負荷軽減）
    await Future.delayed(Duration(milliseconds: 300));
    
    try {
      // タンクデータを取得
      final tankData = await _tankDataService.getTankData(selectedTank!);
      if (tankData.isEmpty) {
        _measurementApproximations = [];
        _isLoadingMeasurementApproximations = false;
        notifyListeners();
        return;
      }
      
      // 容量でソート
      tankData.sort((a, b) => a.capacity.compareTo(b.capacity));
      
      // 最大・最小容量を取得
      final minCapacity = tankData.first.capacity;
      final maxCapacity = tankData.last.capacity;
      
      // 容量が範囲外か確認
      if (initialVolume! < minCapacity || initialVolume! > maxCapacity) {
        // 最も近い値を提案
        _measurementApproximations = [
          {
            'capacity': initialVolume! < minCapacity ? minCapacity : maxCapacity,
            'measurement': initialVolume! < minCapacity ? tankData.first.measurement : tankData.last.measurement,
          }
        ];
        _isLoadingMeasurementApproximations = false;
        notifyListeners();
        return;
      }
      
      // 完全一致を確認
      bool hasExactMatch = tankData.any((data) => data.capacity == initialVolume);
      
      if (hasExactMatch) {
        // 完全一致があれば自動的に検尺値を設定
        final exactMatch = tankData.firstWhere((data) => data.capacity == initialVolume);
        
        _isUpdatingMeasurement = true;
        measurementController.text = exactMatch.measurement.toString();
        initialMeasurement = exactMatch.measurement;
        _isUpdatingMeasurement = false;
        
        _measurementApproximations = [];
      } else {
        // 近似値を探す
        List<Map<String, double>> approximations = [];
        MeasurementCapacityPair? lowerData;
        MeasurementCapacityPair? upperData;
        
        for (int i = 0; i < tankData.length - 1; i++) {
          if (tankData[i].capacity <= initialVolume! && initialVolume! <= tankData[i + 1].capacity) {
            lowerData = tankData[i];
            upperData = tankData[i + 1];
            break;
          }
        }
        
        if (lowerData != null) {
          approximations.add({
            'capacity': lowerData.capacity,
            'measurement': lowerData.measurement
          });
        }
        
        if (upperData != null) {
          approximations.add({
            'capacity': upperData.capacity,
            'measurement': upperData.measurement
          });
        }
        
        _measurementApproximations = approximations;
      }
    } catch (e) {
      print('近似値検索エラー: $e');
      _measurementApproximations = [];
    } finally {
      _isLoadingMeasurementApproximations = false;
      notifyListeners();
    }
  }
  
  // 近似値検索: 検尺→容量
  Future<void> _findVolumeFromMeasurement() async {
    if (selectedTank == null || initialMeasurement == null) {
      _volumeApproximations = [];
      notifyListeners();
      return;
    }
    
    _isLoadingVolumeApproximations = true;
    notifyListeners();
    
    // 遅延処理（連続入力時の負荷軽減）
    await Future.delayed(Duration(milliseconds: 300));
    
    try {
      // タンクデータを取得
      final tankData = await _tankDataService.getTankData(selectedTank!);
      if (tankData.isEmpty) {
        _volumeApproximations = [];
        _isLoadingVolumeApproximations = false;
        notifyListeners();
        return;
      }
      
      // 検尺でソート
      tankData.sort((a, b) => a.measurement.compareTo(b.measurement));
      
      // 最大・最小検尺を取得
      final minMeasurement = tankData.first.measurement;
      final maxMeasurement = tankData.last.measurement;
      
      // 検尺が範囲外か確認
      if (initialMeasurement! < minMeasurement || initialMeasurement! > maxMeasurement) {
        // 最も近い値を提案
        _volumeApproximations = [
          {
            'measurement': initialMeasurement! < minMeasurement ? minMeasurement : maxMeasurement,
            'capacity': initialMeasurement! < minMeasurement ? tankData.first.capacity : tankData.last.capacity,
          }
        ];
        _isLoadingVolumeApproximations = false;
        notifyListeners();
        return;
      }
      
      // 完全一致を確認
      bool hasExactMatch = tankData.any((data) => data.measurement == initialMeasurement);
      
      if (hasExactMatch) {
        // 完全一致があれば自動的に容量を設定
        final exactMatch = tankData.firstWhere((data) => data.measurement == initialMeasurement);
        
        _isUpdatingVolume = true;
        initialVolumeController.text = exactMatch.capacity.toString();
        initialVolume = exactMatch.capacity;
        _isUpdatingVolume = false;
        
        _volumeApproximations = [];
      } else {
        // 近似値を探す
        List<Map<String, double>> approximations = [];
        MeasurementCapacityPair? lowerData;
        MeasurementCapacityPair? upperData;
        
        for (int i = 0; i < tankData.length - 1; i++) {
          if (tankData[i].measurement <= initialMeasurement! && initialMeasurement! <= tankData[i + 1].measurement) {
            lowerData = tankData[i];
            upperData = tankData[i + 1];
            break;
          }
        }
        
        if (lowerData != null) {
          approximations.add({
            'measurement': lowerData.measurement,
            'capacity': lowerData.capacity
          });
        }
        
        if (upperData != null) {
          approximations.add({
            'measurement': upperData.measurement,
            'capacity': upperData.capacity
          });
        }
        
        _volumeApproximations = approximations;
      }
    } catch (e) {
      print('近似値検索エラー: $e');
      _volumeApproximations = [];
    } finally {
      _isLoadingVolumeApproximations = false;
      notifyListeners();
    }
  }
  
  // 容量近似値選択時
  void selectVolumeApproximation(Map<String, double> approximation) {
    _isUpdatingVolume = true;
    _isUpdatingMeasurement = true;
    
    initialVolume = approximation['capacity'];
    initialVolumeController.text = initialVolume.toString();
    
    initialMeasurement = approximation['measurement'];
    measurementController.text = initialMeasurement.toString();
    
    _volumeApproximations = [];
    _measurementApproximations = [];
    
    _isUpdatingVolume = false;
    _isUpdatingMeasurement = false;
    
    notifyListeners();
  }
  
  // 検尺近似値選択時
  void selectMeasurementApproximation(Map<String, double> approximation) {
    _isUpdatingVolume = true;
    _isUpdatingMeasurement = true;
    
    initialMeasurement = approximation['measurement'];
    measurementController.text = initialMeasurement.toString();
    
    initialVolume = approximation['capacity'];
    initialVolumeController.text = initialVolume.toString();
    
    _measurementApproximations = [];
    _volumeApproximations = [];
    
    _isUpdatingVolume = false;
    _isUpdatingMeasurement = false;
    
    notifyListeners();
  }
  
  // 割水計算実行
  Future<void> calculateDilution() async {
    _errorMessage = null;
    
    if (selectedTank == null) {
      _errorMessage = 'タンクを選択してください';
      notifyListeners();
      return;
    }
    
    initialVolume = double.tryParse(initialVolumeController.text);
    if (initialVolume == null) {
      _errorMessage = '有効な初期容量（数値）を入力してください';
      notifyListeners();
      return;
    }
    
    initialAlcoholPercentage = double.tryParse(initialAlcoholController.text);
    if (initialAlcoholPercentage == null) {
      _errorMessage = '有効な初期アルコール度数（数値）を入力してください';
      notifyListeners();
      return;
    }
    
    targetAlcoholPercentage = double.tryParse(targetAlcoholController.text);
    if (targetAlcoholPercentage == null) {
      _errorMessage = '有効な目標アルコール度数（数値）を入力してください';
      notifyListeners();
      return;
    }
    
    if (targetAlcoholPercentage >= initialAlcoholPercentage) {
      _errorMessage = '目標アルコール度数は初期アルコール度数より低くする必要があります';
      notifyListeners();
      return;
    }
    
    initialMeasurement = double.tryParse(measurementController.text);
    if (initialMeasurement == null) {
      _errorMessage = '有効な検尺値（数値）を入力してください';
      notifyListeners();
      return;
    }
    
    // タンクの容量範囲をチェック
    try {
      // タンクの最大容量を取得
      final maxCapacity = await _tankDataService.getMaxCapacity(selectedTank!);
      if (maxCapacity != null && initialVolume! > maxCapacity) {
        _errorMessage = '入力された容量(${initialVolume!.toStringAsFixed(1)}L)はタンク${selectedTank}の最大容量(${maxCapacity.toStringAsFixed(1)}L)を超えています';
        notifyListeners();
        return;
      }
      
      // タンクのデータを取得して最小容量をチェック
      final tankData = await _tankDataService.getTankData(selectedTank!);
      if (tankData.isNotEmpty) {
        tankData.sort((a, b) => a.capacity.compareTo(b.capacity));
        final minCapacity = tankData.first.capacity;
        
        if (initialVolume! < minCapacity) {
          _errorMessage = '入力された容量(${initialVolume!.toStringAsFixed(1)}L)はタンク${selectedTank}の最小容量(${minCapacity.toStringAsFixed(1)}L)未満です';
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      print('容量チェック中にエラーが発生しました: $e');
      // エラーが発生してもとりあえず計算は続行
    }
    
    _isCalculating = true;
    notifyListeners();
    
    try {
      // 計算実行
      
      // 1. 最終容量と追加水量を計算
      final finalVolume = initialVolume! * (initialAlcoholPercentage! / targetAlcoholPercentage!);
      final waterToAdd = finalVolume - initialVolume!;
      
      // 2. 最終検尺値を計算
      final measurementResult = await _measurementService.calculateMeasurement(
        selectedTank!, 
        finalVolume
      );
      
      if (measurementResult == null) {
        _errorMessage = '検尺値の計算に失敗しました';
        _isCalculating = false;
        notifyListeners();
        return;
      }
      
      final finalMeasurement = measurementResult.measurement;
      
      // 3. 容量の近似値を取得
      final tankData = await _tankDataService.getTankData(selectedTank!);
      final nearestPairs = await _approximationService.findNearestPairsForDilution(
        tankData, 
        finalVolume
      );
      
      // 4. 結果を設定
      _dilutionResult = DilutionResult(
        initialVolume: initialVolume!,
        initialAlcoholPercentage: initialAlcoholPercentage!,
        targetAlcoholPercentage: targetAlcoholPercentage!,
        waterToAdd: waterToAdd,
        finalVolume: finalVolume,
        finalMeasurement: finalMeasurement,
        nearestAvailablePairs: nearestPairs,
        isExactMatch: measurementResult.isExactMatch,
      );
      
      // 選択値をリセット
      _selectedFinalVolume = null;
      _selectedFinalMeasurement = null;
    } catch (e) {
      _errorMessage = '計算中にエラーが発生しました: $e';
    } finally {
      _isCalculating = false;
      notifyListeners();
    }
  }
  
  // 最終容量の近似値選択
  void selectFinalVolume(Map<String, double> pair) {
    if (_dilutionResult == null) return;
    
    final volume = pair['capacity']!;
    final measurement = pair['measurement']!;
    
    _selectedFinalVolume = volume;
    _selectedFinalMeasurement = measurement;
    
    // 調整後の値を計算
    final adjustedWaterToAdd = volume - initialVolume!;
    final adjustedAlcoholPercentage = (initialVolume! * initialAlcoholPercentage!) / volume;
    
    // 結果を更新
    _dilutionResult = DilutionResult(
      initialVolume: _dilutionResult!.initialVolume,
      initialAlcoholPercentage: _dilutionResult!.initialAlcoholPercentage,
      targetAlcoholPercentage: _dilutionResult!.targetAlcoholPercentage,
      waterToAdd: _dilutionResult!.waterToAdd,
      finalVolume: _dilutionResult!.finalVolume,
      finalMeasurement: _dilutionResult!.finalMeasurement,
      nearestAvailablePairs: _dilutionResult!.nearestAvailablePairs,
      isExactMatch: _dilutionResult!.isExactMatch,
      adjustedWaterToAdd: adjustedWaterToAdd,
      adjustedFinalVolume: volume,
      adjustedFinalMeasurement: measurement,
      adjustedAlcoholPercentage: adjustedAlcoholPercentage,
    );
    
    notifyListeners();
  }
  
  // 割水計画を保存
  Future<bool> saveDilutionPlan() async {
    if (selectedTank == null || _dilutionResult == null) {
      _errorMessage = 'タンクが選択されていないか、計算結果がありません';
      notifyListeners();
      return false;
    }
    
    if (initialVolume == null || initialMeasurement == null) {
      _errorMessage = '初期容量または検尺が設定されていません';
      notifyListeners();
      return false;
    }
    
    // 編集時は既存IDを使用、新規作成時は新しいIDを生成
    final planId = _isEditMode ? _editPlanId! : DateTime.now().millisecondsSinceEpoch.toString();
    
    // 調整後の値または元の値を使用
    final waterToAdd = _selectedFinalVolume != null 
        ? _dilutionResult!.adjustedWaterToAdd! 
        : _dilutionResult!.waterToAdd;
    
    final finalVolume = _selectedFinalVolume ?? _dilutionResult!.finalVolume;
    final finalMeasurement = _selectedFinalMeasurement ?? _dilutionResult!.finalMeasurement;
    
    final actualAlcohol = _selectedFinalVolume != null 
        ? _dilutionResult!.adjustedAlcoholPercentage! 
        : _dilutionResult!.targetAlcoholPercentage;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final plan = DilutionPlan(
        id: planId,
        tankNumber: selectedTank!,
        initialVolume: initialVolume!,
        initialMeasurement: initialMeasurement!,
        initialAlcoholPercentage: initialAlcoholPercentage!,
        targetAlcoholPercentage: targetAlcoholPercentage!,
        waterToAdd: waterToAdd,
        finalVolume: finalVolume,
        finalMeasurement: finalMeasurement,
        sakeName: sakeNameController.text,
        personInCharge: personInChargeController.text,
        plannedDate: _isEditMode && widget.planToEdit != null 
            ? widget.planToEdit!.plannedDate 
            : DateTime.now(),
        completionDate: _isEditMode && widget.planToEdit != null 
            ? widget.planToEdit!.completionDate 
            : null,
        isCompleted: _isEditMode && widget.planToEdit != null 
            ? widget.planToEdit!.isCompleted 
            : false,
      );
      
      await _storageService.saveDilutionPlan(plan);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '保存中にエラーが発生しました: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // フォームクリア
  void resetForm() {
    initialVolumeController.clear();
    measurementController.clear();
    initialAlcoholController.clear();
    targetAlcoholController.clear();
    sakeNameController.clear();
    personInChargeController.clear();
    
    initialVolume = null;
    initialMeasurement = null;
    initialAlcoholPercentage = null;
    targetAlcoholPercentage = null;
    
    _dilutionResult = null;
    _selectedFinalVolume = null;
    _selectedFinalMeasurement = null;
    
    _errorMessage = null;
    
    notifyListeners();
  }
}