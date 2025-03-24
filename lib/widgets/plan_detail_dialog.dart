import 'package:flutter/material.dart';
import '../models/dilution_plan.dart';

/// 割水計画詳細ダイアログ
/// 計画の詳細情報を表示し、編集や完了処理を行うためのダイアログ
class PlanDetailDialog extends StatelessWidget {
  final DilutionPlan plan;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  
  const PlanDetailDialog({
    Key? key,
    required this.plan,
    required this.onComplete,
    required this.onEdit,
    this.onDelete,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(plan.sakeName.isNotEmpty ? plan.sakeName : 'タンク ${plan.tankNumber}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem(
              icon: Icons.calendar_today,
              label: '計画日',
              value: _formatDate(plan.plannedDate),
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
          ],
        ),
      ),
      actions: [
        if (onDelete != null)
          TextButton.icon(
            icon: Icon(Icons.delete, color: Colors.red),
            label: Text('削除', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context);
              onDelete!();
            },
          ),
        TextButton.icon(
          icon: Icon(Icons.edit),
          label: Text('編集'),
          onPressed: () {
            Navigator.pop(context);
            onEdit();
          },
        ),
        ElevatedButton.icon(
          icon: Icon(Icons.check_circle),
          label: Text('完了'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
            onComplete();
          },
        ),
      ],
      actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
  
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}