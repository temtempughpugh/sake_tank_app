import 'package:flutter/material.dart';
import '../services/csv_service.dart';
import '../services/dilution_service.dart';
import '../models/dilution_result.dart';
import '../models/dilution_plan.dart';
import '../widgets/main_drawer.dart';
import '../models/tank_category.dart';

class DilutionCalculatorScreen extends StatefulWidget {
  final DilutionPlan? planToEdit; // 編集対象の計画（nullの場合は新規作成）
  
  const DilutionCalculatorScreen({Key? key, this.planToEdit}) : super(key: key);
  
  @override
  _DilutionCalculatorScreenState createState() => _DilutionCalculatorScreenState();
}

class _DilutionCalculatorScreenState extends State<DilutionCalculatorScreen> {
  final CsvService _csvService = CsvService();
  final DilutionService _dilutionService = DilutionService();
  
  List<String> _availableTanks = [];
  String? _selectedTank;
  bool _isLoading = true;
  bool _isEdit = false;
  String? _editPlanId;
  
  // Input controllers
  final TextEditingController _initialVolumeController = TextEditingController();
  final TextEditingController _measurementController = TextEditingController();
  final TextEditingController _initialAlcoholController = TextEditingController();
  final TextEditingController _targetAlcoholController = TextEditingController();
  final TextEditingController _sakeNameController = TextEditingController();
  final TextEditingController _personInChargeController = TextEditingController();
  
  // Result state
  DilutionResult? _dilutionResult;
  bool _isDilutionCalculating = false;
  double? _selectedFinalVolume;
  
  // Autofill states
  List<double> _volumeApproximations = [];
  List<double> _measurementApproximations = [];
  bool _isLoadingApproximations = false;
  bool _isLoadingMeasurementApproximations = false;
  bool _isUpdatingVolume = false;
  bool _isUpdatingMeasurement = false;
  
  @override
  void initState() {
    super.initState();
    _loadTanks();
    
    // Check if editing existing plan
    if (widget.planToEdit != null) {
      _isEdit = true;
      _editPlanId = widget.planToEdit!.id;
      _loadExistingPlanData();
    }
    
    // Add listeners for autofill
    _initialVolumeController.addListener(_findMeasurementFromVolume);
    _measurementController.addListener(_findVolumeFromMeasurement);
  }
  
