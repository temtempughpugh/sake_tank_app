import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/core/services/tank_data_service.dart';
import '/core/services/measurement_service.dart';
import '/core/services/approximation_service.dart';
import '/core/services/storage_service.dart';
import '/widgets/tank_selector.dart';
import '/widgets/measurement_input.dart';
import '/widgets/result_card.dart';
import '/core/utils/validators.dart';
import '/models/measurement_result.dart';
import 'dilution_controller.dart';

class DilutionScreen extends StatefulWidget {
  final DilutionPlan? planToEdit;
  
  const DilutionScreen({Key? key, this.planToEdit}) : super(key: key);
  
  @override
  _DilutionScreenState createState() => _DilutionScreenState();
}

class _DilutionScreenState extends State<DilutionScreen> {
  late DilutionController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    
    // コントローラー初期化
    _controller = DilutionController(
      tankDataService: context.read<TankDataService>(),
      measurementService: context.read<MeasurementService>(),
      approximationService: context.read<ApproximationService>(),
      storageService: context.read<StorageService>(),
    );
    
    // 編集モードの場合は既存データを読み込む
    if (widget.planToEdit != null) {
      _controller.setEditMode(widget.planToEdit!);
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

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      await _controller.saveDilutionPlan();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.isEditMode ? '割水計画を更新しました' : '割水計画を保存しました'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      Navigator.pop(context, true);
    } catch (e) {
      _showError('保存に失敗しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<DilutionController>(
            builder: (context, controller, _) => 
              Text(controller.isEditMode ? '割水計画を編集' : '割水計算'),
          ),
        ),
        body: Consumer<DilutionController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return Center(child: CircularProgressIndicator());
            }
            
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // タンク選択
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'タンク選択',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),
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
                    ),
                    
                    SizedBox(height: 16),
                    
                    // 検尺・容量入力
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '現在の状態',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),
                            MeasurementInputPair(
                              measurementController: controller.measurementController,
                              volumeController: controller.initialVolumeController,
                              tankNumber: controller.selectedTank,
                              measurementApproximations: controller.measurementApproximations,
                              volumeApproximations: controller.volumeApproximations,
                              isLoadingMeasurementApproximations: controller.isLoadingMeasurementApproximations,
                              isLoadingVolumeApproximations: controller.isLoadingVolumeApproximations,
                              onMeasurementApproximationSelected: (value, paired) => 
                                controller.selectMeasurementApproximation(value, paired),
                              onVolumeApproximationSelected: (value, paired) => 
                                controller.selectVolumeApproximation(value, paired),
                              onCalculateVolume: () {
                                try {
                                  controller.calculateCapacityFromMeasurement();
                                } catch (e) {
                                  _showError(e.toString());
                                }
                              },
                              onCalculateMeasurement: () {
                                try {
                                  controller.calculateMeasurementFromCapacity();
                                } catch (e) {
                                  _showError(e.toString());
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // アルコール度数入力
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'アルコール度数',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: controller.initialAlcoholController,
                                    decoration: InputDecoration(
                                      labelText: '現在のアルコール度数（%）',
                                      hintText: '例: 18.5',
                                      prefixIcon: Icon(Icons.percent),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) => Validators.validateAlcoholPercentage(value),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: controller.targetAlcoholController,
                                    decoration: InputDecoration(
                                      labelText: '目標アルコール度数（%）',
                                      hintText: '例: 15.5',
                                      prefixIcon: Icon(Icons.arrow_downward),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) => Validators.validateTargetAlcohol(
                                      value, 
                                      controller.initialAlcoholController.text
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // 追加情報（オプション）
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '追加情報（オプション）',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: controller.sakeNameController,
                              decoration: InputDecoration(
                                labelText: 'お酒の名前',
                                hintText: '例: 純米大吟醸 X',
                                prefixIcon: Icon(Icons.local_bar),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: controller.personInChargeController,
                              decoration: InputDecoration(
                                labelText: '担当者',
                                hintText: '例: 田中',
                                prefixIcon: Icon(Icons.person),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // 計算・リセットボタン
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.calculate),
                            label: Text('割水計算'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: controller.isCalculating 
                                ? null 
                                : () {
                                    try {
                                      controller.calculateDilution();
                                    } catch (e) {
                                      _showError(e.toString());
                                    }
                                  },
                          ),
                        ),
                        SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: Icon(Icons.clear),
                          label: Text('クリア'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () => controller.resetForm(),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24),
                    
                    // 計算結果表示
                    if (controller.isCalculating)
                      Center(child: CircularProgressIndicator())
                    else if (controller.hasCalculationResult)
                      DilutionResultCard(
                        initialVolume: double.parse(controller.initialVolumeController.text),
                        initialAlcohol: double.parse(controller.initialAlcoholController.text),
                        targetAlcohol: double.parse(controller.targetAlcoholController.text),
                        waterToAdd: controller.dilutionResult!.waterToAdd,
                        finalVolume: controller.dilutionResult!.finalVolume,
                        finalMeasurement: controller.finalMeasurement,
                        tankNumber: controller.selectedTank,
                        approximations: controller.finalVolumeApproximations,
                        selectedFinalVolume: controller.selectedFinalVolume,
                        selectedFinalMeasurement: controller.selectedFinalMeasurement,
                        adjustedWaterToAdd: controller.adjustedWaterToAdd,
                        actualAlcohol: controller.actualAlcoholPercentage,
                        onApproximationSelected: (volume, measurement) => 
                          controller.selectFinalVolume(volume, measurement),
                        isExactMatch: controller.isExactMatch,
                      ),
                    
                    // 保存ボタン
                    if (controller.hasCalculationResult) ...[
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: Icon(Icons.save),
                        label: Text(controller.isEditMode ? '計画を更新' : '計画を登録'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          minimumSize: Size(double.infinity, 0),
                        ),
                        onPressed: _savePlan,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}