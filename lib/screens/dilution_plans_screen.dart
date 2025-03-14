import 'package:flutter/material.dart';
import '../models/dilution_plan.dart';
import '../services/dilution_service.dart';
import '../services/csv_service.dart';

class DilutionPlansScreen extends StatefulWidget {
  @override
  _DilutionPlansScreenState createState() => _DilutionPlansScreenState();
}

class _DilutionPlansScreenState extends State<DilutionPlansScreen> with SingleTickerProviderStateMixin {
  final DilutionService _dilutionService = DilutionService();
  final CsvService _csvService = CsvService();
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
  
  Future<void> _completePlan(String planId) async {
    try {
      await _dilutionService.completePlan(planId);
      await _loadPlans();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('割水作業を完了しました')),
      );
    } catch (e) {
      _showErrorDialog('完了処理中にエラーが発生しました: $e');
    }
  }
  
  Future<void> _deletePlan(String planId) async {
    try {
      await _dilutionService.deletePlan(planId);
      await _loadPlans();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('割水計画を削除しました')),
      );
    } catch (e) {
      _showErrorDialog('削除中にエラーが発生しました: $e');
    }
  }
  
  void _showDetailDialog(DilutionPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(plan.sakeName.isNotEmpty ? plan.sakeName : 'タンク ${plan.tankNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('タンク番号', plan.tankNumber),
              _buildDetailRow('現在の容量', '${plan.initialVolume.toStringAsFixed(1)} L'),
              _buildDetailRow('検尺値', '${plan.initialMeasurement.toStringAsFixed(1)} mm'),
              _buildDetailRow('現在のアルコール度数', '${plan.initialAlcoholPercentage.toStringAsFixed(2)} %'),
              _buildDetailRow('目標アルコール度数', '${plan.targetAlcoholPercentage.toStringAsFixed(2)} %'),
              _buildDetailRow('追加する水量', '${plan.waterToAdd.toStringAsFixed(1)} L'),
              _buildDetailRow('割水後の合計容量', '${plan.finalVolume.toStringAsFixed(1)} L'),
              _buildDetailRow('割水後の検尺', '${plan.finalMeasurement.toStringAsFixed(1)} mm'),
              if (plan.personInCharge.isNotEmpty)
                _buildDetailRow('担当者', plan.personInCharge),
              _buildDetailRow('計画日', _formatDate(plan.plannedDate)),
              if (plan.isCompleted)
                _buildDetailRow('完了日', _formatDate(plan.completionDate!)),
            ],
          ),
        ),
        actions: [
          if (!plan.isCompleted)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _completePlan(plan.id);
              },
              child: Text('完了'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePlan(plan.id);
            },
            child: Text('削除'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('閉じる'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: '最新の情報に更新',
            onPressed: _loadPlans,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // 計画中タブ
                activePlans.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.water_drop_outlined, size: 64, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              '計画中の割水はありません',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('割水計算を作成する'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: activePlansByTank.keys.length,
                        itemBuilder: (context, index) {
                          final tankNumber = activePlansByTank.keys.elementAt(index);
                          final plans = activePlansByTank[tankNumber]!;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: Text(
                                  'タンク $tankNumber',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              ...plans.map((plan) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Card(
                                  child: InkWell(
                                    onTap: () => _showDetailDialog(plan),
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
                                                  plan.sakeName.isNotEmpty ? plan.sakeName : '無題の割水計画',
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
                                          SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              TextButton.icon(
                                                icon: Icon(Icons.check_circle, size: 18),
                                                label: Text('完了'),
                                                onPressed: () => _completePlan(plan.id),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.green,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              TextButton.icon(
                                                icon: Icon(Icons.delete, size: 18),
                                                label: Text('削除'),
                                                onPressed: () => _deletePlan(plan.id),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )).toList(),
                            ],
                          );
                        },
                      ),
                
                // 完了済みタブ
                completedPlans.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              '完了した割水作業はありません',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: completedPlans.length,
                        itemBuilder: (context, index) {
                          final plan = completedPlans[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Card(
                              child: InkWell(
                                onTap: () => _showDetailDialog(plan),
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
                                              Icon(
                                                Icons.check_circle,
                                                size: 16,
                                                color: Colors.green,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'タンク ${plan.tankNumber}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '完了: ${_formatDate(plan.completionDate!)}',
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
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '${plan.initialAlcoholPercentage.toStringAsFixed(1)}% → ${plan.targetAlcoholPercentage.toStringAsFixed(1)}%（水量: ${plan.waterToAdd.toStringAsFixed(1)} L）',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Icon(Icons.add),
        tooltip: '新しい割水計算',
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
    return '${date.year}/${date.month}/${date.day}';
  }
}