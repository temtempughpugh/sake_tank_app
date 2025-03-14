import 'package:flutter/material.dart';
import '../services/csv_service.dart';
import '../services/dilution_service.dart';
import '../models/tank_data.dart';
import '../models/measurement_result.dart';
import '../models/dilution_result.dart';
import '../models/dilution_plan.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final CsvService _csvService = CsvService();
  final DilutionService _dilutionService = DilutionService();
  List<String> _availableTanks = [];
  String? _selectedTank;
  bool _isLoading = true;
  late TabController _tabController;
  
  // 検尺タブの状態管理
  final TextEditingController _measurementController = TextEditingController();
  MeasurementResult? _capacityResult;
  bool _isMeasurementCalculating = false;
  
  // 容量タブの状態管理
  final TextEditingController _capacityController = TextEditingController();
  MeasurementResult? _measurementResult;
  bool _isCapacityCalculating = false;

  // 容量入力から近似値を表示
  List<double> _volumeApproximations = [];
  bool _isLoadingApproximations = false;
  bool _isUpdatingVolume = false;
bool _isUpdatingMeasurement = false;
  
  // 検尺入力から近似値を表示
  List<double> _measurementApproximations = [];
  bool _isLoadingMeasurementApproximations = false;

  // 割水タブの状態管理
  final TextEditingController _dilutionInitialVolumeController = TextEditingController();
  final TextEditingController _dilutionMeasurementController = TextEditingController();
  final TextEditingController _initialAlcoholController = TextEditingController();
  final TextEditingController _targetAlcoholController = TextEditingController();
  final TextEditingController _sakeNameController = TextEditingController();
  final TextEditingController _personInChargeController = TextEditingController();
  
  // 割水計算の状態
  DilutionResult? _dilutionResult;
  bool _isDilutionCalculating = false;
  double? _selectedFinalVolume;
  List<DilutionPlan> _savedPlans = [];
  bool _isLoadingPlans = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3タブに変更
    _loadTanks();
    _loadSavedPlans();
    
    // 容量入力時に自動的に検尺値を探す
    _dilutionInitialVolumeController.addListener(_findMeasurementFromVolume);
    
    // 検尺入力時に自動的に容量を探す
    _dilutionMeasurementController.addListener(_findVolumeFromMeasurement);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _measurementController.dispose();
    _capacityController.dispose();
    _dilutionInitialVolumeController.dispose();
    _dilutionMeasurementController.dispose();
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
        _isLoading = false;
        if (tanks.isNotEmpty) {
          _selectedTank = tanks.first;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('タンクデータの読み込みに失敗しました: $e');
    }
  }
  
  // 保存された割水計画を読み込む
  Future<void> _loadSavedPlans() async {
    setState(() {
      _isLoadingPlans = true;
    });
    
    try {
      final plans = await _dilutionService.getAllDilutionPlans();
      setState(() {
        _savedPlans = plans;
        _isLoadingPlans = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPlans = false;
      });
      _showErrorDialog('計画データの読み込みに失敗しました: $e');
    }
  }
  
  // 割水フォームをリセット
  void _resetDilutionForm() {
    setState(() {
      _dilutionInitialVolumeController.clear();
      _dilutionMeasurementController.clear();
      _initialAlcoholController.clear();
      _targetAlcoholController.clear();
      _sakeNameController.clear();
      _personInChargeController.clear();
      _dilutionResult = null;
      _selectedFinalVolume = null;
    });
  }
  
  // 検尺から容量を計算（割水タブ用）
  void _calculateVolumeFromMeasurement() async {
    if (_selectedTank == null) {
      _showErrorDialog('タンクを選択してください');
      return;
    }
    
    final measurement = double.tryParse(_dilutionMeasurementController.text);
    if (measurement == null) {
      _showErrorDialog('有効な検尺値（数値）を入力してください');
      return;
    }
    
    try {
      final result = await _csvService.calculateCapacity(_selectedTank!, measurement);
      if (result != null) {
        setState(() {
          _dilutionInitialVolumeController.text = result.capacity.toStringAsFixed(1);
        });
      } else {
        _showErrorDialog('この検尺値に対応する容量データが見つかりません');
      }
    } catch (e) {
      _showErrorDialog('計算中にエラーが発生しました: $e');
    }
  }
  
  // 容量から検尺を計算（割水タブ用）
  void _calculateMeasurementFromVolume() async {
    if (_selectedTank == null) {
      _showErrorDialog('タンクを選択してください');
      return;
    }
    
    final volume = double.tryParse(_dilutionInitialVolumeController.text);
    if (volume == null) {
      _showErrorDialog('有効な容量（数値）を入力してください');
      return;
    }
    
    try {
      final result = await _csvService.calculateMeasurement(_selectedTank!, volume);
      if (result != null) {
        setState(() {
          _dilutionMeasurementController.text = result.measurement.toStringAsFixed(1);
        });
      } else {
        _showErrorDialog('この容量に対応する検尺データが見つかりません');
      }
    } catch (e) {
      _showErrorDialog('計算中にエラーが発生しました: $e');
    }
  }
  
  // 割水計算
  void _calculateDilution() async {
    if (_selectedTank == null) {
      _showErrorDialog('タンクを選択してください');
      return;
    }
    
    final initialVolume = double.tryParse(_dilutionInitialVolumeController.text);
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
  
  // 割水計画を保存
  void _saveDilutionPlan() async {
    if (_selectedTank == null || _dilutionResult == null) {
      _showErrorDialog('タンクが選択されていないか、計算結果がありません');
      return;
    }
    
    final initialVolume = double.tryParse(_dilutionInitialVolumeController.text);
    final initialMeasurement = double.tryParse(_dilutionMeasurementController.text);
    
    if (initialVolume == null) {
      _showErrorDialog('有効な初期容量が入力されていません');
      return;
    }
    
    // 一意のIDをタイムスタンプで作成
    final planId = DateTime.now().millisecondsSinceEpoch.toString();
    
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
      finalMeasurement: _dilutionResult!.finalMeasurement,
      sakeName: _sakeNameController.text,
      personInCharge: _personInChargeController.text,
      plannedDate: DateTime.now(),
    );
    
    try {
      await _dilutionService.saveDilutionPlan(plan);
      
      // 計画リストを更新
      await _loadSavedPlans();
      
      // 成功メッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('割水計画を保存しました')),
      );
      
      // フォームをリセット
      _resetDilutionForm();
    } catch (e) {
      _showErrorDialog('保存中にエラーが発生しました: $e');
    }
  }
  
  // 割水計画を完了としてマーク
  void _completeDilutionPlan(String planId) async {
    try {
      await _dilutionService.completePlan(planId);
      await _loadSavedPlans();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('割水作業を完了しました')),
      );
    } catch (e) {
      _showErrorDialog('完了処理中にエラーが発生しました: $e');
    }
  }
  
  // 保存された計画をフォームに読み込む
  void _loadPlan(DilutionPlan plan) {
    setState(() {
      _selectedTank = plan.tankNumber;
      _dilutionInitialVolumeController.text = plan.initialVolume.toString();
      _dilutionMeasurementController.text = plan.initialMeasurement.toString();
      _initialAlcoholController.text = plan.initialAlcoholPercentage.toString();
      _targetAlcoholController.text = plan.targetAlcoholPercentage.toString();
      _sakeNameController.text = plan.sakeName;
      _personInChargeController.text = plan.personInCharge;
      
      // 計算を実行して結果を更新
      _calculateDilution();
    });
  }
  // 容量入力から自動的に近似値を探す
  // 容量入力から自動的に近似値を探す
