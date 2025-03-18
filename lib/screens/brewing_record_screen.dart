import 'package:flutter/material.dart';
import '../models/bottling_info.dart';
import '../models/brewing_record.dart';
import '../services/bottling_service.dart';
import '../services/brewing_record_service.dart';
import '../services/csv_service.dart';
import '../widgets/main_drawer.dart';
import '../models/tank_category.dart';

class BrewingRecordScreen extends StatefulWidget {
  final BottlingInfo bottlingInfo;
  
  const BrewingRecordScreen({Key? key, required this.bottlingInfo}) : super(key: key);
  
  @override
  _BrewingRecordScreenState createState() => _BrewingRecordScreenState();
}

class _BrewingRecordScreenState extends State<BrewingRecordScreen> {
  final BrewingRecordService _brewingRecordService = BrewingRecordService();
  final BottlingService _bottlingService = BottlingService();
  final CsvService _csvService = CsvService();
  
  // 状態変数
  ProcessType _selectedProcess = ProcessType.SHIPPING_DILUTION;
  bool _isLoading = false;
  List<String> _availableTanks = [];
  
  // 選択されたタンクと入力値
  String? _selectedTank;
  final TextEditingController _originalAlcoholController = TextEditingController();
  // コンストラクタの引数はpositionではなく名前付き引数として渡す
final TextEditingController _reductionController = TextEditingController(text: '0');
  final TextEditingController _temperatureController = TextEditingController();
  
  // 計算値
  double? _dilutedVolume;
  double? _selectedDilutedVolume;
  double? _dilutedMeasurement;
  
  double? _originalAlcoholPercentage;
  double? _dilutionAmount;
  double? _originalLiquorVolume;
  double? _selectedOriginalLiquorVolume;
  double? _originalLiquorMeasurement;
  
  double? _actualDilutedAlcoholPercentage;
  
  List<Map<String, double>> _dilutedVolumeApproximations = [];
  List<Map<String, double>> _originalLiquorApproximations = [];

  bool _manualAlcoholMode = false;
  bool _manualDilutionMode = false;
  bool _manualOriginalLiquorMode = false;

  final TextEditingController _actualAlcoholController = TextEditingController();
  final TextEditingController _dilutionAmountController = TextEditingController();
  final TextEditingController _originalLiquorController = TextEditingController();
  
@override
  void initState() {
    super.initState();
    _loadTanks();
  }
  
