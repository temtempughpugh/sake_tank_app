import 'package:flutter/material.dart';
import '../models/dilution_plan.dart';
import 'active_plan_item.dart';

class TaskCategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<DilutionPlan> plans;
  final VoidCallback onSeeAll;
  
  const TaskCategoryCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.plans,
    required this.onSeeAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Display at most 3 plans in the card, with a "see all" option
    final displayPlans = plans.take(3).toList();
    final hasMore = plans.length > 3;
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Category header
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(title).withOpacity(0.2),
              child: Icon(
                icon,
                color: _getCategoryColor(title),
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text('${plans.length}件の作業予定'),
            trailing: TextButton(
              onPressed: onSeeAll,
              child: Text('すべて表示'),
            ),
          ),
          
          // Plan items
          ...displayPlans.map((plan) => ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(title).withOpacity(0.1),
              child: Text(
                plan.tankNumber,
                style: TextStyle(
                  color: _getCategoryColor(title),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            title: Text(
              plan.sakeName.isNotEmpty ? plan.sakeName : 'タンク ${plan.tankNumber}',
              style: TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${plan.initialAlcoholPercentage.toStringAsFixed(1)}% → ${plan.targetAlcoholPercentage.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 20),
                  color: Colors.blue,
                  onPressed: () => Navigator.pushNamed(context, '/dilution-plans'),
                ),
                IconButton(
                  icon: Icon(Icons.check_circle_outline, size: 20),
                  color: Colors.green,
                  onPressed: () => Navigator.pushNamed(context, '/dilution-plans'),
                ),
              ],
            ),
            onTap: () => Navigator.pushNamed(context, '/dilution-plans'),
          )),
          
          // Show "more" indicator if there are additional plans
          if (hasMore)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Center(
                child: TextButton.icon(
                  icon: Icon(Icons.arrow_downward, size: 16),
                  label: Text('他${plans.length - 3}件の作業を表示'),
                  onPressed: onSeeAll,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Get appropriate color for each category
  Color _getCategoryColor(String category) {
    switch (category) {
      case '割水':
        return Colors.blue;
      case '蔵出し':
        return Colors.green;
      case '瓶詰め':
        return Colors.amber[700]!;
      case 'ろ過':
        return Colors.purple;
      case '火入れ':
        return Colors.deepOrange;
      case '調合':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }
}