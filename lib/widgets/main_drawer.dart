// lib/widgets/main_drawer.dart
import 'package:flutter/material.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            context,
            icon: Icons.home,
            title: 'ホーム',
            onTap: () {
              // Close drawer first to avoid navigation issues
              Navigator.pop(context);
              // If not already on home screen, navigate to it
              if (ModalRoute.of(context)?.settings.name != '/') {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.table_chart,
            title: '早見表',
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/quick-reference') {
                Navigator.pushReplacementNamed(context, '/quick-reference');
              }
            },
          ),
          ExpansionTile(
            leading: Icon(Icons.water_drop),
            title: Text('蔵出し'),
            children: [
              _buildDrawerNestedItem(
                context,
                title: '蔵出し計画',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/shipping-plans');
                },
              ),
              _buildDrawerNestedItem(
                context,
                title: '割水計算',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/dilution-calculator');
                },
              ),
              _buildDrawerNestedItem(
                context,
                title: '割水計画',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/dilution-plans');
                },
              ),
            ],
          ),
          _buildDrawerItem(
  context,
  icon: Icons.liquor,
  title: '瓶詰め',
  onTap: () {
    Navigator.pop(context);
    // 瓶詰め情報一覧画面に遷移
    Navigator.pushReplacementNamed(context, '/bottling-list');
  },
),
          _buildDrawerItem(
            context,
            icon: Icons.filter_alt,
            title: 'ろ過',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/filtering');
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.whatshot,
            title: '火入れ',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/pasteurization');
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.science,
            title: '調合',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/blending');
            },
          ),
          Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: '設定',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/settings');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
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

  Widget _buildDrawerNestedItem(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.only(left: 72, right: 16),
      title: Text(title),
      onTap: onTap,
    );
  }
}