  @override
  void dispose() {
    _originalAlcoholController.dispose();
    _reductionController.dispose();
    _temperatureController.dispose();
    _actualAlcoholController.dispose();
    _dilutionAmountController.dispose();
    _originalLiquorController.dispose();
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
        
        // 初期値設定
        _dilutedVolume = widget.bottlingInfo.totalVolume;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('タンクデータの読み込みに失敗しました: $e');
    }
  }
  
  Future<void> _loadDilutedVolumeApproximations() async {
  if (_selectedTank == null || _dilutedVolume == null) return;
  
  setState(() {
    _isLoading = true;
  });
  
  try {
    // タンクデータを取得
    final tankData = await _csvService.getDataForTank(_selectedTank!);
    if (tankData.isEmpty) {
      setState(() {
        _dilutedVolumeApproximations = [];
        _isLoading = false;
      });
      return;
    }
    
    // 容量でソート
    tankData.sort((a, b) => a.capacity.compareTo(b.capacity));
    
    // 目標値に最も近いインデックスを見つける
    int closestIndex = 0;
    double minDiff = double.infinity;
    
    for (int i = 0; i < tankData.length; i++) {
      double diff = (_dilutedVolume! - tankData[i].capacity).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestIndex = i;
      }
    }
    
    // -1, +1, +2, +3, +4のインデックスオフセットを計算（配列範囲内に収める）
    List<int> offsets = [-1, 1, 2, 3, 4];
    List<Map<String, double>> approximations = [];
    
    for (int offset in offsets) {
      int index = closestIndex + offset;
      // 配列の範囲内かチェック
      if (index >= 0 && index < tankData.length) {
        approximations.add({
          'capacity': tankData[index].capacity,
          'measurement': tankData[index].measurement
        });
      }
    }
    
    setState(() {
      _dilutedVolumeApproximations = approximations;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    _showErrorDialog('近似値の取得に失敗しました: $e');
  }
}
  
  Future<void> _loadOriginalLiquorApproximations() async {
  if (_selectedTank == null || _originalLiquorVolume == null) return;
  
  setState(() {
    _isLoading = true;
  });
  
  try {
    // タンクデータを取得
    final tankData = await _csvService.getDataForTank(_selectedTank!);
    if (tankData.isEmpty) {
      setState(() {
        _originalLiquorApproximations = [];
        _isLoading = false;
      });
      return;
    }
    
    // 容量でソート
    tankData.sort((a, b) => a.capacity.compareTo(b.capacity));
    
    // 目標値に最も近いインデックスを見つける
    int closestIndex = 0;
    double minDiff = double.infinity;
    
    for (int i = 0; i < tankData.length; i++) {
      double diff = (_originalLiquorVolume! - tankData[i].capacity).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestIndex = i;
      }
    }
    
    // -1, +1, +2, +3, +4のインデックスオフセットを計算
    List<int> offsets = [-1, 1, 2, 3, 4];
    List<Map<String, double>> approximations = [];
    
    for (int offset in offsets) {
      int index = closestIndex + offset;
      // 配列の範囲内かチェック
      if (index >= 0 && index < tankData.length) {
        approximations.add({
          'capacity': tankData[index].capacity,
          'measurement': tankData[index].measurement
        });
      }
    }
    
    setState(() {
      _originalLiquorApproximations = approximations;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    _showErrorDialog('近似値の取得に失敗しました: $e');
  }
}
  
  void _selectDilutedVolume(double volume, double measurement) {
  setState(() {
    _selectedDilutedVolume = volume;
    _dilutedMeasurement = measurement;
    
    // 瓶詰め欠減を計算（追加部分）
    double bottlingReduction = volume - widget.bottlingInfo.totalVolume;
    _reductionController.text = bottlingReduction.toStringAsFixed(1);
    
    // 割水前アルコール度数が入力済みなら再計算
    if (_originalAlcoholPercentage != null) {
      _calculateDilution();
    }
  });
}
  
  void _selectOriginalLiquorVolume(double volume, double measurement) {
    setState(() {
      _selectedOriginalLiquorVolume = volume;
      _originalLiquorMeasurement = measurement;
      
      // 実際のアルコール度数を再計算
      _recalculateActualAlcohol();
    });
  }
  


  void _calculateDilution() {
    if (_selectedDilutedVolume == null || _originalAlcoholPercentage == null) return;
    
    // 割水前酒量計算
    final dilutedAlcohol = widget.bottlingInfo.alcoholPercentage;
    _originalLiquorVolume = _brewingRecordService.calculateOriginalLiquorVolume(
      _selectedDilutedVolume!,
      _originalAlcoholPercentage!,
      dilutedAlcohol
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
  
  void _recalculateActualAlcohol() {
    if (_selectedOriginalLiquorVolume == null || 
        _originalAlcoholPercentage == null || 
        _dilutionAmount == null) return;
    
    _actualDilutedAlcoholPercentage = _brewingRecordService.calculateActualAlcohol(
      _selectedOriginalLiquorVolume!,
      _originalAlcoholPercentage!,
      _dilutionAmount!
    );
    
    setState(() {});
  }

  void _updateDependentValues(String changedValue) {
  if (_selectedDilutedVolume == null) return;
  
  switch (changedValue) {
    case 'alcohol':
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
  
  Future<void> _saveRecord() async {
    // 入力検証
    if (_selectedTank == null) {
      _showErrorDialog('タンクを選択してください');
      return;
    }
    
    if (_selectedDilutedVolume == null || _dilutedMeasurement == null) {
      _showErrorDialog('割水後容量を選択してください');
      return;
    }
    
    if (_originalAlcoholPercentage == null) {
      _showErrorDialog('割水前アルコール度数を入力してください');
      return;
    }
    
    if (_selectedOriginalLiquorVolume == null || _originalLiquorMeasurement == null) {
      _showErrorDialog('割水前酒量を選択してください');
      return;
    }
    
    // 欠減量取得
    double reductionAmount;
    try {
      reductionAmount = double.parse(_reductionController.text);
    } catch (e) {
      _showErrorDialog('有効な欠減量を入力してください');
      return;
    }
    
    // 品温（オプション）
    double? temperature;
    if (_temperatureController.text.isNotEmpty) {
      try {
        temperature = double.parse(_temperatureController.text);
      } catch (e) {
        _showErrorDialog('有効な品温を入力してください');
        return;
      }
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
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
      
      setState(() {
        _isLoading = false;
      });
      
      // 成功メッセージ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('記帳データを保存しました'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // 前の画面に戻る
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // エラーメッセージ
      _showErrorDialog('保存中にエラーが発生しました: $e');
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
        child: Divider(height: 1),
      ));
    }
  }
  
  return items;
}
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('記帳サポート'),
      ),
      endDrawer: MainDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 工程選択
                  _buildProcessSelector(),
                  
                  SizedBox(height: 16),
                  
                  // 瓶詰め情報表示
                  _buildBottlingInfoCard(),
                  
                  SizedBox(height: 16),
                  
                  // 工程フォーム（現在は蔵出し/割水のみ）
                  if (_selectedProcess == ProcessType.SHIPPING_DILUTION)
                    _buildShippingDilutionForm(),
                  
                  SizedBox(height: 24),
                  
                  // 保存ボタン
                  ElevatedButton.icon(
                    onPressed: _saveRecord,
                    icon: Icon(Icons.save),
                    label: Text('記帳データを保存'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      minimumSize: Size(double.infinity, 0),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildProcessSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '工程選択',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<ProcessType>(
              value: _selectedProcess,
              decoration: InputDecoration(
                labelText: '工程を選択',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
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
  
  Widget _buildBottlingInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '瓶詰め情報',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text(widget.bottlingInfo.sakeName),
              subtitle: Text('${widget.bottlingInfo.date.year}/${widget.bottlingInfo.date.month}/${widget.bottlingInfo.date.day}'),
              leading: CircleAvatar(
                child: Icon(Icons.liquor),
              ),
            ),
            Divider(),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('アルコール度数:'),
                  Text(
                    '${widget.bottlingInfo.alcoholPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('総容量:'),
                  Text(
                    '${widget.bottlingInfo.totalVolume.toStringAsFixed(1)} L',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (widget.bottlingInfo.actualAlcoholPercentage != null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('実際アルコール度数:'),
                    Text(
                      '${widget.bottlingInfo.actualAlcoholPercentage!.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildShippingDilutionForm() {
  return Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '蔵出し/割水',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Divider(),
          DropdownButtonFormField<String>(
            value: _selectedTank,
            decoration: InputDecoration(
              labelText: 'タンク番号',
              border: OutlineInputBorder(),
            ),
            items: _buildTankDropdownItems(),
            onChanged: (value) {
              if (value != null && !value.startsWith("header_") && !value.startsWith("divider_")) {
                setState(() {
                  _selectedTank = value;
                  _selectedDilutedVolume = null;
                  _dilutedMeasurement = null;
                  _dilutionAmount = null;
                  _originalLiquorVolume = null;
                  _selectedOriginalLiquorVolume = null;
                  _originalLiquorMeasurement = null;
                  _actualDilutedAlcoholPercentage = null;
                  _loadDilutedVolumeApproximations();
                });
              }
            },
          ),
          SizedBox(height: 24),
          Text('＜割水後情報＞', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('目標アルコール度数: ${widget.bottlingInfo.alcoholPercentage.toStringAsFixed(1)}%'),
          SizedBox(height: 16),
          if (_selectedTank != null) ...[
            Text('割水後総量: ${_dilutedVolume?.toStringAsFixed(1) ?? "..."} L (瓶詰め量)'),
            SizedBox(height: 8),
            if (_dilutedVolumeApproximations.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _dilutedVolumeApproximations.map((pair) {
                  final volume = pair['capacity']!;
                  final measurement = pair['measurement']!;
                  return ChoiceChip(
                    label: Text('${volume.toStringAsFixed(1)} L'),
                    selected: _selectedDilutedVolume == volume,
                    onSelected: (selected) {
                      if (selected) {
                        _selectDilutedVolume(volume, measurement);
                      }
                    },
                  );
                }).toList(),
              ),
            if (_dilutedMeasurement != null)
              Text('割水後検尺: ${_dilutedMeasurement!.toStringAsFixed(1)} mm'),
          ],
          SizedBox(height: 16),
          TextFormField(
            controller: _originalAlcoholController,
            decoration: InputDecoration(
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
          SizedBox(height: 24),
          if (_dilutionAmount != null) ...[
            Text('割水量: ${_dilutionAmount!.toStringAsFixed(1)} L',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 16),
            Text('割水前酒量: ${_originalLiquorVolume?.toStringAsFixed(1) ?? "..."} L (計算値)'),
            SizedBox(height: 8),
            if (_originalLiquorApproximations.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _originalLiquorApproximations.map((pair) {
                  final volume = pair['capacity']!;
                  final measurement = pair['measurement']!;
                  return ChoiceChip(
                    label: Text('${volume.toStringAsFixed(1)} L'),
                    selected: _selectedOriginalLiquorVolume == volume,
                    onSelected: (selected) {
                      if (selected) {
                        _selectOriginalLiquorVolume(volume, measurement);
                      }
                    },
                  );
                }).toList(),
              ),
            if (_originalLiquorMeasurement != null)
              Text('割水前検尺: ${_originalLiquorMeasurement!.toStringAsFixed(1)} mm'),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Text('実際アルコール度数:'),
                  SizedBox(width: 8),
                  Expanded(
                    child: _manualAlcoholMode
                        ? TextField(
                            controller: _actualAlcoholController,
                            decoration: InputDecoration(
                              suffixText: '%',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              double? alcohol = double.tryParse(value);
                              if (alcohol != null) {
                                _actualDilutedAlcoholPercentage = alcohol;
                                _updateDependentValues('alcohol');
                              }
                            },
                          )
                        : Text(
                            '${_actualDilutedAlcoholPercentage?.toStringAsFixed(1) ?? "-"}% (${_actualDilutedAlcoholPercentage?.toStringAsFixed(2) ?? "-"}%)',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  Switch(
                    value: _manualAlcoholMode,
                    onChanged: (value) {
                      setState(() {
                        _manualAlcoholMode = value;
                        if (value && _actualDilutedAlcoholPercentage != null) {
                          _actualAlcoholController.text = _actualDilutedAlcoholPercentage!.toStringAsFixed(2);
                        }
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Text('割水量:'),
                  SizedBox(width: 8),
                  Expanded(
                    child: _manualDilutionMode
                        ? TextField(
                            controller: _dilutionAmountController,
                            decoration: InputDecoration(
                              suffixText: 'L',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              double? amount = double.tryParse(value);
                              if (amount != null) {
                                _dilutionAmount = amount;
                                _updateDependentValues('dilution');
                              }
                            },
                          )
                        : Text(
                            '${_dilutionAmount?.toStringAsFixed(1) ?? "-"} L',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                  Switch(
                    value: _manualDilutionMode,
                    onChanged: (value) {
                      setState(() {
                        _manualDilutionMode = value;
                        if (value && _dilutionAmount != null) {
                          _dilutionAmountController.text = _dilutionAmount!.toStringAsFixed(1);
                        }
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Text('割水前酒量:'),
                  SizedBox(width: 8),
                  Expanded(
                    child: _manualOriginalLiquorMode
                        ? TextField(
                            controller: _originalLiquorController,
                            decoration: InputDecoration(
                              suffixText: 'L',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              double? amount = double.tryParse(value);
                              if (amount != null) {
                                _selectedOriginalLiquorVolume = amount;
                                _updateDependentValues('originalLiquor');
                              }
                            },
                          )
                        : Text(
                            '${_selectedOriginalLiquorVolume?.toStringAsFixed(1) ?? _originalLiquorVolume?.toStringAsFixed(1) ?? "-"} L',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  Switch(
                    value: _manualOriginalLiquorMode,
                    onChanged: (value) {
                      setState(() {
                        _manualOriginalLiquorMode = value;
                        if (value && _selectedOriginalLiquorVolume != null) {
                          _originalLiquorController.text = _selectedOriginalLiquorVolume!.toStringAsFixed(1);
                        }
                      });
                    },
                    activeColor: Colors.orange,
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _reductionController,
                  decoration: InputDecoration(
                    labelText: '蔵出し欠減 (L)',
                    hintText: 'デフォルト: 0',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _temperatureController,
                  decoration: InputDecoration(
                    labelText: '品温 (℃)',
                    hintText: '例: 18.5',
                    border: OutlineInputBorder(),
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
}}