  void _loadExistingPlanData() {
    final plan = widget.planToEdit!;
    
    // Will be set once tanks are loaded
    _selectedTank = plan.tankNumber;
    
    // Set form values
    _initialVolumeController.text = plan.initialVolume.toString();
    _measurementController.text = plan.initialMeasurement.toString();
    _initialAlcoholController.text = plan.initialAlcoholPercentage.toString();
    _targetAlcoholController.text = plan.targetAlcoholPercentage.toString();
    _sakeNameController.text = plan.sakeName;
    _personInChargeController.text = plan.personInCharge;
    
    // Calculate to show the result
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedTank != null) {
        _calculateDilution();
      }
    });
  }
  
  @override
  void dispose() {
    _initialVolumeController.dispose();
    _measurementController.dispose();
    _initialAlcoholController.dispose();
    _targetAlcoholController.dispose();
    _sakeNameController.dispose();
    _personInChargeController.dispose();
    super.dispose();
  }
  
  Future<void> _loadTanks() async {
  setState(() {
    _isLoading = true;
  });
  
  try {
    final tanks = await _csvService.getAvailableTankNumbers();
    setState(() {
      _availableTanks = tanks;
      
      // 蔵出しタンクを優先的に選択
     final releaseSourceTanks = tanks.where((tank) => 
  TankCategories.getCategoryForTank(tank).name == '蔵出しタンク').toList();

// 条件文も変更
if (_isEdit && widget.planToEdit != null) {
  _selectedTank = widget.planToEdit!.tankNumber;
} else if (releaseSourceTanks.isNotEmpty) {
  _selectedTank = releaseSourceTanks.first;
} else if (tanks.isNotEmpty) {
  _selectedTank = tanks.first;
}
      
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    _showErrorDialog('タンクデータの読み込みに失敗しました: $e');
  }
}
  
  // 計算関連のメソッド
  void _calculateVolumeFromMeasurement() async {
    if (_selectedTank == null) {
      _showErrorDialog('タンクを選択してください');
      return;
    }
    
    final measurement = double.tryParse(_measurementController.text);
    if (measurement == null) {
      _showErrorDialog('有効な検尺値（数値）を入力してください');
      return;
    }
    
    try {
      final result = await _csvService.calculateCapacity(_selectedTank!, measurement);
      if (result != null) {
        setState(() {
          _initialVolumeController.text = result.capacity.toStringAsFixed(1);
        });
      } else {
        _showErrorDialog('この検尺値に対応する容量データが見つかりません');
      }
    } catch (e) {
      _showErrorDialog('計算中にエラーが発生しました: $e');
    }
  }
  
  void _calculateMeasurementFromVolume() async {
    if (_selectedTank == null) {
      _showErrorDialog('タンクを選択してください');
      return;
    }
    
    final volume = double.tryParse(_initialVolumeController.text);
    if (volume == null) {
      _showErrorDialog('有効な容量（数値）を入力してください');
      return;
    }
    
    try {
      final result = await _csvService.calculateMeasurement(_selectedTank!, volume);
      if (result != null) {
        setState(() {
          _measurementController.text = result.measurement.toStringAsFixed(1);
        });
      } else {
        _showErrorDialog('この容量に対応する検尺データが見つかりません');
      }
    } catch (e) {
      _showErrorDialog('計算中にエラーが発生しました: $e');
    }
  }
  
  void _calculateDilution() async {
  if (_selectedTank == null) {
    _showErrorDialog('タンクを選択してください');
    return;
  }
  
  final initialVolume = double.tryParse(_initialVolumeController.text);
  if (initialVolume == null) {
    _showErrorDialog('有効な初期容量（数値）を入力してください');
    return;
  }
  
  final initialAlcohol = double.tryParse(_initialAlcoholController.text);
  if (initialAlcohol == null) {
    _showErrorDialog('有効な初期アルコール度数（数値）を入力してください');
    return;
  }
  
  final targetAlcohol = double.tryParse(_targetAlcoholController.text);
  if (targetAlcohol == null) {
    _showErrorDialog('有効な目標アルコール度数（数値）を入力してください');
    return;
  }
  
  if (targetAlcohol >= initialAlcohol) {
    _showErrorDialog('目標アルコール度数は初期アルコール度数より低くする必要があります');
    return;
  }
  
  // タンクの容量範囲をチェック
  try {
    // タンクの最大容量を取得
    final maxCapacity = await _csvService.getMaxCapacity(_selectedTank!);
    if (maxCapacity != null && initialVolume > maxCapacity) {
      _showErrorDialog('入力された容量(${initialVolume.toStringAsFixed(1)}L)はタンク${_selectedTank}の最大容量(${maxCapacity.toStringAsFixed(1)}L)を超えています');
      return;
    }
    
    // タンクのデータを取得して最小容量をチェック
    final tankData = await _csvService.getDataForTank(_selectedTank!);
    if (tankData.isNotEmpty) {
      tankData.sort((a, b) => a.capacity.compareTo(b.capacity));
      final minCapacity = tankData.first.capacity;
      
      if (initialVolume < minCapacity) {
        _showErrorDialog('入力された容量(${initialVolume.toStringAsFixed(1)}L)はタンク${_selectedTank}の最小容量(${minCapacity.toStringAsFixed(1)}L)未満です');
        return;
      }
    }
    
    // 計算結果により水を追加した後の容量が最大容量を超えないかチェック
    if (maxCapacity != null) {
      // 割水後の最終容量を仮計算
      final estimatedFinalVolume = initialVolume * (initialAlcohol / targetAlcohol);
      if (estimatedFinalVolume > maxCapacity) {
        _showErrorDialog('計算される割水後の容量(${estimatedFinalVolume.toStringAsFixed(1)}L)がタンク${_selectedTank}の最大容量(${maxCapacity.toStringAsFixed(1)}L)を超えています\n\n目標アルコール度数を下げるか、初期容量を減らしてください');
        return;
      }
    }
  } catch (e) {
    print('容量チェック中にエラーが発生しました: $e');
    // エラーが発生してもとりあえず計算は続行
  }
  
  setState(() {
    _isDilutionCalculating = true;
    _dilutionResult = null;
    _selectedFinalVolume = null;
  });
  
  try {
    final result = await _dilutionService.calculateDilution(
      tankNumber: _selectedTank!,
      initialVolume: initialVolume,
      initialAlcoholPercentage: initialAlcohol,
      targetAlcoholPercentage: targetAlcohol,
    );
    
    setState(() {
      _dilutionResult = result;
      _isDilutionCalculating = false;
    });
  } catch (e) {
    setState(() {
      _isDilutionCalculating = false;
    });
    _showErrorDialog('計算中にエラーが発生しました: $e');
  }
}
  
  // 最終容量を選択（近似値から）
  Future<void> _selectFinalVolume(double volume) async {
    if (_dilutionResult == null) return;
    
    final adjustedResult = await _dilutionService.adjustCalculation(_dilutionResult!, volume);
    
    setState(() {
      _selectedFinalVolume = volume;
      _dilutionResult = adjustedResult;
    });
  }
  
  // フォームリセット
  void _resetForm() {
    setState(() {
      _initialVolumeController.clear();
      _measurementController.clear();
      _initialAlcoholController.clear();
      _targetAlcoholController.clear();
      _sakeNameController.clear();
      _personInChargeController.clear();
      _dilutionResult = null;
      _selectedFinalVolume = null;
    });
  }
  
  // 割水計画を保存
  void _saveDilutionPlan() async {
    if (_selectedTank == null || _dilutionResult == null) {
      _showErrorDialog('タンクが選択されていないか、計算結果がありません');
      return;
    }
    
    final initialVolume = double.tryParse(_initialVolumeController.text);
    final initialMeasurement = double.tryParse(_measurementController.text);
    
    if (initialVolume == null) {
      _showErrorDialog('有効な初期容量が入力されていません');
      return;
    }
    
    // 編集時は既存IDを使用、新規作成時は新しいIDを生成
    final planId = _isEdit ? _editPlanId! : DateTime.now().millisecondsSinceEpoch.toString();
    
    final waterToAdd = _selectedFinalVolume != null 
        ? _dilutionResult!.adjustedWaterToAdd! 
        : _dilutionResult!.waterToAdd;
    
    final finalVolume = _selectedFinalVolume ?? _dilutionResult!.finalVolume;
    
    final actualAlcohol = _selectedFinalVolume != null 
        ? _dilutionResult!.adjustedAlcoholPercentage! 
        : _dilutionResult!.targetAlcoholPercentage;
    
    final plan = DilutionPlan(
      id: planId,
      tankNumber: _selectedTank!,
      initialVolume: initialVolume,
      initialMeasurement: initialMeasurement ?? 0,
      initialAlcoholPercentage: double.parse(_initialAlcoholController.text),
      targetAlcoholPercentage: actualAlcohol,
      waterToAdd: waterToAdd,
      finalVolume: finalVolume,
      finalMeasurement: _selectedFinalVolume != null 
          ? _dilutionResult!.adjustedFinalMeasurement! 
          : _dilutionResult!.finalMeasurement,
      sakeName: _sakeNameController.text,
      personInCharge: _personInChargeController.text,
      plannedDate: _isEdit && widget.planToEdit != null 
          ? widget.planToEdit!.plannedDate 
          : DateTime.now(),
      completionDate: _isEdit && widget.planToEdit != null 
          ? widget.planToEdit!.completionDate 
          : null,
      isCompleted: _isEdit && widget.planToEdit != null 
          ? widget.planToEdit!.isCompleted 
          : false,
    );
    
    try {
      await _dilutionService.saveDilutionPlan(plan);
      
      // 成功メッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? '割水計画を更新しました' : '割水計画を保存しました'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // 一覧画面に戻る
      Navigator.pop(context, true); // trueを渡して変更があったことを通知
    } catch (e) {
      _showErrorDialog('保存中にエラーが発生しました: $e');
    }
  }
  
  // 自動値入力関連メソッド
  void _findMeasurementFromVolume() {
    // 更新中なら処理しない（ループ防止）
    if (_isUpdatingMeasurement) return;
    
    if (_selectedTank == null || _initialVolumeController.text.isEmpty) {
      setState(() {
        _measurementApproximations = [];
      });
      return;
    }
    
    final volume = double.tryParse(_initialVolumeController.text);
    if (volume == null) return;
    
    setState(() {
      _isLoadingMeasurementApproximations = true;
    });
    
    // 遅延を入れて連続入力時に処理が重くならないようにする
    Future.delayed(Duration(milliseconds: 300), () async {
      try {
        // タンクデータを取得
        final tankData = await _csvService.getDataForTank(_selectedTank!);
        if (tankData.isEmpty) {
          setState(() {
            _isLoadingMeasurementApproximations = false;
            _measurementApproximations = [];
          });
          return;
        }
        
        // 最大・最小容量を取得
        tankData.sort((a, b) => a.capacity.compareTo(b.capacity));
        final minCapacity = tankData.first.capacity;
        final maxCapacity = tankData.last.capacity;
        
        // 容量が範囲外か確認
        if (volume < minCapacity || volume > maxCapacity) {
          setState(() {
            _isLoadingMeasurementApproximations = false;
            // 最も近い値を提案
            _measurementApproximations = [
              volume < minCapacity ? minCapacity : maxCapacity
            ];
          });
          return;
        }
        
        // 正確な一致を確認
        final exactMatch = tankData.where((data) => data.capacity == volume).toList();
        if (exactMatch.isNotEmpty) {
          // 更新中フラグをセット
          _isUpdatingMeasurement = true;
          
          setState(() {
            _measurementController.text = exactMatch.first.measurement.toString();
            _measurementApproximations = [];
            _isLoadingMeasurementApproximations = false;
          });
          
          // フラグをリセット
          Future.delayed(Duration(milliseconds: 100), () {
            _isUpdatingMeasurement = false;
          });
          return;
        }
        
        // 上下の近似値を探す（最大2つ）
        List<double> approximations = [];
        double? lowerApprox;
        double? upperApprox;
        
        for (int i = 0; i < tankData.length; i++) {
          if (tankData[i].capacity > volume) {
            if (i > 0) {
              lowerApprox = tankData[i - 1].capacity;
            }
            upperApprox = tankData[i].capacity;
            break;
          }
        }
        
        // 全てのデータがvolume以下の場合
        if (upperApprox == null && tankData.isNotEmpty) {
          lowerApprox = tankData.last.capacity;
        }
        
        if (lowerApprox != null) approximations.add(lowerApprox);
        if (upperApprox != null) approximations.add(upperApprox);
        
        setState(() {
          _measurementApproximations = approximations;
          _isLoadingMeasurementApproximations = false;
        });
      } catch (e) {
        setState(() {
          _isLoadingMeasurementApproximations = false;
          _measurementApproximations = [];
        });
      }
    });
  }
  
  void _findVolumeFromMeasurement() {
    // 更新中なら処理しない（ループ防止）
    if (_isUpdatingVolume) return;
    
    if (_selectedTank == null || _measurementController.text.isEmpty) {
      setState(() {
        _volumeApproximations = [];
      });
      return;
    }
    
    final measurement = double.tryParse(_measurementController.text);
    if (measurement == null) return;
    
    setState(() {
      _isLoadingApproximations = true;
    });
    
    // 遅延を入れて連続入力時に処理が重くならないようにする
    Future.delayed(Duration(milliseconds: 300), () async {
      try {
        // タンクデータを取得
        final tankData = await _csvService.getDataForTank(_selectedTank!);
        if (tankData.isEmpty) {
          setState(() {
            _isLoadingApproximations = false;
            _volumeApproximations = [];
          });
          return;
        }
        
        // 最大・最小検尺値を取得
        tankData.sort((a, b) => a.measurement.compareTo(b.measurement));
        final minMeasurement = tankData.first.measurement;
        final maxMeasurement = tankData.last.measurement;
        
        // 検尺値が範囲外か確認
        if (measurement < minMeasurement || measurement > maxMeasurement) {
          setState(() {
            _isLoadingApproximations = false;
            // 最も近い値を提案
            _volumeApproximations = [
              measurement < minMeasurement ? minMeasurement : maxMeasurement
            ];
          });
          return;
        }
        
        // 正確な一致を確認
        final exactMatch = tankData.where((data) => data.measurement == measurement).toList();
        if (exactMatch.isNotEmpty) {
          // 更新中フラグをセット
          _isUpdatingVolume = true;
          
          setState(() {
            _initialVolumeController.text = exactMatch.first.capacity.toString();
            _volumeApproximations = [];
            _isLoadingApproximations = false;
          });
          
          // フラグをリセット
          Future.delayed(Duration(milliseconds: 100), () {
            _isUpdatingVolume = false;
          });
          return;
        }
        
        // 上下の近似値を探す（最大2つ）
        List<double> approximations = [];
        double? lowerApprox;
        double? upperApprox;
        
        for (int i = 0; i < tankData.length; i++) {
          if (tankData[i].measurement > measurement) {
            if (i > 0) {
              lowerApprox = tankData[i - 1].measurement;
            }
            upperApprox = tankData[i].measurement;
            break;
          }
        }
        
        // 全てのデータがmeasurement以下の場合
        if (upperApprox == null && tankData.isNotEmpty) {
          lowerApprox = tankData.last.measurement;
        }
        
        if (lowerApprox != null) approximations.add(lowerApprox);
        if (upperApprox != null) approximations.add(upperApprox);
        
        setState(() {
          _volumeApproximations = approximations;
          _isLoadingApproximations = false;
        });
      } catch (e) {
        setState(() {
          _isLoadingApproximations = false;
          _volumeApproximations = [];
        });
      }
    });
  }
  
  void _selectVolumeApproximation(double measurement) async {
    try {
      final tankData = await _csvService.getDataForTank(_selectedTank!);
      final selectedData = tankData.firstWhere((data) => data.measurement == measurement);
      
      // 更新中フラグをセット（両方のフラグをセット）
      _isUpdatingVolume = true;
      _isUpdatingMeasurement = true;
      
      setState(() {
        _measurementController.text = selectedData.measurement.toString();
        _initialVolumeController.text = selectedData.capacity.toString();
        _volumeApproximations = [];
        _measurementApproximations = [];
      });
      
      // フラグをリセット
      Future.delayed(Duration(milliseconds: 100), () {
        _isUpdatingVolume = false;
        _isUpdatingMeasurement = false;
      });
    } catch (e) {
      _showErrorDialog('データの取得に失敗しました');
    }
  }
  
  void _selectMeasurementApproximation(double capacity) async {
    try {
      final tankData = await _csvService.getDataForTank(_selectedTank!);
      final selectedData = tankData.firstWhere((data) => data.capacity == capacity);
      
      // 更新中フラグをセット（両方のフラグをセット）
      _isUpdatingVolume = true;
      _isUpdatingMeasurement = true;
      
      setState(() {
        _initialVolumeController.text = selectedData.capacity.toString();
        _measurementController.text = selectedData.measurement.toString();
        _measurementApproximations = [];
        _volumeApproximations = [];
      });
      
      // フラグをリセット
      Future.delayed(Duration(milliseconds: 100), () {
        _isUpdatingVolume = false;
        _isUpdatingMeasurement = false;
      });
    } catch (e) {
      _showErrorDialog('データの取得に失敗しました');
    }
  }
  
  // 計算結果の近似値を制限し、上下2つまでに制限する
  List<double> _getLimitedNearestVolumes() {
    if (_dilutionResult == null || _dilutionResult!.nearestAvailableVolumes.isEmpty) {
      return [];
    }
    
    final targetVolume = _dilutionResult!.finalVolume;
    final allVolumes = _dilutionResult!.nearestAvailableVolumes;
    
    // 完全一致がある場合
    final exactMatch = allVolumes.contains(targetVolume);
    if (exactMatch) {
      // 完全一致を含む最大3つまでを表示
      final limitedVolumes = <double>[];
      
      // 一致よりも小さい値を1つ追加
      final smallerVolumes = allVolumes.where((v) => v < targetVolume).toList()
        ..sort((a, b) => (targetVolume - a).abs().compareTo((targetVolume - b).abs()));
      if (smallerVolumes.isNotEmpty) {
        limitedVolumes.add(smallerVolumes.first);
      }
      
      // 完全一致を追加
      limitedVolumes.add(targetVolume);
      
      // 一致よりも大きい値を1つ追加
      final largerVolumes = allVolumes.where((v) => v > targetVolume).toList()
        ..sort((a, b) => (a - targetVolume).abs().compareTo((b - targetVolume).abs()));
      if (largerVolumes.isNotEmpty) {
        limitedVolumes.add(largerVolumes.first);
      }
      
      return limitedVolumes;
    } else {
      // 完全一致がない場合は、最も近い上下の値を最大2つ表示
      allVolumes.sort((a, b) => (a - targetVolume).abs().compareTo((b - targetVolume).abs()));
      
      // 上下の近似値を取得
      double? lowerApprox;
      double? upperApprox;
      
      for (var volume in allVolumes) {
        if (volume < targetVolume) {
          // より近い下側の値を探す
          if (lowerApprox == null || (targetVolume - volume) < (targetVolume - lowerApprox)) {
            lowerApprox = volume;
          }
        } else if (volume > targetVolume) {
          // より近い上側の値を探す
          if (upperApprox == null || (volume - targetVolume) < (upperApprox - targetVolume)) {
            upperApprox = volume;
          }
        }
      }
      
      final result = <double>[];
      if (lowerApprox != null) result.add(lowerApprox);
      if (upperApprox != null) result.add(upperApprox);
      
      return result.length <= 2 ? result : result.sublist(0, 2);
    }
  }
  
  void _showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 8),
          Text('エラー', style: TextStyle(color: Colors.red)),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(_isEdit ? '割水計画を編集' : '割水計算'),
    ),
    endDrawer: MainDrawer(), // Add the shared drawer
    body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTankSelector(),
                  SizedBox(height: 16),
                  _buildInitialInfoCard(),
                  SizedBox(height: 16),
                  _buildAlcoholInfoCard(),
                  SizedBox(height: 16),
                  _buildOptionalInfoCard(),
                  SizedBox(height: 24),
                  _buildActionButtons(),
                  SizedBox(height: 24),
                  if (_isDilutionCalculating)
                    Center(child: CircularProgressIndicator())
                  else if (_dilutionResult != null)
                    _buildResultCard(),
                ],
              ),
            ),
          ),
  );
}

  
  Widget _buildTankSelector() {
  // Organize tanks into categories for selection
  List<DropdownMenuItem<String>> tankItems = [];
  
  // Define categories
  List<TankCategory> categories = TankCategories.getCategories();
  
  // Map of tanks by category
  Map<String, List<String>> tanksByCategory = {};
  
  // Initialize categories
  for (var category in categories) {
    tanksByCategory[category.name] = [];
  }
  
  // Assign tanks to categories
  for (var tank in _availableTanks) {
    bool assigned = false;
    
    for (var category in categories.where((c) => c.name != 'その他')) {
      if (category.tankNumbers.contains(tank)) {
        tanksByCategory[category.name]!.add(tank);
        assigned = true;
        break;
      }
    }
    
    if (!assigned) {
      // Add to "Others" category
      tanksByCategory['その他']!.add(tank);
    }
  }
  
  // Build dropdown items with categories
  for (var category in categories) {
    var tanksInCategory = tanksByCategory[category.name] ?? [];
    
    // Skip empty categories
    if (tanksInCategory.isEmpty) continue;
    
    // タンク番号を数値順にソート
    tanksInCategory.sort((a, b) {
      // 特殊タンク名は最後に
      bool aIsSpecial = a == '仕込水タンク';
      bool bIsSpecial = b == '仕込水タンク';
        
      if (aIsSpecial && !bIsSpecial) return 1;
      if (!aIsSpecial && bIsSpecial) return -1;
        
      // No.プレフィックスを一時的に削除して数値比較
      String aNum = a.replaceAll(RegExp(r'No\.'), '').trim();
      String bNum = b.replaceAll(RegExp(r'No\.'), '').trim();
        
      // 数値に変換して比較
      int? aInt = int.tryParse(aNum);
      int? bInt = int.tryParse(bNum);
        
      if (aInt != null && bInt != null) {
        return aInt.compareTo(bInt);
      }
        
      // 数値変換できなければ文字列比較
      return a.compareTo(b);
    });
    
    // Add category header
    tankItems.add(
      DropdownMenuItem<String>(
        enabled: false,
        child: Text(
          category.name,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        value: 'header_${category.name}',
      )
    );
    
    // Add tanks in this category
    for (var tank in tanksInCategory) {
      bool isLessProminent = TankCategories.isLessProminentTank(tank);
      
      tankItems.add(
        DropdownMenuItem<String>(
          value: tank,
          child: Text(
            tank, // 元のタンク番号表記をそのまま使用
            style: TextStyle(
              color: isLessProminent ? Colors.grey : Colors.black,
              fontStyle: isLessProminent ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        )
      );
    }
    
    // Add divider if not the last category
    if (category != categories.last) {
      tankItems.add(
        DropdownMenuItem<String>(
          enabled: false,
          child: Divider(height: 1),
          value: 'divider_${category.name}',
        )
      );
    }
  }
  
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'タンク選択',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedTank,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'タンク番号',
              hintText: 'タンクを選択してください',
              prefixIcon: Icon(Icons.wine_bar),
            ),
            items: tankItems,
            onChanged: (value) {
              setState(() {
                _selectedTank = value;
                // リセット
                _dilutionResult = null;
              });
            },
          ),
        ],
      ),
    ),
  );
}
  
  Widget _buildInitialInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '現在の状態',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _initialVolumeController,
                        decoration: InputDecoration(
                          labelText: '現在の容量（L）',
                          hintText: '例: 3000',
                          prefixIcon: Icon(Icons.water_drop),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      if (_isLoadingMeasurementApproximations)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('近似値を検索中...', 
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        )
                      else if (_measurementApproximations.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Wrap(
                            spacing: 8,
                            children: [
                              Text('近似値: ', 
                                style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                              ..._measurementApproximations.map((capacity) => 
                                InkWell(
                                  onTap: () => _selectMeasurementApproximation(capacity),
                                  child: Chip(
                                    label: Text('${capacity.toStringAsFixed(1)}L'),
                                    labelStyle: TextStyle(fontSize: 12),
                                    backgroundColor: Colors.blue[50],
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                )
                              ).toList(),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _measurementController,
                        decoration: InputDecoration(
                          labelText: '現在の検尺（mm）',
                          hintText: '例: 1250',
                          prefixIcon: Icon(Icons.straighten),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      if (_isLoadingApproximations)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('近似値を検索中...', 
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        )
                      else if (_volumeApproximations.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Wrap(
                            spacing: 8,
                            children: [
                              Text('近似値: ', 
                                style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                              ..._volumeApproximations.map((measurement) => 
                                InkWell(
                                  onTap: () => _selectVolumeApproximation(measurement),
                                  child: Chip(
                                    label: Text('${measurement.toStringAsFixed(1)}mm'),
                                    labelStyle: TextStyle(fontSize: 12),
                                    backgroundColor: Colors.green[50],
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                )
                              ).toList(),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                icon: Icon(Icons.sync, size: 16),
                label: Text('容量と検尺を更新'),
                onPressed: () {
                  if (_initialVolumeController.text.isNotEmpty) {
                    _calculateMeasurementFromVolume();
                  } else if (_measurementController.text.isNotEmpty) {
                    _calculateVolumeFromMeasurement();
                  } else {
                    _showErrorDialog('容量または検尺を入力してください');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAlcoholInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'アルコール度数',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _initialAlcoholController,
                    decoration: InputDecoration(
                      labelText: '現在のアルコール度数（%）',
                      hintText: '例: 18.5',
                      prefixIcon: Icon(Icons.percent),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _targetAlcoholController,
                    decoration: InputDecoration(
                      labelText: '目標アルコール度数（%）',
                      hintText: '例: 15.5',
                      prefixIcon: Icon(Icons.arrow_downward),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOptionalInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '追加情報（オプション）',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _sakeNameController,
              decoration: InputDecoration(
                labelText: 'お酒の名前',
                hintText: '例: 純米大吟醸 X',
                prefixIcon: Icon(Icons.local_bar),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _personInChargeController,
              decoration: InputDecoration(
                labelText: '担当者',
                hintText: '例: 田中',
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(Icons.calculate),
            label: Text('割水計算'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _isDilutionCalculating ? null : _calculateDilution,
          ),
        ),
        SizedBox(width: 8),
        OutlinedButton.icon(
          icon: Icon(Icons.clear),
          label: Text('クリア'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: _resetForm,
        ),
      ],
    );
  }
  
  Widget _buildResultCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '計算結果', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                if (!_dilutionResult!.isExactMatch)
                  Chip(
                    label: Text('近似値'),
                    backgroundColor: Colors.orange[100],
                  ),
              ],
            ),
            Divider(),
            
            // 結果テーブル
            _buildResultRow('タンク番号:', '$_selectedTank'),
            _buildResultRow('現在の容量:', '${_dilutionResult!.initialVolume.toStringAsFixed(1)} L'),
            _buildResultRow(
              '追加する水量:',
              _selectedFinalVolume != null
                ? '${_dilutionResult!.adjustedWaterToAdd!.toStringAsFixed(1)} L'
                : '${_dilutionResult!.waterToAdd.toStringAsFixed(1)} L',
              highlight: true,
            ),
            _buildResultRow(
              '割水後の合計容量:',
              _selectedFinalVolume != null
                ? '${_selectedFinalVolume!.toStringAsFixed(1)} L'
                : '${_dilutionResult!.finalVolume.toStringAsFixed(1)} L'
            ),
            _buildResultRow(
              '割水後の検尺:',
              _selectedFinalVolume != null
                ? '${_dilutionResult!.adjustedFinalMeasurement!.toStringAsFixed(1)} mm'
                : '${_dilutionResult!.finalMeasurement.toStringAsFixed(1)} mm'
            ),
            _buildResultRow(
              '実際のアルコール度数:',
              _selectedFinalVolume != null
                ? '${_dilutionResult!.adjustedAlcoholPercentage!.toStringAsFixed(2)} %'
                : '${_dilutionResult!.targetAlcoholPercentage.toStringAsFixed(2)} %',
              warning: _selectedFinalVolume != null &&
                      (_dilutionResult!.adjustedAlcoholPercentage! - _dilutionResult!.targetAlcoholPercentage).abs() > 0.1
            ),
            
            // 近似値選択（データに正確な値がない場合）
            if (!_dilutionResult!.isExactMatch && _dilutionResult!.nearestAvailableVolumes.isNotEmpty) ...[
              Divider(),
              Text(
                '近似値を選択:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '計算された合計容量（${_dilutionResult!.finalVolume.toStringAsFixed(1)} L）に最も近い利用可能な値を選択できます。これにより、実際の割水量とアルコール度数が調整されます。',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _getLimitedNearestVolumes().map((volume) {
                  final isSelected = _selectedFinalVolume == volume;
                  final isExactMatch = volume == _dilutionResult!.finalVolume;
                  
                  // 対応する検尺値を取得
                  String measurementText = '';
                  for (var pair in _dilutionResult!.nearestAvailablePairs) {
                    if (pair['capacity'] == volume) {
                      measurementText = ' (${pair['measurement']!.toStringAsFixed(1)}mm)';
                      break;
                    }
                  }
                  
                  return ChoiceChip(
                    label: Text('${volume.toStringAsFixed(1)}L${measurementText}'),
                    selected: isSelected,
                    selectedColor: isExactMatch ? Colors.green[100] : Colors.blue[100],
                    backgroundColor: isExactMatch ? Colors.green[50] : null,
                    avatar: isExactMatch ? Icon(Icons.check, size: 16, color: Colors.green[800]) : null,
                    onSelected: (selected) {
                      if (selected) {
                        _selectFinalVolume(volume);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
            
            SizedBox(height: 24),
            
            // 保存ボタン
            ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text(_isEdit ? '計画を更新' : '計画を登録'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                minimumSize: Size(double.infinity, 0), // 幅いっぱい
              ),
              onPressed: _saveDilutionPlan,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultRow(String label, String value, {bool highlight = false, bool warning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: highlight ? 20 : 16,
              color: warning 
                ? Colors.orange[700]
                : highlight 
                  ? Theme.of(context).primaryColor
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}