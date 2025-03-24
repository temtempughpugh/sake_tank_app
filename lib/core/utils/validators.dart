/// アプリケーション全体で使用する入力検証関数集
class Validators {
  /// 容量入力の検証（空でないか、数値か、範囲内か）
  static String? validateVolume(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return '容量を入力してください';
    }
    
    final double? parsed = double.tryParse(value);
    if (parsed == null) {
      return '有効な数値を入力してください';
    }
    
    if (min != null && parsed < min) {
      return '$min L以上の値を入力してください';
    }
    
    if (max != null && parsed > max) {
      return '$max L以下の値を入力してください';
    }
    
    return null;
  }
  
  /// 検尺入力の検証
  static String? validateMeasurement(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return '検尺値を入力してください';
    }
    
    final double? parsed = double.tryParse(value);
    if (parsed == null) {
      return '有効な数値を入力してください';
    }
    
    if (min != null && parsed < min) {
      return '$min mm以上の値を入力してください';
    }
    
    if (max != null && parsed > max) {
      return '$max mm以下の値を入力してください';
    }
    
    return null;
  }
  
  /// アルコール度数入力の検証
  static String? validateAlcoholPercentage(String? value) {
    if (value == null || value.isEmpty) {
      return 'アルコール度数を入力してください';
    }
    
    final double? parsed = double.tryParse(value);
    if (parsed == null) {
      return '有効な数値を入力してください';
    }
    
    if (parsed <= 0 || parsed > 100) {
      return '1〜100%の範囲で入力してください';
    }
    
    return null;
  }
  
  /// 目標アルコール度数の検証（初期値より低いか）
  static String? validateTargetAlcohol(String? value, String? initialValue) {
    final baseValidation = validateAlcoholPercentage(value);
    if (baseValidation != null) {
      return baseValidation;
    }
    
    final double? target = double.tryParse(value!);
    final double? initial = double.tryParse(initialValue ?? '');
    
    if (initial != null && target != null && target >= initial) {
      return '目標アルコール度数は現在の度数より低く設定してください';
    }
    
    return null;
  }
  
  /// 名前入力の検証（必須かどうかで条件変更）
  static String? validateName(String? value, {bool required = false}) {
    if (required && (value == null || value.isEmpty)) {
      return '名前を入力してください';
    }
    
    return null;
  }
}