import 'package:flutter/material.dart';
import '../services/csv_service.dart';
import '../models/tank_data.dart';
import '../models/measurement_result.dart';
import '../models/tank_category.dart';
import '../widgets/main_drawer.dart';

class QuickReferenceScreen extends StatefulWidget {
  @override
  _QuickReferenceScreenState createState() => _QuickReferenceScreenState();
}

class _QuickReferenceScreenState extends State<QuickReferenceScreen> with SingleTickerProviderStateMixin {
  final CsvService _csvService = CsvService();
  List<String> _availableTanks = [];
  String? _selectedTank;
  bool _isLoading = true;
  late TabController _tabController;
  
  // For tank categorization
  List<TankCategory> _categories = [];
  Map<String, List<String>> _categoryTanks = {};
  Map<String, bool> _expandedCategories = {};
  
  // 検尺タブの状態管理
  final TextEditingController _measurementController = TextEditingController();
  MeasurementResult? _capacityResult;
  bool _isMeasurementCalculating = false;
  
  // 容量タブの状態管理
  final TextEditingController _capacityController = TextEditingController();
  MeasurementResult? _measurementResult;
  bool _isCapacityCalculating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTanks();
    
    // Initialize categories
    _categories = TankCategories.getCategories();
    
    // Set all categories as expanded initially
    for (var category in _categories) {
      _expandedCategories[category.name] = true;
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _measurementController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  // タンク番号のクリーニングユーティリティ
  String _cleanTankNumber(String tankNumber) {
    if (tankNumber == "仕込水タンク") return tankNumber;
    return tankNumber.replaceAll(RegExp(r'(?i)No\.|N0\.'), '').trim();
  }

  Future<void> _loadTanks() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final tanks = await _csvService.getAvailableTankNumbers();
      
      // Group tanks by category
      Map<String, List<String>> categoryTanks = {};
      for (var category in _categories) {
        categoryTanks[category.name] = [];
      }
      
      // Assign each tank to its category
      for (var tank in tanks) {
        final cleanTankNumber = _cleanTankNumber(tank);
        
        bool assigned = false;
        for (var category in _categories.where((c) => c.name != 'その他')) {
          if (category.tankNumbers.contains(cleanTankNumber)) {
            categoryTanks[category.name]!.add(tank);
            assigned = true;
            break;
          }
        }
        
        if (!assigned) {
          // Add to "Others" category
          categoryTanks['その他']!.add(tank);
        }
      }
      
      // Sort tanks within each category
      for (var category in categoryTanks.keys) {
        categoryTanks[category]!.sort((a, b) {
          // 特殊なタンク名（数字でない）は後ろに
          bool aIsSpecial = !RegExp(r'^\d+$').hasMatch(_cleanTankNumber(a));
          bool bIsSpecial = !RegExp(r'^\d+$').hasMatch(_cleanTankNumber(b));
          
          if (aIsSpecial && !bIsSpecial) return 1;
          if (!aIsSpecial && bIsSpecial) return -1;
          if (aIsSpecial && bIsSpecial) return a.compareTo(b);
          
          // 数値で比較
          return int.parse(_cleanTankNumber(a)).compareTo(int.parse(_cleanTankNumber(b)));
        });
      }
      
      setState(() {
        _availableTanks = tanks;
        _categoryTanks = categoryTanks;
        _isLoading = false;
        
        // Set initial selected tank if available
        if (tanks.isNotEmpty) {
          // Try to select a commonly used tank first
          if (tanks.any((t) => _cleanTankNumber(t) == '16')) { // 蔵出しタンク
            _selectedTank = tanks.firstWhere((t) => _cleanTankNumber(t) == '16');
          } else if (tanks.isNotEmpty) {
            _selectedTank = tanks.first;
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('タンクデータの読み込みに失敗しました: $e');
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
  
  // Toggle category expansion
  void _toggleCategory(String categoryName) {
    setState(() {
      _expandedCategories[categoryName] = !(_expandedCategories[categoryName] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('タンク早見表'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.arrow_downward), text: '検尺から容量'),
            Tab(icon: Icon(Icons.arrow_upward), text: '容量から検尺'),
          ],
        ),
      ),
      endDrawer: MainDrawer(), // Use the shared main drawer
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // タンク選択部分 - Replaced with categorized dropdown
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('タンク番号: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedTank,
                              isExpanded: true,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              hint: Text('タンクを選択'),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedTank = newValue;
                                  // 選択変更時にリセット
                                  _capacityResult = null;
                                  _measurementResult = null;
                                });
                              },
                              items: _buildDropdownItems(),
                            ),
                          ),
                        ],
                      ),
                      // Add "Show categorized view" button
                      TextButton.icon(
                        icon: Icon(Icons.category),
                        label: Text('カテゴリー別にタンクを表示'),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20))
                            ),
                            builder: (context) => _buildCategorizedTankSelector(),
                          );
                        },
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
                      _buildMeasurementToCapacityTab(),
                      
                      // 容量から検尺を計算するタブ（逆引き）
                      _buildCapacityToMeasurementTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  // Build dropdown menu items with category headers
  List<DropdownMenuItem<String>> _buildDropdownItems() {
    List<DropdownMenuItem<String>> items = [];
    
    // Add items for each category
    for (var category in _categories) {
      // Add category header if it has tanks
      final tanksInCategory = _categoryTanks[category.name] ?? [];
      if (tanksInCategory.isNotEmpty) {
        items.add(
          DropdownMenuItem<String>(
            enabled: false,
            child: Text(
              category.name,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            value: '${category.name}_header', // Dummy value, not selectable
          )
        );
        
        // Add tanks in this category
        for (var tankNumber in tanksInCategory) {
          final cleanNumber = _cleanTankNumber(tankNumber);
          bool isLessProminent = TankCategories.isLessProminentTank(cleanNumber);
          
          items.add(
            DropdownMenuItem<String>(
              value: tankNumber,
              child: Text(
                tankNumber, // タンク番号をそのまま表示
                style: TextStyle(
                  color: isLessProminent ? Colors.grey : Colors.black,
                  fontStyle: isLessProminent ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            )
          );
        }
        
        // Add divider after category if not the last one
        if (category != _categories.last) {
          items.add(
            DropdownMenuItem<String>(
              enabled: false,
              child: Divider(height: 1),
              value: '${category.name}_divider', // Dummy value, not selectable
            )
          );
        }
      }
    }
    
    return items;
  }
  
  // Build categorized tank selector in bottom sheet
  Widget _buildCategorizedTankSelector() {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'タンク選択',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final tanks = _categoryTanks[category.name] ?? [];
                    
                    // Skip empty categories
                    if (tanks.isEmpty) return SizedBox.shrink();
                    
                    final isExpanded = _expandedCategories[category.name] ?? false;
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: Column(
                        children: [
                          // Category header (tappable to expand/collapse)
                          ListTile(
                            title: Text(
                              category.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: category.color ?? Theme.of(context).primaryColor,
                              ),
                            ),
                            trailing: Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                            ),
                            onTap: () => _toggleCategory(category.name),
                          ),
                          
                          // Tank list (if expanded)
                          if (isExpanded)
                            Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: tanks.map((tankNumber) {
                                  final isSelected = tankNumber == _selectedTank;
                                  final isLessProminent = TankCategories.isLessProminentTank(_cleanTankNumber(tankNumber));
                                  
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedTank = tankNumber;
                                        _capacityResult = null;
                                        _measurementResult = null;
                                      });
                                      Navigator.pop(context); // Close the modal
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                          ? (category.color ?? Theme.of(context).primaryColor) 
                                          : isLessProminent 
                                            ? Colors.grey[200] 
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected 
                                            ? (category.color ?? Theme.of(context).primaryColor) 
                                            : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Text(
                                        tankNumber, // タンク番号をそのまま表示
                                        style: TextStyle(
                                          color: isSelected 
                                            ? Colors.white 
                                            : isLessProminent 
                                              ? Colors.grey[600] 
                                              : Colors.black,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildMeasurementToCapacityTab() {
    return Padding(
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
                    hintText: '例: 1250',
                    helperText: 'タンク上部からの距離をmmで入力',
                    prefixIcon: Icon(Icons.straighten),
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
            _buildErrorCard('データが見つかりません', '入力された検尺値に対応するデータが存在しません。')
          ] else if (_capacityResult!.isOverLimit) ...[
            _buildErrorCard(
              '検尺上限を越えています',
              '入力された検尺値（${_measurementController.text} mm）はこのタンクの上限を超えています。有効な範囲内の検尺値を入力してください。'
            )
          ] else ...[
            _buildResultCard(
              '検尺から容量の計算結果',
              !_capacityResult!.isExactMatch ? '指定した検尺値に正確にマッチするデータがないため、近似値を表示しています' : null,
              {
                'タンク番号:': '$_selectedTank',
                '検尺:': '${_measurementController.text} mm',
                '容量:': '${_capacityResult!.capacity.toStringAsFixed(1)} L',
              },
              '容量'
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildCapacityToMeasurementTab() {
    return Padding(
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
                    hintText: '例: 2500',
                    helperText: 'リットル単位で入力',
                    prefixIcon: Icon(Icons.water_drop),
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
            _buildErrorCard('データが見つかりません', '入力された容量に対応するデータが存在しません。')
          ] else if (_measurementResult!.isOverCapacity) ...[
            _buildErrorCard(
              '容量をオーバーしています',
              '入力された容量（${_capacityController.text} L）はこのタンクの最大容量を超えています。'
              '\n最大容量: ${_measurementResult!.capacity.toStringAsFixed(1)} L（検尺: ${_measurementResult!.measurement.toStringAsFixed(1)} mm）'
              '\n\n検尺が0の時が最大容量です。これ以上の逆引きはできません。'
            )
          ] else if (_measurementResult!.isOverLimit) ...[
            _buildErrorCard(
              '検尺上限を越えています',
              '入力された容量（${_capacityController.text} L）に対応する検尺値はこのタンクの上限を超えています。'
              '\n最小容量: ${_measurementResult!.capacity.toStringAsFixed(1)} L（検尺: ${_measurementResult!.measurement.toStringAsFixed(1)} mm）'
            )
          ] else ...[
            _buildResultCard(
              '容量から検尺の計算結果',
              !_measurementResult!.isExactMatch ? '指定した容量に正確にマッチするデータがないため、近似値を表示しています' : null,
              {
                'タンク番号:': '$_selectedTank',
                '希望容量:': '${_capacityController.text} L',
                if (!_measurementResult!.isExactMatch) 
                  '実際の容量:': '${_measurementResult!.capacity.toStringAsFixed(1)} L',
                '必要な検尺:': '${_measurementResult!.measurement.toStringAsFixed(1)} mm',
              },
              '検尺'
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildErrorCard(String title, String message) {
    return Card(
      elevation: 2,
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
                  title,
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
              message,
              style: TextStyle(color: Colors.red[800]),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultCard(String title, String? warning, Map<String, String> data, String highlightKey) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title, 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            Divider(),
            if (warning != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  warning,
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            ],
            ...data.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key),
                  Text(
                    entry.value, 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: entry.key.contains(highlightKey) ? 20 : 16,
                      color: entry.key.contains(highlightKey) 
                        ? Theme.of(context).primaryColor 
                        : null,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}