import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/services/tank_data_service.dart';
import 'core/services/measurement_service.dart';
import 'core/services/approximation_service.dart';
import 'core/services/storage_service.dart';
import 'core/features/tank_reference/tank_reference_screen.dart';
import 'core/features/dilution/dilution_screen.dart';
import 'core/features/dilution/dilution_plan_manager.dart';
import 'core/features/bottling/bottling_screen.dart';

void main() {
  // アプリケーション初期化時には向きを固定（縦向き）
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
    // 共通サービスのプロバイダー設定
    Provider<TankDataService>(
      create: (_) => TankDataService(),
    ),
    Provider<StorageService>(
      create: (_) => StorageService(),
    ),
    ProxyProvider<TankDataService, MeasurementService>(
      update: (_, tankDataService, __) => MeasurementService(tankDataService),
    ),
    ProxyProvider<TankDataService, ApproximationService>(
      update: (_, tankDataService, __) => ApproximationService(tankDataService),
    ),
    // 画面コントローラーのプロバイダー設定
    ChangeNotifierProxyProvider<StorageService, DilutionPlanManager>(
      create: (context) => DilutionPlanManager(storageService: context.read<StorageService>()),
      update: (context, service, previous) => previous ?? DilutionPlanManager(storageService: service),
    ),
  ],
      child: MaterialApp(
        title: '相原酒造タンク管理',
        theme: ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(0xFF1A5F7A),
    brightness: Brightness.light,
  ),
  appBarTheme: AppBarTheme(
    elevation: 0,
    centerTitle: true,
    backgroundColor: Color(0xFF1A5F7A),
    foregroundColor: Colors.white,
  ),
  cardTheme: CardTheme(
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    filled: true,
    fillColor: Colors.grey[50],
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF1A5F7A),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  // Improved tab styling for better visibility
  tabBarTheme: TabBarTheme(
    labelColor: Colors.white,
    unselectedLabelColor: Colors.white70,
    indicatorColor: Colors.white,
    indicatorSize: TabBarIndicatorSize.tab,
    labelStyle: TextStyle(fontWeight: FontWeight.bold),
    unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
  ),
  fontFamily: 'Noto Sans JP',
),
        initialRoute: '/',
        routes: {
          '/': (context) => HomeScreen(),
          '/quick-reference': (context) => TankReferenceScreen(),
          '/dilution-calculator': (context) => DilutionScreen(),
          '/dilution-plans': (context) => DilutionPlansScreen(),
          '/bottling': (context) => BottlingScreen(),
        },
      ),
    );
  }
}

// ホーム画面
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('相原酒造タンク管理'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'タンク管理アプリ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            _buildFeatureCard(
              context,
              title: 'タンク早見表',
              description: '検尺値と容量の変換を素早く行います',
              icon: Icons.search,
              onTap: () => Navigator.pushNamed(context, '/quick-reference'),
            ),
            _buildFeatureCard(
              context,
              title: '割水計算',
              description: 'アルコール調整のための割水量を計算',
              icon: Icons.calculate,
              onTap: () => Navigator.pushNamed(context, '/dilution-calculator'),
            ),
            _buildFeatureCard(
              context,
              title: '割水計画',
              description: '登録済みの割水計画を管理',
              icon: Icons.list_alt,
              onTap: () => Navigator.pushNamed(context, '/dilution-plans'),
            ),
            _buildFeatureCard(
              context,
              title: '瓶詰め管理',
              description: '瓶詰め情報の登録と管理',
              icon: Icons.liquor,
              onTap: () => Navigator.pushNamed(context, '/bottling'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

// 割水計画一覧画面
class DilutionPlansScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('割水計画管理'),
      ),
      body: Consumer<DilutionPlanManager>(
        builder: (context, planManager, _) {
          if (planManager.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: Theme.of(context).colorScheme.primary,
                  tabs: [
                    Tab(text: '計画中 (${planManager.activePlans.length})'),
                    Tab(text: '完了済み (${planManager.completedPlans.length})'),
                  ],
                  onTap: (index) => planManager.selectTab(index),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // 計画中
                      _buildActivePlansTab(context, planManager),
                      
                      // 完了済み
                      _buildCompletedPlansTab(context, planManager),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/dilution-calculator')
              .then((_) => Provider.of<DilutionPlanManager>(context, listen: false).loadPlans());
        },
        child: Icon(Icons.add),
        tooltip: '新規割水計算',
      ),
    );
  }
  
  Widget _buildActivePlansTab(BuildContext context, DilutionPlanManager planManager) {
    if (planManager.activePlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water_drop_outlined, size: 64, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              '計画中の割水はありません',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('割水計算を作成'),
              onPressed: () => Navigator.pushNamed(context, '/dilution-calculator'),
            ),
          ],
        ),
      );
    }
    
    final tankGroups = planManager.activePlansByTank;
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: tankGroups.length,
      itemBuilder: (context, index) {
        final tankNumber = tankGroups.keys.elementAt(index);
        final plansForTank = tankGroups[tankNumber]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'タンク $tankNumber',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            ...plansForTank.map((plan) => Card(
              child: ListTile(
                title: Text(plan.displayName),
                subtitle: Text(
                  '${plan.initialAlcoholPercentage.toStringAsFixed(1)}% → ${plan.targetAlcoholPercentage.toStringAsFixed(1)}%（水: ${plan.waterToAdd.toStringAsFixed(1)}L）',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DilutionScreen(planToEdit: plan),
                          ),
                        ).then((_) => planManager.loadPlans());
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () async {
                        try {
                          await planManager.completePlan(plan.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('計画を完了としてマークしました')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                    ),
                  ],
                ),
                onTap: () {
                  // 詳細表示
                },
              ),
            )).toList(),
            SizedBox(height: 16),
          ],
        );
      },
    );
  }
  
  Widget _buildCompletedPlansTab(BuildContext context, DilutionPlanManager planManager) {
    if (planManager.completedPlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              '完了した割水計画はありません',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: planManager.completedPlans.length,
      itemBuilder: (context, index) {
        final plan = planManager.completedPlans[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(plan.tankNumber),
              backgroundColor: Colors.green[100],
            ),
            title: Text(plan.displayName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${plan.initialAlcoholPercentage.toStringAsFixed(1)}% → ${plan.targetAlcoholPercentage.toStringAsFixed(1)}%',
                ),
                Text(
                  '完了日: ${plan.completionDate?.toString().substring(0, 10) ?? '不明'}',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                try {
                  await planManager.deletePlan(plan.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('計画を削除しました')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
            onTap: () {
              // 詳細表示
            },
          ),
        );
      },
    );
  }
}