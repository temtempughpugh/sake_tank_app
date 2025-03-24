import 'package:flutter/material.dart';
import '../models/tank.dart';
import '../core/services/tank_data_service.dart';
import '../core/services/storage_service.dart';

/// タンク選択のためのドロップダウンウィジェット
/// タンクカテゴリ別に整理して表示
class TankSelector extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String?> onChanged;
  final TankDataService tankDataService;
  final StorageService storageService;
  final bool showCategoryHeaders;
  final bool autosaveSelection;
  
  const TankSelector({
    Key? key, 
    this.initialValue,
    required this.onChanged,
    required this.tankDataService,
    required this.storageService,
    this.showCategoryHeaders = true,
    this.autosaveSelection = true,
  }) : super(key: key);

  @override
  State<TankSelector> createState() => _TankSelectorState();
}

class _TankSelectorState extends State<TankSelector> {
  String? _selectedTank;
  bool _isLoading = true;
  List<Tank> _tanks = [];
  Map<String, List<Tank>> _tanksByCategory = {};
  
  @override
  void initState() {
    super.initState();
    _selectedTank = widget.initialValue;
    _loadTanks();
  }
  
  Future<void> _loadTanks() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // タンクデータを全て読み込む
      final allTanks = await widget.tankDataService.loadAllTankData();
      
      // カテゴリごとに整理
      final Map<String, List<Tank>> tanksByCategory = {};
      
      for (var tank in allTanks) {
        // tankのcategoryプロパティを使用
        final category = tank.category;
        
        if (!tanksByCategory.containsKey(category)) {
          tanksByCategory[category] = [];
        }
        
        tanksByCategory[category]!.add(tank);
      }
      
      // カテゴリごとにソート
      tanksByCategory.forEach((category, tanks) {
        tanks.sort((a, b) {
          // 特殊名称のタンクは後ろに
          if (a.tankNumber == "仕込水タンク" && b.tankNumber != "仕込水タンク") return 1;
          if (a.tankNumber != "仕込水タンク" && b.tankNumber == "仕込水タンク") return -1;
          
          // No.をトリムして数値比較
          final aNum = a.tankNumber.replaceAll(RegExp(r'No\.'), '').trim();
          final bNum = b.tankNumber.replaceAll(RegExp(r'No\.'), '').trim();
          
          // 数値変換を試みる
          int? aInt = int.tryParse(aNum);
          int? bInt = int.tryParse(bNum);
          
          if (aInt != null && bInt != null) {
            return aInt.compareTo(bInt);
          }
          
          // 数値変換できない場合は文字列比較
          return a.tankNumber.compareTo(b.tankNumber);
        });
      });
      
      setState(() {
        _tanks = allTanks;
        _tanksByCategory = tanksByCategory;
        _isLoading = false;
        
        // 初期値が設定されていない場合は最後に選択したタンクか蔵出しタンクを選択
        if (_selectedTank == null) {
          _initDefaultTank();
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('タンク情報の読み込みに失敗しました: $e');
    }
  }
  
  Future<void> _initDefaultTank() async {
    // 最後に選択したタンクを取得
    final lastTank = await widget.storageService.getLastSelectedTank();
    
    if (lastTank != null && _tanks.any((t) => t.tankNumber == lastTank)) {
      _selectedTank = lastTank;
    } else {
      // 蔵出しタンクを優先
      final releaseSourceTanks = _tanks.where((t) => t.category == '蔵出しタンク').toList();
      if (releaseSourceTanks.isNotEmpty) {
        _selectedTank = releaseSourceTanks.first.tankNumber;
      } else if (_tanks.isNotEmpty) {
        _selectedTank = _tanks.first.tankNumber;
      }
    }
    
    if (_selectedTank != null) {
      widget.onChanged(_selectedTank);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : DropdownButtonFormField<String>(
            value: _selectedTank,
            decoration: InputDecoration(
              labelText: 'タンク番号',
              hintText: 'タンクを選択してください',
              prefixIcon: Icon(Icons.wine_bar),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            isExpanded: true,
            items: _buildDropdownItems(),
            onChanged: (value) {
              if (value != null && !value.startsWith('header_') && !value.startsWith('divider_')) {
                setState(() {
                  _selectedTank = value;
                });
                
                widget.onChanged(value);
                
                // 選択を保存
                if (widget.autosaveSelection) {
                  widget.storageService.saveLastSelectedTank(value);
                }
              }
            },
          );
  }
  
  List<DropdownMenuItem<String>> _buildDropdownItems() {
    // ドロップダウンメニュー項目のリスト
    List<DropdownMenuItem<String>> items = [];
    
    // カテゴリ順序を定義（重要な順）
    final categoryOrder = [
      '蔵出しタンク',
      '貯蔵用サーマルタンク',
      '貯蔵用タンク(冷蔵庫A)',
      '貯蔵用タンク(冷蔵庫B)',
      '貯蔵用タンク',
      '仕込み用タンク',
      '水タンク',
      'その他',
    ];
    
    // カテゴリをソート
    final sortedCategories = _tanksByCategory.keys.toList()
      ..sort((a, b) {
        final indexA = categoryOrder.indexOf(a);
        final indexB = categoryOrder.indexOf(b);
        
        // リストにないカテゴリは後ろに
        if (indexA < 0 && indexB < 0) return a.compareTo(b);
        if (indexA < 0) return 1;
        if (indexB < 0) return -1;
        
        return indexA.compareTo(indexB);
      });
    
    // カテゴリごとにアイテムを追加
    for (final category in sortedCategories) {
      final tanksInCategory = _tanksByCategory[category]!;
      if (tanksInCategory.isEmpty) continue;
      
      // カテゴリヘッダー（有効にする場合）
      if (widget.showCategoryHeaders) {
        items.add(
          DropdownMenuItem<String>(
            value: 'header_$category',
            enabled: false,
            child: Text(
              category,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }
      
      // このカテゴリのタンク
      for (final tank in tanksInCategory) {
        items.add(
          DropdownMenuItem<String>(
            value: tank.tankNumber,
            child: Text(
              tank.tankNumber,
              style: TextStyle(
                color: tank.isLessProminent ? Colors.grey[600] : Colors.black,
                fontStyle: tank.isLessProminent ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        );
      }
      
      // セパレータ（最後のカテゴリ以外）
      if (category != sortedCategories.last && widget.showCategoryHeaders) {
        items.add(
          DropdownMenuItem<String>(
            value: 'divider_$category',
            enabled: false,
            child: Divider(height: 1),
          ),
        );
      }
    }
    
    return items;
  }
}