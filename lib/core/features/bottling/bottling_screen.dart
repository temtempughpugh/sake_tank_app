import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models/bottling_info.dart';
import '/core/services/storage_service.dart';
import '/core/utils/formatters.dart';
import 'bottling_controller.dart';

class BottlingScreen extends StatefulWidget {
  final BottlingInfo? bottlingToEdit;
  
  const BottlingScreen({Key? key, this.bottlingToEdit}) : super(key: key);
  
  @override
  _BottlingScreenState createState() => _BottlingScreenState();
}

class _BottlingScreenState extends State<BottlingScreen> {
  late BottlingController _controller;
  final _formKey = GlobalKey<FormState>();
  
  @override
  void initState() {
    super.initState();
    
    _controller = BottlingController(
      storageService: context.read<StorageService>(),
    );
    
    if (widget.bottlingToEdit != null) {
      _controller.setEditMode(widget.bottlingToEdit!);
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _controller.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      _controller.selectDate(picked);
    }
  }
  
  Future<void> _showAddBottleDialog() async {
    BottleType? selectedType;
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
                // 瓶種選択
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
                
                // ケース入数設定
                TextField(
                  decoration: InputDecoration(
                    labelText: 'ケース入数',
                    hintText: selectedType != null 
                      ? '${selectedType!.bottlesPerCase}本入り' 
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
                          selectedType!.updateBottlesPerCase(newCount);
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
                if ((selectedType != null || (customVolume != null)) &&
                    caseCount >= 0 && looseCount >= 0 && 
                    (caseCount > 0 || looseCount > 0)) {
                  
                  final bottleType = selectedType ?? 
                    BottleType.custom(customVolume!, bottlesPerCase);
                  
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
        _controller.addBottleEntry(entry);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<BottlingController>(
            builder: (context, controller, _) =>
              Text(controller.isEditMode ? '瓶詰め情報を編集' : '瓶詰め情報登録'),
          ),
        ),
        body: Consumer<BottlingController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return Center(child: CircularProgressIndicator());
            }
            
            return Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // 基本情報入力
                  Card(
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
                            subtitle: Text(Formatters.formatDate(controller.selectedDate)),
                            trailing: Icon(Icons.calendar_today),
                            onTap: () => _selectDate(context),
                          ),
                          
                          // 酒名
                          TextFormField(
                            controller: controller.sakeNameController,
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
                            controller: controller.alcoholController,
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
                            controller: controller.remainingController,
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
                            controller: controller.temperatureController,
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
                  ),
                  
                  SizedBox(height: 16),
                  
                  // 瓶種一覧
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '瓶種一覧',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      controller.bottleEntries.isEmpty
                        ? Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                '瓶種がまだ追加されていません',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: controller.bottleEntries.length,
                            itemBuilder: (context, index) {
                              final entry = controller.bottleEntries[index];
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
                                    onPressed: () => controller.removeBottleEntry(index),
                                  ),
                                ),
                              );
                            },
                          ),
                      
                      // 瓶種追加ボタン
                      Padding(
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
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 24),
                  
                  // 計算結果表示
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('計算結果', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          
                          Divider(),
                          Text('総本数: ${controller.totalBottles.toInt()} 本'),
                          Text('総容量: ${controller.totalVolume.toStringAsFixed(1)} L'),
                          Text('詰残り換算: ${controller.remainingVolume.toStringAsFixed(1)} L'),
                          
                          // 瓶種ごとの小計表示
                          if (controller.bottleEntries.isNotEmpty) ...[
                            SizedBox(height: 8),
                            Text('瓶種別集計:', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            
                            ...List.generate(controller.bottleEntries.length, (index) {
                              final entry = controller.bottleEntries[index];
                              final bottleAlcohol = entry.totalVolume * controller.alcoholPercentage / 100;
                              
                              return Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text('${entry.bottleType.name}:'),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text('${entry.totalBottles}本 (${entry.totalVolume.toStringAsFixed(1)}L)'),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('純AL: ${bottleAlcohol.toStringAsFixed(2)}L'),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            
                            Divider(),
                          ],
                          
                          Divider(),
                          Text('合計容量: ${controller.totalWithRemaining.toStringAsFixed(1)} L', 
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('純アルコール量: ${controller.pureAlcohol.toStringAsFixed(2)} L', 
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // 保存ボタン
                  ElevatedButton.icon(
                    onPressed: controller.bottleEntries.isEmpty
                        ? null
                        : () {
                            if (!_formKey.currentState!.validate()) return;
                            
                            try {
                              controller.saveBottlingInfo();
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(controller.isEditMode ? '瓶詰め情報を更新しました' : '瓶詰め情報を保存しました'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              
                              Navigator.pop(context, true);
                            } catch (e) {
                              _showError(e.toString());
                            }
                          },
                    icon: Icon(Icons.save),
                    label: Text(controller.isEditMode ? '更新' : '保存'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}