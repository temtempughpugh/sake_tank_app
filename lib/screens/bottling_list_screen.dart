import 'package:flutter/material.dart';
import '../models/bottling_info.dart';
import '../services/bottling_service.dart';
import '../widgets/main_drawer.dart';
import 'bottling_screen.dart';
import 'brewing_record_screen.dart';

class BottlingListScreen extends StatefulWidget {
  @override
  _BottlingListScreenState createState() => _BottlingListScreenState();
}

class _BottlingListScreenState extends State<BottlingListScreen> {
  final BottlingService _bottlingService = BottlingService();
  List<BottlingInfo> _bottlingInfoList = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadBottlingInfo();
  }
  
  Future<void> _loadBottlingInfo() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final infoList = await _bottlingService.getAllBottlingInfo();
      setState(() {
        _bottlingInfoList = infoList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラー: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _deleteBottlingInfo(String id) async {
    try {
      await _bottlingService.deleteBottlingInfo(id);
      _loadBottlingInfo(); // リスト再読み込み
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('瓶詰め情報を削除しました'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラー: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _confirmDeleteBottlingInfo(BottlingInfo info) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('瓶詰め情報の削除'),
        content: Text('「${info.sakeName}」の瓶詰め情報を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBottlingInfo(info.id);
            },
            child: Text('削除'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
  
  void _editBottlingInfo(BottlingInfo info) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BottlingScreen(bottlingToEdit: info),
      ),
    ).then((updated) {
      if (updated == true) {
        _loadBottlingInfo(); // リスト再読み込み
      }
    });
  }
  
  void _navigateToRecord(BottlingInfo info) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrewingRecordScreen(bottlingInfo: info),
      ),
    ).then((updated) {
      if (updated == true) {
        _loadBottlingInfo(); // リスト再読み込み（実際アルコール度数が更新されている可能性）
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('瓶詰め情報一覧'),
      ),
      endDrawer: MainDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBottlingInfo,
              child: _bottlingInfoList.isEmpty
                  ? _buildEmptyState()
                  : _buildBottlingList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BottlingScreen()),
          ).then((created) {
            if (created == true) {
              _loadBottlingInfo(); // リスト再読み込み
            }
          });
        },
        child: Icon(Icons.add),
        tooltip: '新規瓶詰め情報',
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.liquor,
            size: 80,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            '瓶詰め情報がありません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '右下の「+」ボタンから瓶詰め情報を登録できます',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottlingList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _bottlingInfoList.length,
      itemBuilder: (context, index) {
        final info = _bottlingInfoList[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => _navigateToRecord(info),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_drink, color: Theme.of(context).primaryColor),
                          SizedBox(width: 8),
                          Text(
                            info.sakeName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${info.date.year}/${info.date.month}/${info.date.day}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'アルコール度数: ${info.alcoholPercentage.toStringAsFixed(1)}%',
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '総容量: ${info.totalVolume.toStringAsFixed(1)}L',
                        ),
                      ),
                    ],
                  ),
                  if (info.actualAlcoholPercentage != null) ...[
                    SizedBox(height: 4),
                    Text(
                      '実際アルコール度数: ${info.actualAlcoholPercentage!.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: Icon(Icons.edit),
                        label: Text('編集'),
                        onPressed: () => _editBottlingInfo(info),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: Icon(Icons.assignment),
                        label: Text('記帳'),
                        onPressed: () => _navigateToRecord(info),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteBottlingInfo(info),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}