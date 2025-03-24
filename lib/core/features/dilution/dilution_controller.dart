import 'package:flutter/material.dart';
import '/core/services/tank_data_service.dart';
import '/core/services/measurement_service.dart';
import '/core/services/approximation_service.dart';
import '/core/services/storage_service.dart';
import '/models/measurement_result.dart';
import '/models/dilution_plan.dart';
import '/models/dilution_calc_result.dart';


/// 割水計算機能のためのコントローラークラス
/// UI状態管理とサービス機能の橋渡し役
class DilutionController extends ChangeNotifier {
  // 依存サービス
  final TankDataService _tankDataService;
  final MeasurementService _measurementService;
  final ApproximationService _approximationService;
  final StorageService _storageService;
  
  // 編集モード
  bool _isEditMode = false;
  String? _editPlanId;
  
  // 入力コントローラー
  final TextEditingController initialVolumeController = TextEditingController();
  final TextEditingController measurementController = TextEditingController();
  final TextEditingController initialAlcoholController = TextEditingController();
  final TextEditingController targetAlcoholController = TextEditingController();
  final TextEditingController sakeNameController = TextEditingController();
  final TextEditingController personInChargeController = TextEditingController();
  
  // 状態変数
  String? _selectedTank;
  bool _isLoading = false;
  bool _isCalculating = false;
  
  // 近似値の状態
  List<Map<String, double>> _volumeApproximations = [];
  List<Map<String, double>> _measurementApproximations = [];
  bool _isLoadingVolumeApproximations = false;
  bool _isLoadingMeasurementApproximations = false;
  bool _isUpdatingVolume = false;
  bool _isUpdatingMeasurement = false;
  
  // 計算結果関連
  DilutionCalcResult? _dilutionResult;
  double? _finalMeasurement;
  double? _selectedFinalVolume;
  double? _selectedFinalMeasurement;
  double? _adjustedWaterToAdd;
  double? _actualAlcoholPercentage;
  List<Map<String, double>> _finalVolumeApproximations = [];
  bool _isExactMatch = false;
  
  // ゲッター
  String? get selectedTank => _selectedTank;
  bool get isLoading => _isLoading;
  bool get isCalculating => _isCalculating;
  bool get isEditMode => _isEditMode;
  String? get editPlanId => _editPlanId;
  
  List<Map<String, double>> get volumeApproximations => _volumeApproximations;
  List<Map<String, double>> get measurementApproximations => _measurementApproximations;
  bool get isLoadingVolumeApproximations => _isLoadingVolumeApproximations;
  bool get isLoadingMeasurementApproximations => _isLoadingMeasurementApproximations;
  
  DilutionCalcResult? get dilutionResult => _dilutionResult;
  double? get finalMeasurement => _finalMeasurement;
  double? get selectedFinalVolume => _selectedFinalVolume;
  double? get selectedFinalMeasurement => _selectedFinalMeasurement;
  double? get adjustedWaterToAdd => _adjustedWaterToAdd;
  double? get actualAlcoholPercentage => _actualAlcoholPercentage;
  List<Map<String, double>> get finalVolumeApproximations => _finalVolumeApproximations;
  bool get isExactMatch => _isExactMatch;
  
  // 計算結果があるかどうか
  bool get hasCalculationResult => _dilutionResult != null;
  
  // コンストラクタ
  DilutionController({
    required TankDataService tankDataService,
    required MeasurementService measurementService,
    required ApproximationService approximationService,
    required StorageService storageService,
  }) : _tankDataService = tankDataService,
       _measurementService = measurementService,
       _approximationService = approximationService,
       _storageService = storageService {
    // 初期化処理
    _init();
  }
  
