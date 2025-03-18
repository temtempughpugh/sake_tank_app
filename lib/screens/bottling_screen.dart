import 'package:flutter/material.dart';
import '../models/bottling_info.dart';
import '../services/bottling_service.dart';
import '../widgets/main_drawer.dart';
import 'package:flutter/services.dart'; // 入力フォーマッティング用
import 'dart:math'; 

class BottlingScreen extends StatefulWidget {
  final BottlingInfo? bottlingToEdit; // 編集用（nullなら新規作成）
  
  const BottlingScreen({Key? key, this.bottlingToEdit}) : super(key: key);
  
  @override
  _BottlingScreenState createState() => _BottlingScreenState();
}

class _BottlingScreenState extends State<BottlingScreen> {
  final _formKey = GlobalKey<FormState>();
  final BottlingService _bottlingService = BottlingService();
  
  // フォーム入力値
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _sakeNameController = TextEditingController();
  final TextEditingController _alcoholController = TextEditingController();
  final TextEditingController _remainingController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  
  List<BottleEntry> _bottleEntries = [];
  bool _isLoading = false;
  bool _isEdit = false;
  String? _editId;
  
  @override
  void initState() {
    super.initState();
    
    // 編集モードの場合、データを読み込む
    if (widget.bottlingToEdit != null) {
      _isEdit = true;
      _editId = widget.bottlingToEdit!.id;
      _loadExistingData();
    }
  }
  
  void _loadExistingData() {
    final info = widget.bottlingToEdit!;
    
    _selectedDate = info.date;
    _sakeNameController.text = info.sakeName;
    _alcoholController.text = info.alcoholPercentage.toString();
    _remainingController.text = info.remainingAmount.toString();
    if (info.temperature != null) {
      _temperatureController.text = info.temperature.toString();
    }
    
    _bottleEntries = List.from(info.bottleEntries);
  }
  
