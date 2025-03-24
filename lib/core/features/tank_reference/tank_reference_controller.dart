import 'package:flutter/material.dart';
import '/core/services/tank_data_service.dart';
import '/core/services/measurement_service.dart';
import '/models/measurement_result.dart';

/// タンク早見表画面のコントローラー
class TankReferenceController extends ChangeNotifier {
  // 依存サービス
  final TankDataService _tankDataService;
  final MeasurementService _measurementService;
  
  // 入力コントローラー
  final TextEditingController measurementController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();
  
  // 状態変数
  String? _selectedTank;
  bool _isLoading = false;
  bool _isMeasurementCalculating = false;
  bool _isCapacityCalculating = false;
  
  // 計算結果
  MeasurementResult? _capacityResult;
  MeasurementResult? _measurementResult;
  
  // ゲッター
  String? get selectedTank => _selectedTank;
  bool get isLoading => _isLoading;
  bool get isMeasurementCalculating => _isMeasurementCalculating;
  bool get isCapacityCalculating => _isCapacityCalculating;
  MeasurementResult? get capacityResult => _capacityResult;
  MeasurementResult? get measurementResult => _measurementResult;
  
  // コンストラクタ
  TankReferenceController({
    required TankDataService tankDataService,
    required MeasurementService measurementService,
  }) : _tankDataService = tankDataService,
       _measurementService = measurementService;
  
  @override
  void dispose() {
    measurementController.dispose();
    capacityController.dispose();
    super.dispose();
  }
  
  /// タンクを選択
  void selectTank(String tankNumber) {
    _selectedTank = tankNumber;
    
    // 選択変更に伴うリセット
    _capacityResult = null;
    _measurementResult = null;
    
    notifyListeners();
  }
  
  /// 検尺から容量を計算
  Future<void> calculateCapacity() async {
    if (_selectedTank == null) {
      throw Exception('タンクを選択してください');
    }
    
    final measurement = double.tryParse(measurementController.text);
    if (measurement == null) {
      throw Exception('有効な検尺値を入力してください');
    }
    
    _isMeasurementCalculating = true;
    _capacityResult = null;
    notifyListeners();
    
    try {
      final result = await _tankDataService.calculateCapacity(_selectedTank!, measurement);
      _capacityResult = result;
    } catch (e) {
      throw Exception('計算中にエラーが発生しました: $e');
    } finally {
      _isMeasurementCalculating = false;
      notifyListeners();
    }
  }
  
  /// 容量から検尺を計算
  Future<void> calculateMeasurement() async {
    if (_selectedTank == null) {
      throw Exception('タンクを選択してください');
    }
    
    final capacity = double.tryParse(capacityController.text);
    if (capacity == null) {
      throw Exception('有効な容量を入力してください');
    }
    
    _isCapacityCalculating = true;
    _measurementResult = null;
    notifyListeners();
    
    try {
      final result = await _tankDataService.calculateMeasurement(_selectedTank!, capacity);
      _measurementResult = result;
    } catch (e) {
      throw Exception('計算中にエラーが発生しました: $e');
    } finally {
      _isCapacityCalculating = false;
      notifyListeners();
    }
  }
  
  /// フォームをリセット
  void resetForm() {
    measurementController.clear();
    capacityController.clear();
    _capacityResult = null;
    _measurementResult = null;
    notifyListeners();
  }
}
