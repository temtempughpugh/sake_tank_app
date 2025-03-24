// lib/screens/brewing_record_screen.dart の修正点

// 1. インポート部分の修正: 名前の衝突を解決
import 'package:flutter/material.dart';
import '../models/bottling_info.dart';
import '../models/brewing_record.dart';
import '../services/bottling_service.dart';
import '../services/brewing_record_service.dart';
// CsvServiceをプレフィックスをつけてインポート
import '../services/csv_service.dart' as csv_service;
import '../widgets/main_drawer.dart';
import '../models/tank_category.dart';
import '../models/approximation_pair.dart'; // 別ファイルに移動した場合

class BrewingRecordScreen extends StatefulWidget {
  final BottlingInfo bottlingInfo;
  
  const BrewingRecordScreen({Key? key, required this.bottlingInfo}) : super(key: key);
  
  @override
  _BrewingRecordScreenState createState() => _BrewingRecordScreenState();
}

class _BrewingRecordScreenState extends State<BrewingRecordScreen> {
  // サービスインスタンス
  final BrewingRecordService _brewingRecordService = BrewingRecordService();
  final BottlingService _bottlingService = BottlingService();
  // 名前衝突を解決
  final csv_service.CsvService _csvService = csv_service.CsvService();
  
  // 状態変数
  bool _isLoading = false;
  ProcessType _selectedProcess = ProcessType.SHIPPING_DILUTION;
  List<String> _availableTanks = [];
  
  // 入力コントローラー
  final TextEditingController _originalAlcoholController = TextEditingController();
  final TextEditingController _actualAlcoholController = TextEditingController();
  final TextEditingController _dilutionAmountController = TextEditingController();
  final TextEditingController _originalLiquorController = TextEditingController();
  final TextEditingController _reductionController = TextEditingController(text: '0');
  final TextEditingController _temperatureController = TextEditingController();
  
  // 手動入力モード状態
  bool _manualAlcoholMode = false;
  bool _manualDilutionMode = false;
  bool _manualOriginalLiquorMode = false;
  
  // 選択・計算された値
  String? _selectedTank;
  double? _dilutedVolume;
  double? _selectedDilutedVolume;
  double? _dilutedMeasurement;
  double? _originalAlcoholPercentage;
  double? _dilutionAmount;
  double? _originalLiquorVolume;
  double? _selectedOriginalLiquorVolume;
  double? _originalLiquorMeasurement;
  double? _actualDilutedAlcoholPercentage;
  
  // 近似値リスト
  List<ApproximationPair> _dilutedVolumeApproximations = [];
  List<ApproximationPair> _originalLiquorApproximations = [];

  @override
  void initState() {
    super.initState();
    _loadTanks();
    _dilutedVolume = widget.bottlingInfo.totalVolume;
  }
  
  @override
  void dispose() {
    // コントローラーの破棄
    _originalAlcoholController.dispose();
    _actualAlcoholController.dispose();
    _dilutionAmountController.dispose();
    _originalLiquorController.dispose();
    _reductionController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }
  