  @override
  void dispose() {
    _sakeNameController.dispose();
    _alcoholController.dispose();
    _remainingController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _saveBottlingInfo() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_bottleEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('少なくとも1つの瓶種を追加してください'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final sakeName = _sakeNameController.text;
      final alcoholPercentage = double.parse(_alcoholController.text);
      final remainingAmount = double.parse(_remainingController.text);
      double? temperature;
      
      if (_temperatureController.text.isNotEmpty) {
        temperature = double.parse(_temperatureController.text);
      }
      
      final id = _isEdit ? _editId! : DateTime.now().millisecondsSinceEpoch.toString();
      
      final bottlingInfo = BottlingInfo(
        id: id,
        date: _selectedDate,
        sakeName: sakeName,
        bottleEntries: _bottleEntries,
        remainingAmount: remainingAmount,
        alcoholPercentage: alcoholPercentage,
        temperature: temperature,
      );
      
      await _bottlingService.saveBottlingInfo(bottlingInfo);
      
      setState(() {
        _isLoading = false;
      });
      
      // 成功メッセージ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? '瓶詰め情報を更新しました' : '瓶詰め情報を保存しました'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラー: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _showAddBottleDialog() async {
    BottleType? selectedType;
    String? customName;
    double? customVolume;
    int bottlesPerCase = 12; // デフォルト値
    int caseCount = 0;
    int looseCount = 0;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('瓶種追加'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 定型瓶選択
                DropdownButton<BottleType?>(
                  hint: Text('瓶種を選択'),
                  value: selectedType,
                  items: [
                    DropdownMenuItem(value: BottleType.large, child: Text('1,800ml (一升瓶)')),
                    DropdownMenuItem(value: BottleType.medium, child: Text('720ml (四合瓶)')),
                    DropdownMenuItem(value: BottleType.small, child: Text('300ml')),
                    DropdownMenuItem(value: null, child: Text('カスタム')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedType = value;
                      if (value != null) {
                        bottlesPerCase = value.bottlesPerCase;
                      }
                    });
                  },
                ),
                
                // カスタム瓶情報入力
                if (selectedType == null) ...[
                  SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'カスタム瓶名',
                      hintText: '例: 180ml',
                    ),
                    onChanged: (value) => customName = value,
                  ),
                  SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '容量 (ml)',
                      hintText: '例: 180',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => customVolume = double.tryParse(value),
                  ),
                ],
                
                SizedBox(height: 16),
                
                // ケース入数設定（すべての瓶で変更可能）
                TextField(
                  decoration: InputDecoration(
                    labelText: 'ケース入数',
                    hintText: selectedType != null 
    ? '${selectedType!.bottlesPerCase}本入り'  // null アサーション演算子 (!) を追加
    : '例: 24',
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: bottlesPerCase.toString()),
                  onChanged: (value) {
                    int? newCount = int.tryParse(value);
                    if (newCount != null && newCount > 0) {
                      setState(() {
                        bottlesPerCase = newCount;
                        if (selectedType != null) {
  selectedType!.updateBottlesPerCase(newCount);  // null アサーション演算子 (!) を追加
}
                      });
                    }
                  },
                ),
                
                SizedBox(height: 16),
                
                // ケース数・バラ数入力
                TextField(
                  decoration: InputDecoration(labelText: 'ケース数'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => caseCount = int.tryParse(value) ?? 0,
                ),
                SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(labelText: 'バラ本数'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => looseCount = int.tryParse(value) ?? 0,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                // 有効性チェック
                if ((selectedType != null || (customName != null && customVolume != null)) &&
                    caseCount >= 0 && looseCount >= 0 && 
                    (caseCount > 0 || looseCount > 0)) {
                  
                  final bottleType = selectedType ?? 
                    BottleType.custom(customName!, customVolume!, bottlesPerCase);
                  
                  final entry = BottleEntry(
                    bottleType: bottleType,
                    caseCount: caseCount,
                    looseCount: looseCount,
                  );
                  
                  Navigator.pop(context, entry);
                } else {
                  // エラーメッセージ
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('瓶種と数量を正しく入力してください'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text('追加'),
            ),
          ],
        ),
      ),
    ).then((entry) {
      if (entry != null) {
        setState(() {
          _bottleEntries.add(entry);
        });
      }
    });
  }
  
  void _removeBottleEntry(int index) {
    setState(() {
      _bottleEntries.removeAt(index);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '瓶詰め情報を編集' : '瓶詰め情報登録'),
      ),
      endDrawer: MainDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // 基本情報入力
                  _buildBasicInfoSection(),
                  
                  SizedBox(height: 24),
                  
                  // 瓶種リスト
                  _buildBottleEntriesList(),
                  
                  // 瓶種追加ボタン
                  _buildAddBottleButton(),
                  
                  SizedBox(height: 24),
                  
                  // 計算結果表示
                  _buildCalculationResultsSection(),
                  
                  SizedBox(height: 24),
                  
                  // 保存ボタン
                  ElevatedButton.icon(
                    onPressed: _saveBottlingInfo,
                    icon: Icon(Icons.save),
                    label: Text(_isEdit ? '更新' : '保存'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基本情報',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            // 日付選択
            ListTile(
              title: Text('日付'),
              subtitle: Text('${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}'),
              trailing: Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            
            // 酒名
            TextFormField(
              controller: _sakeNameController,
              decoration: InputDecoration(
                labelText: '酒名',
                hintText: '例: 純米大吟醸 〇〇',
                icon: Icon(Icons.local_drink),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '酒名を入力してください';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16),
            
            // アルコール度数
            TextFormField(
              controller: _alcoholController,
              decoration: InputDecoration(
                labelText: 'アルコール度数 (%)',
                hintText: '例: 15.5',
                icon: Icon(Icons.percent),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'アルコール度数を入力してください';
                }
                if (double.tryParse(value) == null) {
                  return '有効な数値を入力してください';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16),
            
            // 詰残
            TextFormField(
              controller: _remainingController,
              decoration: InputDecoration(
                labelText: '詰残（1.8Lで何本）',
                hintText: '例: 0.5',
                icon: Icon(Icons.water_drop_outlined),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '詰残を入力してください（ない場合は0）';
                }
                if (double.tryParse(value) == null) {
                  return '有効な数値を入力してください';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16),
            
            // 品温（オプション）
            TextFormField(
              controller: _temperatureController,
              decoration: InputDecoration(
                labelText: '品温 (℃)（オプション）',
                hintText: '例: 18.5',
                icon: Icon(Icons.thermostat),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return '有効な数値を入力してください';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBottleEntriesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '瓶種一覧',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        if (_bottleEntries.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '瓶種がまだ追加されていません',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _bottleEntries.length,
            itemBuilder: (context, index) {
              final entry = _bottleEntries[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.liquor),
                  ),
                  title: Text(entry.bottleType.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${entry.caseCount}ケース（${entry.bottleType.bottlesPerCase}本入り）+ ${entry.looseCount}本'),
                      Text('合計: ${entry.totalBottles}本 (${entry.totalVolume.toStringAsFixed(1)}L)'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeBottleEntry(index),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
  
  Widget _buildAddBottleButton() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: _showAddBottleDialog,
          icon: Icon(Icons.add),
          label: Text('瓶種を追加'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCalculationResultsSection() {
    // 総計算
    final totalBottles = _bottleEntries.fold<int>(
      0, (sum, entry) => sum + entry.totalBottles);
    
    final totalVolume = _bottleEntries.fold<double>(
      0, (sum, entry) => sum + entry.totalVolume);
    
    final remainingVolume = double.tryParse(_remainingController.text) ?? 0;
    final alcohol = double.tryParse(_alcoholController.text) ?? 0;
    
    final totalWithRemaining = totalVolume + (remainingVolume * 1.8);
    final pureAlcohol = totalWithRemaining * alcohol / 100;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('計算結果', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(),
            Text('総本数: $totalBottles 本'),
            Text('総容量: ${totalVolume.toStringAsFixed(1)} L'),
            Text('詰残り換算: ${(remainingVolume * 1.8).toStringAsFixed(1)} L'),
            Divider(),
            Text('合計容量: ${totalWithRemaining.toStringAsFixed(1)} L', 
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('純アルコール量: ${pureAlcohol.toStringAsFixed(2)} L', 
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}