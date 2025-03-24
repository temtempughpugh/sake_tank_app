import 'package:flutter/material.dart';
import '/models/bottling_info.dart';
import '/core/services/storage_service.dart';

/// 瓶詰め情報管理のコントローラー
/// データの保存・編集・計算を担当
class BottlingController extends ChangeNotifier {
  final StorageService _storageService;
  
  // フォーム入力コントローラー
  final TextEditingController sakeNameController = TextEditingController();
  final TextEditingController alcoholController = TextEditingController();
  final TextEditingController remainingController = TextEditingController();
  final TextEditingController temperatureController = TextEditingController();
  
  // 状態変数
  bool _isLoading = false;
  bool _isEditMode = false;
  String? _editId;
  DateTime _selectedDate = DateTime.now();
  List<BottleEntry> _bottleEntries = [];
  
  // ゲッター
  bool get isLoading => _isLoading;
  bool get isEditMode => _isEditMode;
  DateTime get selectedDate => _selectedDate;
  List<BottleEntry> get bottleEntries => _bottleEntries;
  
  // 計算結果
  double get totalBottles => _bottleEntries.fold<int>(
    0, (sum, entry) => sum + entry.totalBottles).toDouble();
    
  double get totalVolume => _bottleEntries.fold<double>(
    0, (sum, entry) => sum + entry.totalVolume);
  
  double get remainingVolume {
    final remaining = double.tryParse(remainingController.text) ?? 0;
    return remaining * 1.8; // 1.8L換算
  }
  
  double get totalWithRemaining => totalVolume + remainingVolume;
  
  double get alcoholPercentage => double.tryParse(alcoholController.text) ?? 0;
  
  double get pureAlcohol => totalWithRemaining * alcoholPercentage / 100;
  
  // コンストラクタ
  BottlingController({required StorageService storageService})
      : _storageService = storageService;
  
  @override
  void dispose() {
    sakeNameController.dispose();
    alcoholController.dispose();
    remainingController.dispose();
    temperatureController.dispose();
    super.dispose();
  }
  
  /// 編集モードに設定
  void setEditMode(BottlingInfo info) {
    _isEditMode = true;
    _editId = info.id;
    
    // フォーム値を設定
    sakeNameController.text = info.sakeName;
    alcoholController.text = info.alcoholPercentage.toString();
    remainingController.text = info.remainingAmount.toString();
    
    if (info.temperature != null) {
      temperatureController.text = info.temperature.toString();
    }
    
    _selectedDate = info.date;
    _bottleEntries = List.from(info.bottleEntries);
    
    notifyListeners();
  }
  
  /// 日付を選択
  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
  
  /// 瓶タイプを追加
  void addBottleEntry(BottleEntry entry) {
    _bottleEntries.add(entry);
    notifyListeners();
  }
  
  /// 瓶タイプを削除
  void removeBottleEntry(int index) {
    _bottleEntries.removeAt(index);
    notifyListeners();
  }
  
  /// フォームをリセット
  void resetForm() {
    sakeNameController.clear();
    alcoholController.clear();
    remainingController.clear();
    temperatureController.clear();
    _selectedDate = DateTime.now();
    _bottleEntries = [];
    notifyListeners();
  }
  
  /// 瓶詰め情報を保存
  Future<void> saveBottlingInfo() async {
    if (_bottleEntries.isEmpty) {
      throw Exception('少なくとも1つの瓶種を追加してください');
    }
    
    final sakeName = sakeNameController.text;
    final alcoholPercentage = double.tryParse(alcoholController.text);
    final remainingAmount = double.tryParse(remainingController.text);
    
    if (sakeName.isEmpty) {
      throw Exception('銘柄名を入力してください');
    }
    
    if (alcoholPercentage == null) {
      throw Exception('有効なアルコール度数を入力してください');
    }
    
    if (remainingAmount == null) {
      throw Exception('有効な詰め残り量を入力してください');
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      double? temperature;
      if (temperatureController.text.isNotEmpty) {
        temperature = double.tryParse(temperatureController.text);
      }
      
      final id = _isEditMode ? _editId! : DateTime.now().millisecondsSinceEpoch.toString();
      
      final bottlingInfo = BottlingInfo(
        id: id,
        date: _selectedDate,
        sakeName: sakeName,
        bottleEntries: _bottleEntries,
        remainingAmount: remainingAmount,
        alcoholPercentage: alcoholPercentage,
        temperature: temperature,
      );
      
      // 保存処理（BottlingServiceを介する想定）
      // await bottlingService.saveBottlingInfo(bottlingInfo);
      
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}