// 容量入力から自動的に近似値を探す
// 容量入力から自動的に近似値を探す
void _findMeasurementFromVolume() {
  // 更新中なら処理しない（ループ防止）
  if (_isUpdatingMeasurement) return;
  
  if (_selectedTank == null || _dilutionInitialVolumeController.text.isEmpty) {
    setState(() {
      _measurementApproximations = [];
    });
    return;
  }
  
  final volume = double.tryParse(_dilutionInitialVolumeController.text);
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
          _dilutionMeasurementController.text = exactMatch.first.measurement.toString();
          _measurementApproximations = [];
          _isLoadingMeasurementApproximations = false;
        });
        
        // フラグをリセット
        Future.delayed(Duration(milliseconds: 100), () {
          _isUpdatingMeasurement = false;
        });
        return;
      }
      
      // 上下の近似値を探す
      // 一致するものがない場合は近似値を最大2つ表示
      List<TankData> approximations = [];
      TankData? lowerApprox;
      TankData? upperApprox;
      
      for (var data in tankData) {
        if (data.capacity < volume) {
          lowerApprox = data;
        } else if (data.capacity > volume) {
          upperApprox = data;
          break;
        }
      }
      
      if (lowerApprox != null) approximations.add(lowerApprox);
      if (upperApprox != null) approximations.add(upperApprox);
      
      setState(() {
        _measurementApproximations = approximations.map((data) => data.capacity).toList();
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

// 検尺入力から自動的に近似値を探す
// 検尺入力から自動的に近似値を探す
void _findVolumeFromMeasurement() {
  // 更新中なら処理しない（ループ防止）
  if (_isUpdatingVolume) return;
  
  if (_selectedTank == null || _dilutionMeasurementController.text.isEmpty) {
    setState(() {
      _volumeApproximations = [];
    });
    return;
  }
  
  final measurement = double.tryParse(_dilutionMeasurementController.text);
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
          _dilutionInitialVolumeController.text = exactMatch.first.capacity.toString();
          _volumeApproximations = [];
          _isLoadingApproximations = false;
        });
        
        // フラグをリセット
        Future.delayed(Duration(milliseconds: 100), () {
          _isUpdatingVolume = false;
        });
        return;
      }
      
      // 上下の近似値を探す
      // 一致するものがない場合は近似値を最大2つ表示
      List<TankData> approximations = [];
      TankData? lowerApprox;
      TankData? upperApprox;
      
      for (var data in tankData) {
        if (data.measurement < measurement) {
          lowerApprox = data;
        } else if (data.measurement > measurement) {
          upperApprox = data;
          break;
        }
      }
      
      if (lowerApprox != null) approximations.add(lowerApprox);
      if (upperApprox != null) approximations.add(upperApprox);
      
      setState(() {
        _volumeApproximations = approximations.map((data) => data.measurement).toList();
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
  
  // 容量の近似値を選択
void _selectVolumeApproximation(double measurement) async {
  try {
    final tankData = await _csvService.getDataForTank(_selectedTank!);
    final selectedData = tankData.firstWhere((data) => data.measurement == measurement);
    
    // 更新中フラグをセット（両方のフラグをセット）
    _isUpdatingVolume = true;
    _isUpdatingMeasurement = true;
    
    setState(() {
      _dilutionMeasurementController.text = selectedData.measurement.toString();
      _dilutionInitialVolumeController.text = selectedData.capacity.toString();
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

// 検尺の近似値を選択
void _selectMeasurementApproximation(double capacity) async {
  try {
    final tankData = await _csvService.getDataForTank(_selectedTank!);
    final selectedData = tankData.firstWhere((data) => data.capacity == capacity);
    
    // 更新中フラグをセット（両方のフラグをセット）
    _isUpdatingVolume = true;
    _isUpdatingMeasurement = true;
    
    setState(() {
      _dilutionInitialVolumeController.text = selectedData.capacity.toString();
      _dilutionMeasurementController.text = selectedData.measurement.toString();
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
      
      return _dilutionResult!.nearestAvailableVolumes;
}
  }
  void _calculateCapacity() async {
    if (_selectedTank == null) {
      _showErrorDialog('タンクを選択してください');
      return;
    }
    
    final measurement = double.tryParse(_measurementController.text);
    if (measurement == null) {
      _showErrorDialog('有効な検尺値（数値）を入力してください');
      return;
    }
    
    setState(() {
      _isMeasurementCalculating = true;
      _capacityResult = null;
    });
    
    try {
      final result = await _csvService.calculateCapacity(_selectedTank!, measurement);
      setState(() {
        _capacityResult = result;
        _isMeasurementCalculating = false;
      });
    } catch (e) {
      setState(() {
        _isMeasurementCalculating = false;
      });
      _showErrorDialog('計算中にエラーが発生しました: $e');
    }
  }
  
  void _calculateMeasurement() async {
    if (_selectedTank == null) {
      _showErrorDialog('タンクを選択してください');
      return;
    }
    
    final capacity = double.tryParse(_capacityController.text);
    if (capacity == null) {
      _showErrorDialog('有効な容量（数値）を入力してください');
      return;
    }
    
    setState(() {
      _isCapacityCalculating = true;
      _measurementResult = null;
    });
    
    try {
      final result = await _csvService.calculateMeasurement(_selectedTank!, capacity);
      setState(() {
        _measurementResult = result;
        _isCapacityCalculating = false;
      });
    } catch (e) {
      setState(() {
        _isCapacityCalculating = false;
      });
      _showErrorDialog('計算中にエラーが発生しました: $e');
    }
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('エラー'),
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
        title: Text('日本酒タンク管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.arrow_downward), text: '検尺から容量'),
            Tab(icon: Icon(Icons.arrow_upward), text: '容量から検尺'),
            Tab(icon: Icon(Icons.water_drop), text: '割水計算'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.assignment),
            tooltip: '割水計画一覧',
            onPressed: () {
              Navigator.pushNamed(context, '/dilution-plans').then((_) {
                // 画面から戻ってきたら計画を再読み込み
                _loadSavedPlans();
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // タンク選択部分
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.grey[200],
                  child: Row(
                    children: [
                      Text('タンク番号: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedTank,
                          isExpanded: true,
                          hint: Text('タンクを選択'),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedTank = newValue;
                              // 選択変更時にリセット
                              _capacityResult = null;
                              _measurementResult = null;
                              _dilutionResult = null;
                            });
                          },
                          items: _availableTanks.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // タブ内容
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // 検尺から容量を計算するタブ
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'タンク上部からの距離（検尺値）を入力して、タンク内の容量を計算します',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: TextField(
                                    controller: _measurementController,
                                    decoration: InputDecoration(
                                      labelText: '検尺値（mm）',
                                      border: OutlineInputBorder(),
                                      hintText: '例: 1250',
                                      helperText: 'タンク上部からの距離をmmで入力',
                                    ),
                                    keyboardType: TextInputType.number,
                                    onSubmitted: (_) => _calculateCapacity(),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: ElevatedButton(
                                    onPressed: _isMeasurementCalculating ? null : _calculateCapacity,
                                    child: _isMeasurementCalculating
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : Text('計算'),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24),
                            if (_capacityResult == null && !_isMeasurementCalculating) ...[
                              // 結果がまだない場合は何も表示しない
                            ] else if (_capacityResult == null) ...[
                              Card(
                                elevation: 4,
                                color: Colors.red[50],
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text(
                                            'データが見つかりません',
                                            style: TextStyle(
                                              fontSize: 18, 
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '入力された検尺値に対応するデータが存在しません。',
                                        style: TextStyle(color: Colors.red[800]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else if (_capacityResult!.isOverLimit) ...[
                              Card(
                                elevation: 4,
                                color: Colors.red[50],
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text(
                                            '検尺上限を越えています',
                                            style: TextStyle(
                                              fontSize: 18, 
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '入力された検尺値（${_measurementController.text} mm）はこのタンクの上限を超えています。',
                                        style: TextStyle(color: Colors.red[800]),
                                      ),
                                      Text(
                                        '有効な範囲内の検尺値を入力してください。',
                                        style: TextStyle(color: Colors.red[800]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              Card(
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('計算結果', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      Divider(),
                                      if (!_capacityResult!.isExactMatch) ...[
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Text(
                                            '指定した検尺値に正確にマッチするデータがないため、近似値を表示しています',
                                            style: TextStyle(color: Colors.orange, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('タンク番号:'),
                                          Text('$_selectedTank', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('検尺:'),
                                          Text('${_measurementController.text} mm', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('容量:'),
                                          Text('${_capacityResult!.capacity.toStringAsFixed(1)} L', 
                                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // 容量から検尺を計算するタブ（逆引き）
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '必要な容量を入力して、対応する検尺値（タンク上部からの距離）を計算します',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: TextField(
                                    controller: _capacityController,
                                    decoration: InputDecoration(
                                      labelText: '容量（L）',
                                      border: OutlineInputBorder(),
                                      hintText: '例: 2500',
                                      helperText: 'リットル単位で入力',
                                    ),
                                    keyboardType: TextInputType.number,
                                    onSubmitted: (_) => _calculateMeasurement(),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: ElevatedButton(
                                    onPressed: _isCapacityCalculating ? null : _calculateMeasurement,
                                    child: _isCapacityCalculating
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : Text('計算'),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24),
                            if (_measurementResult == null && !_isCapacityCalculating) ...[
                              // 結果がまだない場合は何も表示しない
                            ] else if (_measurementResult == null) ...[
                              Card(
                                elevation: 4,
                                color: Colors.red[50],
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text(
                                            'データが見つかりません',
                                            style: TextStyle(
                                              fontSize: 18, 
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '入力された容量に対応するデータが存在しません。',
                                        style: TextStyle(color: Colors.red[800]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else if (_measurementResult!.isOverCapacity) ...[
                              Card(
                                elevation: 4,
                                color: Colors.red[50],
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text(
                                            '容量をオーバーしています',
                                            style: TextStyle(
                                              fontSize: 18, 
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '入力された容量（${_capacityController.text} L）はこのタンクの最大容量を超えています。',
                                        style: TextStyle(color: Colors.red[800]),
                                      ),
                                      Text(
                                        '最大容量: ${_measurementResult!.capacity.toStringAsFixed(1)} L（検尺: ${_measurementResult!.measurement.toStringAsFixed(1)} mm）',
                                        style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '検尺が0の時が最大容量です。これ以上の逆引きはできません。',
                                        style: TextStyle(color: Colors.red[800]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else if (_measurementResult!.isOverLimit) ...[
                              Card(
                                elevation: 4,
                                color: Colors.red[50],
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text(
                                            '検尺上限を越えています',
                                            style: TextStyle(
                                              fontSize: 18, 
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '入力された容量（${_capacityController.text} L）に対応する検尺値はこのタンクの上限を超えています。',
                                        style: TextStyle(color: Colors.red[800]),
                                      ),
                                      Text(
                                        '最小容量: ${_measurementResult!.capacity.toStringAsFixed(1)} L（検尺: ${_measurementResult!.measurement.toStringAsFixed(1)} mm）',
                                        style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              Card(
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('計算結果', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      Divider(),
                                      if (!_measurementResult!.isExactMatch) ...[
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Text(
                                            '指定した容量に正確にマッチするデータがないため、近似値を表示しています',
                                            style: TextStyle(color: Colors.orange, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('タンク番号:'),
                                          Text('$_selectedTank', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('希望容量:'),
                                          Text('${_capacityController.text} L', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      if (!_measurementResult!.isExactMatch) ...[
                                        SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('実際の容量:'),
                                            Text('${_measurementResult!.capacity.toStringAsFixed(1)} L', 
                                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800]),
                                            ),
                                          ],
                                        ),
                                      ],
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('必要な検尺:'),
                                          Text('${_measurementResult!.measurement.toStringAsFixed(1)} mm', 
                                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // 新しい割水計算タブ
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'お酒への割水計算：アルコール度数を調整するための計算を行います',
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 16),
                              
                              // 初期情報入力カード
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('現在の状態', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      SizedBox(height: 8),
                                      
                                      // 容量と検尺の入力
                                      // 容量と検尺の入力
                                      // 容量と検尺の入力
Row(
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _dilutionInitialVolumeController,
            decoration: InputDecoration(
              labelText: '現在の容量（L）',
              hintText: '例: 3000',
            ),
            keyboardType: TextInputType.number,
          ),
          if (_isLoadingMeasurementApproximations)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text('近似値を検索中...', style: TextStyle(fontSize: 12, color: Colors.grey)),
            )
          else if (_measurementApproximations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Wrap(
                spacing: 8,
                children: [
                  Text('近似値: ', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
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
            controller: _dilutionMeasurementController,
            decoration: InputDecoration(
              labelText: '現在の検尺（mm）',
              hintText: '例: 1250',
            ),
            keyboardType: TextInputType.number,
          ),
          if (_isLoadingApproximations)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text('近似値を検索中...', style: TextStyle(fontSize: 12, color: Colors.grey)),
            )
          else if (_volumeApproximations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Wrap(
                spacing: 8,
                children: [
                  Text('近似値: ', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
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
                                      SizedBox(height: 16),
                                      
                              // アルコール度数の入力
                                      // アルコール度数の入力
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _initialAlcoholController,
                                              decoration: InputDecoration(
                                                labelText: '現在のアルコール度数（%）',
                                                hintText: '例: 18.5',
                                              ),
                                              keyboardType: TextInputType.number,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Icon(Icons.arrow_forward, color: Colors.blue),
                                          ),
                                          Expanded(
                                            child: TextField(
                                              controller: _targetAlcoholController,
                                              decoration: InputDecoration(
                                                labelText: '目標アルコール度数（%）',
                                                hintText: '例: 15.5',
                                              ),
                                              keyboardType: TextInputType.number,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: 16),
                              
                              // 追加情報カード
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('追加情報（オプション）', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      SizedBox(height: 8),
                                      
                                      TextField(
                                        controller: _sakeNameController,
                                        decoration: InputDecoration(
                                          labelText: 'お酒の名前',
                                          hintText: '例: 純米大吟醸 X',
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      
                                      TextField(
                                        controller: _personInChargeController,
                                        decoration: InputDecoration(
                                          labelText: '担当者',
                                          hintText: '例: 田中',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: 16),
                              
                              // アクションボタン
                              Row(
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
                                    onPressed: _resetDilutionForm,
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 24),
                              
                              // 計算結果表示
                              if (_isDilutionCalculating) ...[
                                Center(child: CircularProgressIndicator()),
                              ] else if (_dilutionResult != null) ...[
                                Card(
                                  elevation: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('計算結果', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                            if (!_dilutionResult!.isExactMatch)
                                              Chip(
                                                label: Text('近似値'),
                                                backgroundColor: Colors.orange[100],
                                              ),
                                          ],
                                        ),
                                        Divider(),
                                        
                                        // 結果テーブル
                                        Table(
                                          columnWidths: {
                                            0: FlexColumnWidth(1.2),
                                            1: FlexColumnWidth(0.8),
                                          },
                                          children: [
                                            TableRow(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                  child: Text('タンク番号:'),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                  child: Text(
                                                    '$_selectedTank',
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            TableRow(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                  child: Text('現在の容量:'),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                  child: Text(
                                                    '${_dilutionResult!.initialVolume.toStringAsFixed(1)} L',
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            TableRow(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                  child: Text('追加する水量:'),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                  child: Text(
                                                    _selectedFinalVolume != null
                                                      ? '${_dilutionResult!.adjustedWaterToAdd!.toStringAsFixed(1)} L'
                                                      : '${_dilutionResult!.waterToAdd.toStringAsFixed(1)} L',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18,
                                                      color: Theme.of(context).primaryColor,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            TableRow(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                  child: Text('割水後の合計容量:'),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                  child: Text(
                                                    _selectedFinalVolume != null
                                                      ? '${_selectedFinalVolume!.toStringAsFixed(1)} L'
                                                      : '${_dilutionResult!.finalVolume.toStringAsFixed(1)} L',
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            TableRow(
  children: [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text('割水後の検尺:'),
    ),
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        _selectedFinalVolume != null
          ? '${_dilutionResult!.adjustedFinalMeasurement!.toStringAsFixed(1)} mm'
          : '${_dilutionResult!.finalMeasurement.toStringAsFixed(1)} mm',
        style: TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.right,
      ),
    ),
  ],
),
                                            TableRow(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                  child: Text('実際のアルコール度数:'),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                  child: Text(
                                                    _selectedFinalVolume != null
                                                      ? '${_dilutionResult!.adjustedAlcoholPercentage!.toStringAsFixed(2)} %'
                                                      : '${_dilutionResult!.targetAlcoholPercentage.toStringAsFixed(2)} %',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: _selectedFinalVolume != null &&
                                                              (_dilutionResult!.adjustedAlcoholPercentage! - _dilutionResult!.targetAlcoholPercentage).abs() > 0.1
                                                          ? Colors.orange[800]
                                                          : null,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        
                                        // 近似値選択（データに正確な値がない場合）
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
                                          SizedBox(height: 8),
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
                                        
                                        SizedBox(height: 16),
                                        
                                        // アクションボタン
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                icon: Icon(Icons.save),
                                                label: Text('計画を登録'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: _saveDilutionPlan,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              
                              SizedBox(height: 24),
                              
                              // 最近の計画を表示（最大3件）
                              if (_savedPlans.isNotEmpty) ...[
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '最近の割水計画',
                                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pushNamed(context, '/dilution-plans').then((_) {
                                                  // 画面から戻ってきたら計画を再読み込み
                                                  _loadSavedPlans();
                                                });
                                              },
                                              child: Text('全て表示'),
                                            ),
                                          ],
                                        ),
                                        Divider(),
                                        ..._savedPlans
                                          .where((plan) => !plan.isCompleted)
                                          .take(3)
                                          .map((plan) => Column(
                                            children: [
                                              ListTile(
                                                contentPadding: EdgeInsets.zero,
                                                title: Text(
                                                  plan.sakeName.isNotEmpty ? plan.sakeName : 'タンク ${plan.tankNumber}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  '${plan.initialAlcoholPercentage}% → ${plan.targetAlcoholPercentage.toStringAsFixed(1)}%, 水量: ${plan.waterToAdd.toStringAsFixed(1)} L',
                                                  style: TextStyle(fontSize: 13),
                                                ),
                                                trailing: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                                                      onPressed: () => _loadPlan(plan),
                                                      tooltip: '編集',
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.check_circle, color: Colors.green, size: 20),
                                                      onPressed: () => _completeDilutionPlan(plan.id),
                                                      tooltip: '完了',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (_savedPlans.where((p) => !p.isCompleted).toList().indexOf(plan) < 
                                                  _savedPlans.where((p) => !p.isCompleted).take(3).length - 1)
                                                Divider(),
                                            ],
                                          )).toList(),
                                          
                                        if (_savedPlans.where((plan) => !plan.isCompleted).isEmpty)
                                          Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Text(
                                                '計画中の割水はありません',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  // 日付のフォーマット用ヘルパーメソッド
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}