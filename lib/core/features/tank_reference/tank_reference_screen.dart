import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/core/services/tank_data_service.dart';
import '/core/services/measurement_service.dart';
import '/core/services/storage_service.dart';
import '/widgets/tank_selector.dart';
import '/widgets/result_card.dart';
import 'tank_reference_controller.dart';

class TankReferenceScreen extends StatefulWidget {
  @override
  _TankReferenceScreenState createState() => _TankReferenceScreenState();
}

class _TankReferenceScreenState extends State<TankReferenceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TankReferenceController _controller;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _controller = TankReferenceController(
      tankDataService: context.read<TankDataService>(),
      measurementService: context.read<MeasurementService>(),
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
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
        body: Consumer<TankReferenceController>(
          builder: (context, controller, _) {
            return Column(
              children: [
                // タンク選択セクション
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      Text('タンク番号を選択', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      TankSelector(
                        initialValue: controller.selectedTank,
                        onChanged: (value) {
                          if (value != null) controller.selectTank(value);
                        },
                        tankDataService: context.read<TankDataService>(),
                        storageService: context.read<StorageService>(),
                      ),
                    ],
                  ),
                ),
                
                // タブコンテンツ
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // 検尺から容量を計算するタブ
                      _buildMeasurementToCapacityTab(context, controller),
                      
                      // 容量から検尺を計算するタブ
                      _buildCapacityToMeasurementTab(context, controller),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildMeasurementToCapacityTab(BuildContext context, TankReferenceController controller) {
    return Padding(
      padding: EdgeInsets.all(16),
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
                  controller: controller.measurementController,
                  decoration: InputDecoration(
                    labelText: '検尺値 (mm)',
                    hintText: '例: 1250',
                    helperText: 'タンク上部からの距離をmmで入力',
                    prefixIcon: Icon(Icons.straighten),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: controller.isMeasurementCalculating
                      ? null
                      : () {
                          try {
                            controller.calculateCapacity();
                          } catch (e) {
                            _showError(e.toString());
                          }
                        },
                  child: controller.isMeasurementCalculating
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
          
          // 結果表示
          Expanded(
            child: SingleChildScrollView(
              child: controller.isMeasurementCalculating
                  ? Center(child: CircularProgressIndicator())
                  : controller.capacityResult == null
                      ? Center(
                          child: Text(
                            'タンクと検尺を入力して計算ボタンを押してください',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ResultCard.measurementToCapacity(
                          controller.capacityResult!,
                          controller.selectedTank!,
                        ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCapacityToMeasurementTab(BuildContext context, TankReferenceController controller) {
    return Padding(
      padding: EdgeInsets.all(16),
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
                  controller: controller.capacityController,
                  decoration: InputDecoration(
                    labelText: '容量 (L)',
                    hintText: '例: 2500',
                    helperText: 'リットル単位で入力',
                    prefixIcon: Icon(Icons.water_drop),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: controller.isCapacityCalculating
                      ? null
                      : () {
                          try {
                            controller.calculateMeasurement();
                          } catch (e) {
                            _showError(e.toString());
                          }
                        },
                  child: controller.isCapacityCalculating
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
          
          // 結果表示
          Expanded(
            child: SingleChildScrollView(
              child: controller.isCapacityCalculating
                  ? Center(child: CircularProgressIndicator())
                  : controller.measurementResult == null
                      ? Center(
                          child: Text(
                            'タンクと容量を入力して計算ボタンを押してください',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ResultCard.capacityToMeasurement(
                          controller.measurementResult!,
                          controller.selectedTank!,
                        ),
            ),
          ),
        ],
      ),
    );
  }
}