  // タンク情報を読み込む
  Future<void> _loadTanks() async {
    setState(() => _isLoading = true);
    
    try {
      final tanks = await _csvService.getAvailableTankNumbers();
      setState(() {
        _availableTanks = tanks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('タンクデータの読み込みに失敗しました: $e');
    }
  }
  
  // 割水後容量の近似値を読み込む
  Future<void> _loadDilutedVolumeApproximations() async {
    if (_selectedTank == null || _dilutedVolume == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // 近似値を取得
      final approximations = await _brewingRecordService.findNearestVolumes(
        _selectedTank!, 
        _dilutedVolume!
      );
      
      // 型変換して状態を更新
      setState(() {
    _dilutedVolumeApproximations = approximations
        .map((map) => ApproximationPair(
          capacity: map.capacity,
          measurement: map.measurement
        ))
        .toList();
    _isLoading = false;
  });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('近似値の取得に失敗しました: $e');
    }
  }
  
  // 割水前酒量の近似値を読み込む
  Future<void> _loadOriginalLiquorApproximations() async {
    if (_selectedTank == null || _originalLiquorVolume == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // 近似値を取得
      final approximations = await _brewingRecordService.findNearestVolumes(
        _selectedTank!, 
        _originalLiquorVolume!
      );
      
      // 型変換して状態を更新
      setState(() {
    _dilutedVolumeApproximations = approximations
        .map((map) => ApproximationPair(
          capacity: map.capacity,
          measurement: map.measurement
        ))
        .toList();
    _isLoading = false;
  });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('近似値の取得に失敗しました: $e');
    }
  }
  
  // 割水後容量の選択時
 void _selectDilutedVolume(ApproximationPair pair) {
    setState(() {
      _selectedDilutedVolume = pair.capacity;
      _dilutedMeasurement = pair.measurement;
      
      // 瓶詰め欠減を計算
      double bottlingReduction = pair.capacity - widget.bottlingInfo.totalVolume;
      _reductionController.text = bottlingReduction.toStringAsFixed(1);
      
      // 割水前アルコール度数が入力済みなら再計算
      if (_originalAlcoholPercentage != null) {
        _calculateDilution();
      }
    });
  }
  
  // 割水前酒量の選択時
  void _selectOriginalLiquorVolume(ApproximationPair pair) {
    setState(() {
      _selectedOriginalLiquorVolume = pair.capacity;
      _originalLiquorMeasurement = pair.measurement;
      
      // 実際のアルコール度数を再計算
      _recalculateActualAlcohol();
    });
  }
  
  // 割水計算
  void _calculateDilution() {
    if (_selectedDilutedVolume == null || _originalAlcoholPercentage == null) return;
    
   // 4. 必須引数が欠落している部分の修正 - calculateOriginalLiquorVolume関数
  _originalLiquorVolume = _brewingRecordService.calculateOriginalLiquorVolume(
    dilutedVolume: _selectedDilutedVolume!,
    originalAlcohol: _originalAlcoholPercentage!,
    dilutedAlcohol: widget.bottlingInfo.alcoholPercentage
  );
  
    
    // 割水量計算
    _dilutionAmount = _selectedDilutedVolume! - _originalLiquorVolume!;
    
    // 割水前酒量の近似値を読み込み
    _loadOriginalLiquorApproximations();
    
    // 選択値をリセット
    _selectedOriginalLiquorVolume = null;
    _originalLiquorMeasurement = null;
    _actualDilutedAlcoholPercentage = null;
    
    setState(() {});
  }
  
  // 実際のアルコール度数を再計算
  void _recalculateActualAlcohol() {
    if (_selectedOriginalLiquorVolume == null || 
        _originalAlcoholPercentage == null || 
        _dilutionAmount == null) return;
    
    _actualDilutedAlcoholPercentage = _brewingRecordService.calculateActualAlcohol(
    originalVolume: _selectedOriginalLiquorVolume!,
    originalAlcohol: _originalAlcoholPercentage!,
    dilutionAmount: _dilutionAmount!
  );
    
    setState(() {});
  }
  
  // 手動入力値が変更された時に関連値を更新
  void _updateDependentValues(String changedValue) {
    if (_selectedDilutedVolume == null) return;
    
    switch (changedValue) {
      case 'alcohol':
        // アルコール度数の手動入力時は特に何もしない
        break;
        
      case 'dilution':
        if (_manualDilutionMode && _dilutionAmount != null) {
          double newOriginalLiquorVolume = _selectedDilutedVolume! - _dilutionAmount!;
          if (!_manualOriginalLiquorMode) {
            _originalLiquorVolume = newOriginalLiquorVolume;
            _selectedOriginalLiquorVolume = newOriginalLiquorVolume;
            _loadOriginalLiquorApproximations();
          }
          if (!_manualAlcoholMode && _originalAlcoholPercentage != null && _selectedOriginalLiquorVolume != null) {
            _recalculateActualAlcohol();
          }
        }
        break;
        
      case 'originalLiquor':
        if (_manualOriginalLiquorMode && _selectedOriginalLiquorVolume != null) {
          if (!_manualDilutionMode) {
            _dilutionAmount = _selectedDilutedVolume! - _selectedOriginalLiquorVolume!;
            _dilutionAmountController.text = _dilutionAmount!.toStringAsFixed(1);
          }
          if (!_manualAlcoholMode && _originalAlcoholPercentage != null) {
            _recalculateActualAlcohol();
          }
        }
        break;
    }
    
    setState(() {});
  }
  
  // 入力を検証して記録を保存
  Future<void> _saveRecord() async {
    // 入力検証
    if (!_validateInputs()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // 欠減量取得
      double reductionAmount = double.parse(_reductionController.text);
      
      // 品温（オプション）
      double? temperature;
      if (_temperatureController.text.isNotEmpty) {
        temperature = double.parse(_temperatureController.text);
      }
      
      // 記録作成
      final record = BrewingRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bottlingInfoId: widget.bottlingInfo.id,
        processType: _selectedProcess,
        date: DateTime.now(),
        tankNumber: _selectedTank!,
        dilutedVolume: _selectedDilutedVolume!,
        dilutedMeasurement: _dilutedMeasurement!,
        dilutedAlcoholPercentage: widget.bottlingInfo.alcoholPercentage,
        actualDilutedAlcoholPercentage: _actualDilutedAlcoholPercentage,
        originalAlcoholPercentage: _originalAlcoholPercentage!,
        originalLiquorVolume: _originalLiquorVolume!,
        selectedOriginalLiquorVolume: _selectedOriginalLiquorVolume!,
        originalLiquorMeasurement: _originalLiquorMeasurement!,
        dilutionAmount: _dilutionAmount!,
        reductionAmount: reductionAmount,
        temperature: temperature,
      );
      
      // 記録保存
      await _brewingRecordService.saveBrewingRecord(record);
      
      // 瓶詰め情報の実際アルコール度数を更新
      if (_actualDilutedAlcoholPercentage != null) {
        await _bottlingService.updateActualAlcoholPercentage(
          widget.bottlingInfo.id, 
          _actualDilutedAlcoholPercentage!
        );
      }
      
      setState(() => _isLoading = false);
      
      // 成功メッセージ
      _showSuccessMessage('記帳データを保存しました');
      
      // 前の画面に戻る
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('保存中にエラーが発生しました: $e');
    }
  }
  
  // 入力検証
  bool _validateInputs() {
    if (_selectedTank == null) {
      _showErrorDialog('タンクを選択してください');
      return false;
    }
    
    if (_selectedDilutedVolume == null || _dilutedMeasurement == null) {
      _showErrorDialog('割水後容量を選択してください');
      return false;
    }
    
    if (_originalAlcoholPercentage == null) {
      _showErrorDialog('割水前アルコール度数を入力してください');
      return false;
    }
    
    if (_selectedOriginalLiquorVolume == null || _originalLiquorMeasurement == null) {
      _showErrorDialog('割水前酒量を選択してください');
      return false;
    }
    
    try {
      // 欠減量の数値チェック
      double.parse(_reductionController.text);
      
      // 品温（オプション）の数値チェック
      if (_temperatureController.text.isNotEmpty) {
        double.parse(_temperatureController.text);
      }
    } catch (e) {
      _showErrorDialog('欠減量または品温の値が正しくありません');
      return false;
    }
    
    return true;
  }
  
  // エラーダイアログ表示
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
  
  // 成功メッセージ表示
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('記帳サポート'),
      ),
      endDrawer: MainDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 工程選択
                  _buildProcessSelector(),
                  