  /// 初期化処理
  Future<void> _init() async {
    // 入力コントローラーの変更リスナーを追加
    initialVolumeController.addListener(_findMeasurementFromVolume);
    measurementController.addListener(_findVolumeFromMeasurement);
    
    // 最後に選択されたタンクを読み込む
    final lastTank = await _storageService.getLastSelectedTank();
    if (lastTank != null) {
      _selectedTank = lastTank;
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    // コントローラーの破棄
    initialVolumeController.removeListener(_findMeasurementFromVolume);
    measurementController.removeListener(_findVolumeFromMeasurement);
    
    initialVolumeController.dispose();
    measurementController.dispose();
    initialAlcoholController.dispose();
    targetAlcoholController.dispose();
    sakeNameController.dispose();
    personInChargeController.dispose();
    
    super.dispose();
  }
  
  /// タンクを選択
  void selectTank(String tankNumber) {
    if (_selectedTank == tankNumber) return;
    
    _selectedTank = tankNumber;
    _storageService.saveLastSelectedTank(tankNumber);
    
    // 選択変更に伴うリセット
    _resetApproximations();
    _resetCalculationResult();
    
    notifyListeners();
  }
  
  /// 編集モードに設定
  void setEditMode(DilutionPlan plan) {
    _isEditMode = true;
    _editPlanId = plan.id;
    
    // フォーム値を設定
    _selectedTank = plan.tankNumber;
    initialVolumeController.text = plan.initialVolume.toString();
    measurementController.text = plan.initialMeasurement.toString();
    initialAlcoholController.text = plan.initialAlcoholPercentage.toString();
    targetAlcoholController.text = plan.targetAlcoholPercentage.toString();
    sakeNameController.text = plan.sakeName;
    personInChargeController.text = plan.personInCharge;
    
    // 計算を実行して結果を表示
    calculateDilution();
    
    notifyListeners();
  }
  
  /// 容量から検尺を探す
  Future
  <void> _findMeasurementFromVolume() async {
    // ループ防止（更新中なら処理しない）
    if (_isUpdatingMeasurement) return;
    
    if (_selectedTank == null || initialVolumeController.text.isEmpty) {
      _measurementApproximations = [];
      notifyListeners();
      return;
    }
    
    final volume = double.tryParse(initialVolumeController.text);
    if (volume == null) return;
    
    _isLoadingMeasurementApproximations = true;
    notifyListeners();
    
    // 遅延処理で連続入力時の負荷を軽減
    await Future.delayed(Duration(milliseconds: 300));
    
    try {
      // 容量に対応する近似検尺値を取得
      final approximations = await _approximationService.findApproximateMeasurementsByVolume(
        _selectedTank!,
        volume
      );
      
      _measurementApproximations = approximations;
    } catch (e) {
      print('検尺の近似値取得に失敗: $e');
      _measurementApproximations = [];
    } finally {
      _isLoadingMeasurementApproximations = false;
      notifyListeners();
    }
  }
  
  /// 検尺から容量を探す
  Future<void> _findVolumeFromMeasurement() async {
    // ループ防止
    if (_isUpdatingVolume) return;
    
    if (_selectedTank == null || measurementController.text.isEmpty) {
      _volumeApproximations = [];
      notifyListeners();
      return;
    }
    
    final measurement = double.tryParse(measurementController.text);
    if (measurement == null) return;
    
    _isLoadingVolumeApproximations = true;
    notifyListeners();
    
    // 遅延処理
    await Future.delayed(Duration(milliseconds: 300));
    
    try {
      // 検尺値に対応する近似容量を取得
      final approximations = await _approximationService.findApproximateVolumesByMeasurement(
        _selectedTank!,
        measurement
      );
      
      _volumeApproximations = approximations;
    } catch (e) {
      print('容量の近似値取得に失敗: $e');
      _volumeApproximations = [];
    } finally {
      _isLoadingVolumeApproximations = false;
      notifyListeners();
    }
  }
  
  /// 検尺値を選択（近似値から）
  void selectMeasurementApproximation(double measurement, double capacity) {
    // 更新中フラグをセット
    _isUpdatingVolume = true;
    _isUpdatingMeasurement = true;
    
    // 値を更新
    measurementController.text = measurement.toString();
    initialVolumeController.text = capacity.toString();
    
    // リセット
    _resetApproximations();
    
    // フラグをリセット
    Future.delayed(Duration(milliseconds: 100), () {
      _isUpdatingVolume = false;
      _isUpdatingMeasurement = false;
    });
    
    notifyListeners();
  }
  
  /// 容量を選択（近似値から）
  void selectVolumeApproximation(double capacity, double measurement) {
    // 更新中フラグをセット
    _isUpdatingVolume = true;
    _isUpdatingMeasurement = true;
    
    // 値を更新
    initialVolumeController.text = capacity.toString();
    measurementController.text = measurement.toString();
    
    // リセット
    _resetApproximations();
    
    // フラグをリセット
    Future.delayed(Duration(milliseconds: 100), () {
      _isUpdatingVolume = false;
      _isUpdatingMeasurement = false;
    });
    
    notifyListeners();
  }
  
  /// 検尺から容量を計算
  Future<void> calculateCapacityFromMeasurement() async {
    if (_selectedTank == null) {
      throw Exception('タンクが選択されていません');
    }
    
    final measurement = double.tryParse(measurementController.text);
    if (measurement == null) {
      throw Exception('有効な検尺値を入力してください');
    }
    
    _isUpdatingVolume = true;
    
    try {
      final result = await _tankDataService.calculateCapacity(_selectedTank!, measurement);
      if (result != null) {
        initialVolumeController.text = result.capacity.toStringAsFixed(1);
      } else {
        throw Exception('この検尺値に対応する容量が見つかりません');
      }
    } finally {
      _isUpdatingVolume = false;
    }
  }
  
  /// 容量から検尺を計算
  Future<void> calculateMeasurementFromCapacity() async {
    if (_selectedTank == null) {
      throw Exception('タンクが選択されていません');
    }
    
    final capacity = double.tryParse(initialVolumeController.text);
    if (capacity == null) {
      throw Exception('有効な容量を入力してください');
    }
    
    _isUpdatingMeasurement = true;
    
    try {
      final result = await _tankDataService.calculateMeasurement(_selectedTank!, capacity);
      if (result != null) {
        measurementController.text = result.measurement.toStringAsFixed(1);
      } else {
        throw Exception('この容量に対応する検尺値が見つかりません');
      }
    } finally {
      _isUpdatingMeasurement = false;
    }
  }
  
  /// 割水計算を実行
  Future<void> calculateDilution() async {
    if (_selectedTank == null) {
      throw Exception('タンクを選択してください');
    }
    
    final initialVolume = double.tryParse(initialVolumeController.text);
    if (initialVolume == null) {
      throw Exception('有効な初期容量を入力してください');
    }
    
    final initialAlcohol = double.tryParse(initialAlcoholController.text);
    if (initialAlcohol == null) {
      throw Exception('有効な初期アルコール度数を入力してください');
    }
    
    final targetAlcohol = double.tryParse(targetAlcoholController.text);
    if (targetAlcohol == null) {
      throw Exception('有効な目標アルコール度数を入力してください');
    }
    
    if (targetAlcohol >= initialAlcohol) {
      throw Exception('目標アルコール度数は初期アルコール度数より低くする必要があります');
    }
    
    _isCalculating = true;
    notifyListeners();
    
    try {
      // タンクの容量範囲チェック
      final maxCapacity = await _tankDataService.getMaxCapacity(_selectedTank!);
      if (maxCapacity != null && initialVolume > maxCapacity) {
        throw Exception('入力された容量(${initialVolume.toStringAsFixed(1)}L)はタンク${_selectedTank}の最大容量(${maxCapacity.toStringAsFixed(1)}L)を超えています');
      }
      
      // 計算される最終容量をチェック
      final estimatedFinalVolume = initialVolume * (initialAlcohol / targetAlcohol);
      if (maxCapacity != null && estimatedFinalVolume > maxCapacity) {
        throw Exception('計算される割水後の容量(${estimatedFinalVolume.toStringAsFixed(1)}L)がタンク${_selectedTank}の最大容量(${maxCapacity.toStringAsFixed(1)}L)を超えています\n\n目標アルコール度数を下げるか、初期容量を減らしてください');
      }
      
      // 割水計算実行
      final result = _measurementService.calculateDilution(
        initialVolume: initialVolume,
        initialAlcoholPercentage: initialAlcohol,
        targetAlcoholPercentage: targetAlcohol,
      );
      
      // 検尺値を計算
      MeasurementResult? measurementResult;
      try {
        measurementResult = await _tankDataService.calculateMeasurement(
          _selectedTank!,
          result.finalVolume
        );
      } catch (e) {
        print('検尺計算に失敗: $e');
      }
      
      // 最終容量の近似値を取得
      final approxVolumes = await _approximationService.findNearestVolumePairs(
        _selectedTank!,
        result.finalVolume
      );
      
      // 完全一致かどうかを判定
      bool isExact = false;
      if (measurementResult != null) {
        isExact = measurementResult.isExactMatch;
      } else if (approxVolumes.isNotEmpty) {
        // 容量が完全一致するかチェック
        isExact = approxVolumes.any((pair) => 
          (pair['capacity']! - result.finalVolume).abs() < 0.001);
      }
      
      // 結果を設定
      _dilutionResult = result;
      _finalMeasurement = measurementResult?.measurement;
      _finalVolumeApproximations = approxVolumes;
      _isExactMatch = isExact;
      
      // 選択された値をリセット
      _selectedFinalVolume = null;
      _selectedFinalMeasurement = null;
      _adjustedWaterToAdd = null;
      _actualAlcoholPercentage = null;
      
    } catch (e) {
      rethrow;
    } finally {
      _isCalculating = false;
      notifyListeners();
    }
  }
  
  /// 最終容量を選択（近似値から）
  void selectFinalVolume(double volume, double measurement) {
    if (_dilutionResult == null) return;
    
    _selectedFinalVolume = volume;
    _selectedFinalMeasurement = measurement;
    
    // 水量を調整
    _adjustedWaterToAdd = volume - double.parse(initialVolumeController.text);
    
    // 実際のアルコール度数を再計算
    _actualAlcoholPercentage = _measurementService.calculateActualAlcohol(
      originalLiquorVolume: double.parse(initialVolumeController.text),
      originalAlcoholPercentage: double.parse(initialAlcoholController.text),
      dilutionAmount: _adjustedWaterToAdd!,
    );
    
    notifyListeners();
  }
  
  /// フォームをリセット
  void resetForm() {
    // 入力値をクリア
    initialVolumeController.clear();
    measurementController.clear();
    initialAlcoholController.clear();
    targetAlcoholController.clear();
    sakeNameController.clear();
    personInChargeController.clear();
    
    // 近似値と計算結果をリセット
    _resetApproximations();
    _resetCalculationResult();
    
    notifyListeners();
  }
  
  /// 計算結果をリセット
  void _resetCalculationResult() {
    _dilutionResult = null;
    _finalMeasurement = null;
    _selectedFinalVolume = null;
    _selectedFinalMeasurement = null;
    _adjustedWaterToAdd = null;
    _actualAlcoholPercentage = null;
    _finalVolumeApproximations = [];
    _isExactMatch = false;
  }
  
  /// 近似値をリセット
  void _resetApproximations() {
    _volumeApproximations = [];
    _measurementApproximations = [];
    _isLoadingVolumeApproximations = false;
    _isLoadingMeasurementApproximations = false;
  }
  
  /// 割水計画を保存
  Future<void> saveDilutionPlan() async {
    if (_selectedTank == null || _dilutionResult == null) {
      throw Exception('タンクが選択されていないか、計算結果がありません');
    }
    
    final initialVolume = double.tryParse(initialVolumeController.text);
    final initialMeasurement = double.tryParse(measurementController.text);
    
    if (initialVolume == null) {
      throw Exception('有効な初期容量が入力されていません');
    }
    
    if (initialMeasurement == null) {
      throw Exception('有効な検尺値が入力されていません');
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // 編集時は既存ID、新規作成時は新しいID
      final planId = _isEditMode ? _editPlanId! : DateTime.now().millisecondsSinceEpoch.toString();
      
      // 計算に使用する値を取得
      final waterToAdd = _selectedFinalVolume != null 
          ? _adjustedWaterToAdd! 
          : _dilutionResult!.waterToAdd;
      
      final finalVolume = _selectedFinalVolume ?? _dilutionResult!.finalVolume;
      
      final actualAlcohol = _selectedFinalVolume != null 
          ? _actualAlcoholPercentage! 
          : double.parse(targetAlcoholController.text);
      
      // 計画オブジェクトを作成
      final plan = DilutionPlan(
        id: planId,
        tankNumber: _selectedTank!,
        initialVolume: initialVolume,
        initialMeasurement: initialMeasurement,
        initialAlcoholPercentage: double.parse(initialAlcoholController.text),
        targetAlcoholPercentage: double.parse(targetAlcoholController.text),
        waterToAdd: waterToAdd,
        finalVolume: finalVolume,
        finalMeasurement: _selectedFinalMeasurement ?? _finalMeasurement ?? 0,
        sakeName: sakeNameController.text,
        personInCharge: personInChargeController.text,
        plannedDate: DateTime.now(),
        isCompleted: false,
      );
      
      // 保存
      await _storageService.saveDilutionPlan(plan);
      
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}