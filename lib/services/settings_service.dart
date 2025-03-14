import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  // キー定義
  static const String _lastTankKey = 'last_selected_tank';
  static const String _themeKey = 'app_theme';
  static const String _defaultMeasurementUnitKey = 'default_measurement_unit';
  
  // 最後に選択したタンクを保存
  Future<void> saveLastSelectedTank(String tankNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastTankKey, tankNumber);
  }
  
  // 最後に選択したタンクを読み込み
  Future<String?> getLastSelectedTank() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastTankKey);
  }
  
  // テーマ設定を保存（0: ライトテーマ、1: ダークテーマ、2: システム設定に従う）
  Future<void> saveThemeSetting(int themeSetting) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, themeSetting);
  }
  
  // テーマ設定を読み込み
  Future<int> getThemeSetting() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_themeKey) ?? 2; // デフォルトはシステム設定に従う
  }
  
  // デフォルトの測定単位を保存（mm/L）
  Future<void> saveDefaultMeasurementUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultMeasurementUnitKey, unit);
  }
  
  // デフォルトの測定単位を読み込み
  Future<String> getDefaultMeasurementUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultMeasurementUnitKey) ?? 'mm'; // デフォルトはmm
  }
}