                  const SizedBox(height: 16),
                  
                  // 瓶詰め情報表示
                  _buildBottlingInfoCard(),
                  
                  const SizedBox(height: 16),
                  
                  // 工程フォーム
                  if (_selectedProcess == ProcessType.SHIPPING_DILUTION)
                    _buildShippingDilutionForm(),
                  
                  const SizedBox(height: 24),
                  
                  // 保存ボタン
                  ElevatedButton.icon(
                    onPressed: _saveRecord,
                    icon: const Icon(Icons.save),
                    label: const Text('記帳データを保存'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  // 工程選択ウィジェット
  Widget _buildProcessSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '工程選択',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ProcessType>(
              value: _selectedProcess,
              decoration: const InputDecoration(
                labelText: '工程を選択',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: ProcessType.SHIPPING_DILUTION,
                  child: Text('蔵出し/割水'),
                ),
                // 他の工程も将来追加可能
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedProcess = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // 瓶詰め情報カード
  Widget _buildBottlingInfoCard() {
    final bottlingInfo = widget.bottlingInfo;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '瓶詰め情報',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(bottlingInfo.sakeName),
              subtitle: Text('${bottlingInfo.date.year}/${bottlingInfo.date.month}/${bottlingInfo.date.day}'),
              leading: const CircleAvatar(
                child: Icon(Icons.liquor),
              ),
            ),
            const Divider(),
            _buildInfoRow('アルコール度数:', '${bottlingInfo.alcoholPercentage.toStringAsFixed(1)}%'),
            _buildInfoRow('総容量:', '${bottlingInfo.totalVolume.toStringAsFixed(1)} L'),
            if (bottlingInfo.actualAlcoholPercentage != null)
              _buildInfoRow(
                '実際アルコール度数:', 
                '${bottlingInfo.actualAlcoholPercentage!.toStringAsFixed(2)}%',
                valueColor: Colors.blue[700],
              ),
          ],
        ),
      ),
    );
  }
  
  // 蔵出し/割水フォーム
  Widget _buildShippingDilutionForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '蔵出し/割水',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            
            // タンク選択
            _buildTankSelector(),
            const SizedBox(height: 24),
            
            // 割水後情報セクション
            _buildDilutedSection(),
            const SizedBox(height: 16),
            
            // 割水前アルコール度数入力
            TextFormField(
              controller: _originalAlcoholController,
              decoration: const InputDecoration(
                labelText: '割水前アルコール度数 (%)',
                hintText: '例: 17.0',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final alcohol = double.tryParse(value);
                if (alcohol != null && alcohol > 0) {
                  _originalAlcoholPercentage = alcohol;
                  if (_selectedDilutedVolume != null) {
                    _calculateDilution();
                  }
                }
              },
            ),
            const SizedBox(height: 24),
            
            // 計算結果セクション
            if (_dilutionAmount != null) 
              _buildCalculationResultSection(),
            const SizedBox(height: 24),
            
            // 欠減・品温セクション
            _buildAdditionalInputsSection(),
          ],
        ),
      ),
    );
  }
  
  // タンク選択ドロップダウン
  Widget _buildTankSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedTank,
      decoration: const InputDecoration(
        labelText: 'タンク番号',
        border: OutlineInputBorder(),
      ),
      items: _buildTankDropdownItems(),
      onChanged: (value) {
        if (value != null && !value.startsWith("header_") && !value.startsWith("divider_")) {
          setState(() {
            _selectedTank = value;
            _resetCalculationValues();
            _loadDilutedVolumeApproximations();
          });
        }
      },
    );
  }
  
  // 計算値のリセット
  void _resetCalculationValues() {
    _selectedDilutedVolume = null;
    _dilutedMeasurement = null;
    _dilutionAmount = null;
    _originalLiquorVolume = null;
    _selectedOriginalLiquorVolume = null;
    _originalLiquorMeasurement = null;
    _actualDilutedAlcoholPercentage = null;
  }
  
  // タンクドロップダウン項目の構築
  List<DropdownMenuItem<String>> _buildTankDropdownItems() {
    List<DropdownMenuItem<String>> items = [];
    
    // タンクカテゴリーを取得
    List<TankCategory> categories = TankCategories.getCategories();
    
    // カテゴリーごとにタンクをマッピング
    Map<String, List<String>> tanksByCategory = {};
    for (var category in categories) {
      tanksByCategory[category.name] = [];
    }
    
    // タンクをカテゴリーに割り当て
    for (var tank in _availableTanks) {
      String categoryName = TankCategories.getCategoryForTank(tank).name;
      tanksByCategory[categoryName]!.add(tank);
    }
    
    // カテゴリーごとにドロップダウン項目を作成
    for (var category in categories) {
      var tanksInCategory = tanksByCategory[category.name] ?? [];
      if (tanksInCategory.isEmpty) continue;
      
      // カテゴリータイトル
      items.add(DropdownMenuItem<String>(
        value: "header_${category.name}",
        enabled: false,
        child: Text(
          category.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: category.color ?? Colors.black,
          ),
        ),
      ));
      
      // ソート
      tanksInCategory.sort();
      
      // カテゴリー内のタンク
      for (var tank in tanksInCategory) {
        items.add(DropdownMenuItem<String>(
          value: tank,
          child: Text("  $tank"), // インデント付きで表示
        ));
      }
      
      // 区切り線（最後のカテゴリー以外）
      if (category != categories.last) {
        items.add(DropdownMenuItem<String>(
          value: "divider_${category.name}",
          enabled: false,
          child: const Divider(height: 1),
        ));
      }
    }
    
    return items;
  }
  
  // 割水後情報セクション
  Widget _buildDilutedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('＜割水後情報＞', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('目標アルコール度数: ${widget.bottlingInfo.alcoholPercentage.toStringAsFixed(1)}%'),
        const SizedBox(height: 16),
        if (_selectedTank != null) ...[
          Text('割水後総量: ${_dilutedVolume?.toStringAsFixed(1) ?? "..."} L (瓶詰め量)'),
          const SizedBox(height: 8),
          if (_dilutedVolumeApproximations.isNotEmpty)
            _buildApproximationChips(
              _dilutedVolumeApproximations,
              _selectedDilutedVolume,
              (pair) => _selectDilutedVolume(pair),
            ),
          if (_dilutedMeasurement != null)
            Text('割水後検尺: ${_dilutedMeasurement!.toStringAsFixed(1)} mm'),
        ],
      ],
    );
  }
  
  // 計算結果セクション
  Widget _buildCalculationResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('割水量: ${_dilutionAmount!.toStringAsFixed(1)} L',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Text('割水前酒量: ${_originalLiquorVolume?.toStringAsFixed(1) ?? "..."} L (計算値)'),
        const SizedBox(height: 8),
        if (_originalLiquorApproximations.isNotEmpty)
          _buildApproximationChips(
            _originalLiquorApproximations,
            _selectedOriginalLiquorVolume,
            (pair) => _selectOriginalLiquorVolume(pair),
          ),
        if (_originalLiquorMeasurement != null)
          Text('割水前検尺: ${_originalLiquorMeasurement!.toStringAsFixed(1)} mm'),
        const SizedBox(height: 16),
        
        // 実際アルコール度数（手動/自動）
        _buildManualInputRow(
          label: '実際アルコール度数:',
          value: _actualDilutedAlcoholPercentage?.toStringAsFixed(2) ?? "-",
          suffix: '%',
          controller: _actualAlcoholController,
          isManualMode: _manualAlcoholMode,
          onManualModeChanged: (value) {
            setState(() {
              _manualAlcoholMode = value;
              if (value && _actualDilutedAlcoholPercentage != null) {
                _actualAlcoholController.text = _actualDilutedAlcoholPercentage!.toStringAsFixed(2);
              }
            });
          },
          onValueChanged: (value) {
            double? alcohol = double.tryParse(value);
            if (alcohol != null) {
              _actualDilutedAlcoholPercentage = alcohol;
              _updateDependentValues('alcohol');
            }
          },
          valueColor: Colors.blue,
        ),
        
        // 割水量（手動/自動）
        _buildManualInputRow(
          label: '割水量:',
          value: '${_dilutionAmount?.toStringAsFixed(1) ?? "-"} L',
          suffix: 'L',
          controller: _dilutionAmountController,
          isManualMode: _manualDilutionMode,
          onManualModeChanged: (value) {
            setState(() {
              _manualDilutionMode = value;
              if (value && _dilutionAmount != null) {
                _dilutionAmountController.text = _dilutionAmount!.toStringAsFixed(1);
              }
            });
          },
          onValueChanged: (value) {
            double? amount = double.tryParse(value);
            if (amount != null) {
              _dilutionAmount = amount;
              _updateDependentValues('dilution');
            }
          },
          valueColor: Colors.green,
          fontSize: 16,
        ),
        
        // 割水前酒量（手動/自動）
        _buildManualInputRow(
          label: '割水前酒量:',
          value: '${_selectedOriginalLiquorVolume?.toStringAsFixed(1) ?? _originalLiquorVolume?.toStringAsFixed(1) ?? "-"} L',
          suffix: 'L',
          controller: _originalLiquorController,
          isManualMode: _manualOriginalLiquorMode,
          onManualModeChanged: (value) {
            setState(() {
              _manualOriginalLiquorMode = value;
              if (value && _selectedOriginalLiquorVolume != null) {
                _originalLiquorController.text = _selectedOriginalLiquorVolume!.toStringAsFixed(1);
              }
            });
          },
          onValueChanged: (value) {
            double? amount = double.tryParse(value);
            if (amount != null) {
              _selectedOriginalLiquorVolume = amount;
              _updateDependentValues('originalLiquor');
            }
          },
          valueColor: Colors.orange,
        ),
      ],
    );
  }
  
  // 追加入力（欠減・品温）セクション
  Widget _buildAdditionalInputsSection() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _reductionController,
            decoration: const InputDecoration(
              labelText: '蔵出し欠減 (L)',
              hintText: 'デフォルト: 0',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _temperatureController,
            decoration: const InputDecoration(
              labelText: '品温 (℃)',
              hintText: '例: 18.5',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }
  
  // 情報行ウィジェット
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
  
  // 近似値選択チップ
  Widget _buildApproximationChips(
  List<ApproximationPair> approximations,
  double? selectedValue,
  Function(ApproximationPair) onSelected,
) {
  return Wrap(
    spacing: 8,
    children: approximations.map((pair) {
      return ChoiceChip(
        label: Text('${pair.capacity.toStringAsFixed(1)} L'),
        selected: selectedValue == pair.capacity,
        onSelected: (selected) {
          if (selected) {
            onSelected(pair);
          }
        },
      );
    }).toList(),
  );
}
  
  // 手動入力行ウィジェット
  Widget _buildManualInputRow({
    required String label,
    required String value,
    required String suffix,
    required TextEditingController controller,
    required bool isManualMode,
    required Function(bool) onManualModeChanged,
    required Function(String) onValueChanged,
    Color? valueColor,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Text(label),
          const SizedBox(width: 8),
          Expanded(
            child: isManualMode
                ? TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      suffixText: suffix,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: onValueChanged,
                  )
                : Text(
                    value,
                    style: TextStyle(
                      color: valueColor,
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                  ),
          ),
          Switch(
            value: isManualMode,
            onChanged: onManualModeChanged,
            activeColor: valueColor ?? Colors.blue,
          ),
        ],
      ),
    );
  }
}