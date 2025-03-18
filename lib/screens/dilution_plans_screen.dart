// lib/screens/dilution_plans_screen.dart
import 'package:flutter/material.dart';
import '../models/dilution_plan.dart';
import '../services/dilution_service.dart';
import '../screens/dilution_calculator_screen.dart';
import '../widgets/main_drawer.dart';
import '../models/tank_category.dart';

class DilutionPlansScreen extends StatefulWidget {
  @override
  _DilutionPlansScreenState createState() => _DilutionPlansScreenState();
}

class _DilutionPlansScreenState extends State<DilutionPlansScreen> with SingleTickerProviderStateMixin {
  final DilutionService _dilutionService = DilutionService();
  List<DilutionPlan> _plans = [];
  bool _isLoading = true;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlans();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final plans = await _dilutionService.getAllDilutionPlans();
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('計画データの読み込みに失敗しました: $e');
    }
  }
  
  void _editPlan(DilutionPlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DilutionCalculatorScreen(planToEdit: plan),
      ),
    ).then((_) => _loadPlans());
  }
  
  void _confirmCompletePlan(DilutionPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('割水作業を完了としてマークしますか？'),
        content: Text(
          '「はい」を選択すると、この割水計画は完了済みとして記録されます。後から変更することはできません。'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _completePlan(plan.id);
            },
            child: Text('はい、完了しました'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _completePlan(String planId) async {
    try {
      await _dilutionService.completePlan(planId);
      await _loadPlans();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('割水作業を完了しました'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      _showErrorDialog('完了処理中にエラーが発生しました: $e');
    }
  }
  
  void _confirmDeletePlan(DilutionPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('割水計画を削除しますか？'),
        content: Text(
          '「削除」を選択すると、この割水計画は完全に削除されます。この操作は元に戻せません。'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deletePlan(plan.id);
            },
            child: Text('削除'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deletePlan(String planId) async {
    try {
      await _dilutionService.deletePlan(planId);
      await _loadPlans();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('割水計画を削除しました'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      _showErrorDialog('削除中にエラーが発生しました: $e');
    }
  }
  
  void _showDetailDialog(DilutionPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    plan.sakeName.isNotEmpty ? plan.sakeName : 'タンク ${plan.tankNumber}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  if (plan.isCompleted)
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '完了済み',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 16),
                  _buildDetailItem(
                    icon: Icons.calendar_today,
                    label: '計画日',
                    value: _formatDate(plan.plannedDate),
                  ),
                  if (plan.isCompleted)
                    _buildDetailItem(
                      icon: Icons.event_available,
                      label: '完了日',
                      value: _formatDate(plan.completionDate!),
                    ),
                  Divider(),
                  _buildDetailItem(
                    icon: Icons.straighten,
                    label: 'タンク番号',
                    value: plan.tankNumber,
                  ),
                  _buildDetailItem(
                    icon: Icons.water_drop,
                    label: '現在の容量',
                    value: '${plan.initialVolume.toStringAsFixed(1)} L',
                  ),
                  _buildDetailItem(
                    icon: Icons.height,
                    label: '現在の検尺',
                    value: '${plan.initialMeasurement.toStringAsFixed(1)} mm',
                  ),
                  Divider(),
                  _buildDetailItem(
                    icon: Icons.percent,
                    label: '現在のアルコール度数',
                    value: '${plan.initialAlcoholPercentage.toStringAsFixed(2)} %',
                  ),
                  _buildDetailItem(
                    icon: Icons.arrow_downward,
                    label: '目標アルコール度数',
                    value: '${plan.targetAlcoholPercentage.toStringAsFixed(2)} %',
                  ),
                  Divider(),
                  _buildDetailItem(
                    icon: Icons.add,
                    label: '追加する水量',
                    value: '${plan.waterToAdd.toStringAsFixed(1)} L',
                    valueColor: Colors.blue[700],
                  ),
                  _buildDetailItem(
                    icon: Icons.equalizer,
                    label: '割水後の合計容量',
                    value: '${plan.finalVolume.toStringAsFixed(1)} L',
                  ),
                  _buildDetailItem(
                    icon: Icons.straighten,
                    label: '割水後の検尺',
                    value: '${plan.finalMeasurement.toStringAsFixed(1)} mm',
                  ),
                  if (plan.personInCharge.isNotEmpty) ...[
                    Divider(),
                    _buildDetailItem(
                      icon: Icons.person,
                      label: '担当者',
                      value: plan.personInCharge,
                    ),
                  ],
                  SizedBox(height: 20),
                  if (!plan.isCompleted) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.edit),
                            label: Text('編集'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _editPlan(plan);
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.check_circle),
                            label: Text('完了'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _confirmCompletePlan(plan);
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: Icon(Icons.delete),
                      label: Text('削除'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        minimumSize: Size(double.infinity, 0),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDeletePlan(plan);
                      },
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      icon: Icon(Icons.delete),
                      label: Text('履歴から削除'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        minimumSize: Size(double.infinity, 0),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDeletePlan(plan);
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
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
    // 計画中と完了済みに分類
    final List<DilutionPlan> activePlans = _plans.where((plan) => !plan.isCompleted).toList();
    final List<DilutionPlan> completedPlans = _plans.where((plan) => plan.isCompleted).toList();
    
    // タンク別にグループ化
    final Map<String, List<DilutionPlan>> activePlansByTank = {};
    for (var plan in activePlans) {
      if (!activePlansByTank.containsKey(plan.tankNumber)) {
        activePlansByTank[plan.tankNumber] = [];
      }
      activePlansByTank[plan.tankNumber]!.add(plan);
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('割水計画管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '計画中 (${activePlans.length})'),
            Tab(text: '完了済み (${completedPlans.length})'),
          ],
        ),
      ),
      endDrawer: MainDrawer(), // Use the shared drawer
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // 計画中タブ
                activePlans.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.water_drop_outlined,
                        message: '計画中の割水はありません',
                        buttonLabel: '割水計算を作成する',
                        onButtonPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DilutionCalculatorScreen(),
                            ),
                          ).then((_) => _loadPlans());
                        },
                      )
                    : activePlansByTank.isEmpty
                        ? Center(child: CircularProgressIndicator())
                        : _buildActivePlansList(activePlansByTank),
                
                // 完了済みタブ
                completedPlans.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.task_alt,
                        message: '完了した割水作業はありません',
                      )
                    : _buildCompletedPlansList(completedPlans),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DilutionCalculatorScreen()),
          ).then((_) => _loadPlans());
        },
        child: Icon(Icons.add),
        tooltip: '新しい割水計算',
      ),
    );
  }
  
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? buttonLabel,
    VoidCallback? onButtonPressed,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          if (buttonLabel != null && onButtonPressed != null) ...[
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text(buttonLabel),
              onPressed: onButtonPressed,
            ),
          ],
        ],
      ),
    );
  }
  
  // _buildActivePlansList メソッドの修正
