import 'package:flutter/material.dart';
import '../models/dilution_plan.dart';

class ActivePlanItem extends StatelessWidget {
  final DilutionPlan plan;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  
  const ActivePlanItem({
    Key? key,
    required this.plan,
    required this.onComplete,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayName = plan.sakeName.isNotEmpty
        ? plan.sakeName
        : 'タンク ${plan.tankNumber}';
    
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _buildLeadingIcon(),
      title: Text(
        displayName,
        style: TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.water_drop_outlined,
                size: 14,
                color: Colors.grey[600],
              ),
              SizedBox(width: 4),
              Text(
                '${plan.initialAlcoholPercentage.toStringAsFixed(1)}% → ${plan.targetAlcoholPercentage.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.straighten,
                size: 14,
                color: Colors.grey[600],
              ),
              SizedBox(width: 4),
              Text(
                '${plan.waterToAdd.toStringAsFixed(1)} L',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          if (plan.personInCharge.isNotEmpty) ...[
            SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 4),
                Text(
                  '担当: ${plan.personInCharge}',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 22),
            color: Colors.blue,
            tooltip: '編集',
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(Icons.check_circle_outline, size: 22),
            color: Colors.green,
            tooltip: '完了',
            onPressed: onComplete,
          ),
        ],
      ),
      onTap: () {
        // Show detailed view
        _showPlanDetails(context);
      },
    );
  }
  
  Widget _buildLeadingIcon() {
    return CircleAvatar(
      backgroundColor: Colors.blue[50],
      child: Text(
        plan.tankNumber,
        style: TextStyle(
          color: Colors.blue[700],
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
  
  void _showPlanDetails(BuildContext context) {
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
                  SizedBox(height: 16),
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
                  SizedBox(height: 20),
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
                            onEdit();
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
                            onComplete();
                          },
                        ),
                      ),
                    ],
                  ),
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
  
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}