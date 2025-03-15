import 'package:flutter/material.dart';
import '../models/dilution_plan.dart';
import '../services/dilution_service.dart';
import '../widgets/task_category_card.dart';


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DilutionService _dilutionService = DilutionService();
  bool _isLoading = true;
  List<DilutionPlan> _activePlans = [];
  
  @override
  void initState() {
    super.initState();
    _loadActivePlans();
  }
  
  Future<void> _loadActivePlans() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final plans = await _dilutionService.getAllDilutionPlans();
      setState(() {
        _activePlans = plans.where((plan) => !plan.isCompleted).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('データの読み込みに失敗しました: $e');
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
        title: Text('相原酒造タンク管理'),
      ),
      endDrawer: _buildDrawer(),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadActivePlans,
            child: _buildHomeContent(),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))
            ),
            builder: (context) => _buildQuickActionSheet(),
          );
        },
        child: Icon(Icons.add),
        tooltip: '新規作業',
      ),
    );
  }
  
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '相原酒造タンク管理',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '製造工程管理アプリ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.table_chart,
            title: '早見表',
            onTap: () {
              Navigator.pushNamed(context, '/quick-reference').then((_) => _loadActivePlans());
            },
          ),
          ExpansionTile(
            leading: Icon(Icons.water_drop),
            title: Text('蔵出し'),
            children: [
              _buildDrawerNestedItem(
                title: '蔵出し計画',
                onTap: () {
                  Navigator.pushNamed(context, '/shipping-plans').then((_) => _loadActivePlans());
                },
              ),
              _buildDrawerNestedItem(
                title: '割水計算',
                onTap: () {
                  Navigator.pushNamed(context, '/dilution-calculator').then((_) => _loadActivePlans());
                },
              ),
              _buildDrawerNestedItem(
                title: '割水計画',
                onTap: () {
                  Navigator.pushNamed(context, '/dilution-plans').then((_) => _loadActivePlans());
                },
              ),
            ],
          ),
          _buildDrawerItem(
            icon: Icons.liquor,
            title: '瓶詰め',
            onTap: () => Navigator.pushNamed(context, '/bottling'),
          ),
          _buildDrawerItem(
            icon: Icons.filter_alt,
            title: 'ろ過',
            onTap: () => Navigator.pushNamed(context, '/filtering'),
          ),
          _buildDrawerItem(
            icon: Icons.whatshot,
            title: '火入れ',
            onTap: () => Navigator.pushNamed(context, '/pasteurization'),
          ),
          _buildDrawerItem(
            icon: Icons.science,
            title: '調合',
            onTap: () => Navigator.pushNamed(context, '/blending'),
          ),
          Divider(),
          _buildDrawerItem(
            icon: Icons.settings,
            title: '設定',
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
  
  Widget _buildDrawerNestedItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.only(left: 72, right: 16),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildHomeContent() {
    // Group active plans by category
    final Map<String, List<DilutionPlan>> plansByCategory = {
      '割水': [],
      '蔵出し': [],
      '瓶詰め': [],
      'ろ過': [],
      '火入れ': [],
      '調合': [],
    };
    
    // For now, all plans are categorized as dilution
    // This can be expanded later when more plan types are added
    for (var plan in _activePlans) {
      plansByCategory['割水']!.add(plan);
    }

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Only show categories with active plans
        if (plansByCategory['割水']!.isNotEmpty)
          TaskCategoryCard(
            title: '割水',
            icon: Icons.water_drop,
            plans: plansByCategory['割水']!,
            onSeeAll: () => Navigator.pushNamed(context, '/dilution-plans').then((_) => _loadActivePlans()),
          ),
          
        if (plansByCategory['蔵出し']!.isNotEmpty)  
          TaskCategoryCard(
            title: '蔵出し',
            icon: Icons.local_shipping,
            plans: plansByCategory['蔵出し']!,
            onSeeAll: () => Navigator.pushNamed(context, '/shipping-plans'),
          ),
          
        if (plansByCategory['瓶詰め']!.isNotEmpty)
          TaskCategoryCard(
            title: '瓶詰め',
            icon: Icons.liquor,
            plans: plansByCategory['瓶詰め']!,
            onSeeAll: () => Navigator.pushNamed(context, '/bottling-plans'),
          ),
          
        if (plansByCategory['ろ過']!.isNotEmpty)
          TaskCategoryCard(
            title: 'ろ過',
            icon: Icons.filter_alt,
            plans: plansByCategory['ろ過']!,
            onSeeAll: () => Navigator.pushNamed(context, '/filtering-plans'),
          ),
          
        if (plansByCategory['火入れ']!.isNotEmpty)
          TaskCategoryCard(
            title: '火入れ',
            icon: Icons.whatshot,
            plans: plansByCategory['火入れ']!,
            onSeeAll: () => Navigator.pushNamed(context, '/pasteurization-plans'),
          ),
          
        if (plansByCategory['調合']!.isNotEmpty)
          TaskCategoryCard(
            title: '調合',
            icon: Icons.science,
            plans: plansByCategory['調合']!,
            onSeeAll: () => Navigator.pushNamed(context, '/blending-plans'),
          ),
          
        // If no active plans, show empty state
        if (_activePlans.isEmpty)
          _buildEmptyState(),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 80),
          Icon(
            Icons.task_alt,
            size: 80,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            '作業予定がありません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '右下の「+」ボタンから新しい作業を登録できます',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActionSheet() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '新規作業登録',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          _buildActionButton(
            label: '割水計算',
            icon: Icons.water_drop,
            color: Colors.blue,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/dilution-calculator').then((_) => _loadActivePlans());
            },
          ),
          SizedBox(height: 12),
          _buildActionButton(
            label: '蔵出し計画',
            icon: Icons.local_shipping,
            color: Colors.green,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/shipping-plans').then((_) => _loadActivePlans());
            },
          ),
          SizedBox(height: 12),
          _buildActionButton(
            label: '瓶詰め計画',
            icon: Icons.liquor,
            color: Colors.amber[700]!,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/bottling-plans').then((_) => _loadActivePlans());
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}