Widget _buildActivePlansList(Map<String, List<DilutionPlan>> activePlansByTank) {
  // カテゴリごとにタンクを整理
  Map<String, List<String>> tanksByCategory = {};
  List<TankCategory> categories = TankCategories.getCategories();
  
  // カテゴリごとに初期化
  for (var category in categories) {
    tanksByCategory[category.name] = [];
  }
  
  // タンクをカテゴリに割り当て
  for (var tankNumber in activePlansByTank.keys) {
    var category = TankCategories.getCategoryForTank(tankNumber);
    tanksByCategory[category.name]!.add(tankNumber);
  }
  
  return ListView.builder(
    itemCount: categories.length,
    itemBuilder: (context, categoryIndex) {
      final category = categories[categoryIndex];
      final tanksInCategory = tanksByCategory[category.name] ?? [];
      
      // カテゴリにタンクがなければスキップ
      if (tanksInCategory.isEmpty) {
        return SizedBox.shrink();
      }
      
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
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '${category.name}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: category.color ?? Theme.of(context).primaryColor,
              ),
            ),
          ),
          ...tanksInCategory.expand((tankNumber) {
            final plans = activePlansByTank[tankNumber] ?? [];
            return [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'タンク $tankNumber',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              ...plans.map((plan) => _buildPlanCard(plan)).toList(),
            ];
          }).toList(),
        ],
      );
    },
  );
}
  
  Widget _buildCompletedPlansList(List<DilutionPlan> completedPlans) {
    // 完了日の新しい順にソート
    completedPlans.sort((a, b) => 
      b.completionDate!.compareTo(a.completionDate!));
      
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: completedPlans.length,
      itemBuilder: (context, index) {
        final plan = completedPlans[index];
        return _buildCompletedPlanCard(plan);
      },
    );
  }
  
  Widget _buildPlanCard(DilutionPlan plan) {
    final displayName = plan.sakeName.isNotEmpty
        ? plan.sakeName
        : '無題の割水計画';
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _showDetailDialog(plan),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatDate(plan.plannedDate),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          '現在のアルコール度数',
                          '${plan.initialAlcoholPercentage.toStringAsFixed(1)}%',
                        ),
                        _buildInfoRow(
                          '目標アルコール度数',
                          '${plan.targetAlcoholPercentage.toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          '追加する水量',
                          '${plan.waterToAdd.toStringAsFixed(1)} L',
                        ),
                        _buildInfoRow(
                          '割水後の容量',
                          '${plan.finalVolume.toStringAsFixed(1)} L',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (plan.personInCharge.isNotEmpty) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      '担当: ${plan.personInCharge}',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: Icon(Icons.edit, size: 18),
                    label: Text('編集'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      side: BorderSide(color: Colors.blue),
                    ),
                    onPressed: () => _editPlan(plan),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.check_circle, size: 18),
                    label: Text('完了'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () => _confirmCompletePlan(plan),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCompletedPlanCard(DilutionPlan plan) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _showDetailDialog(plan),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green[50],
                        radius: 16,
                        child: Text(
                          plan.tankNumber,
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '完了',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatDateWithTime(plan.completionDate!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                plan.sakeName.isNotEmpty ? plan.sakeName : '無題の割水作業',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${plan.initialAlcoholPercentage.toStringAsFixed(1)}% → ${plan.targetAlcoholPercentage.toStringAsFixed(1)}%（水量: ${plan.waterToAdd.toStringAsFixed(1)} L）',
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
              if (plan.personInCharge.isNotEmpty) ...[
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      '担当: ${plan.personInCharge}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  // 日付のフォーマット用ヘルパーメソッド
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
  
  // 時間付き日付フォーマット
  String _formatDateWithTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}