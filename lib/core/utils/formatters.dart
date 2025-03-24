import 'package:intl/intl.dart';

/// アプリケーション全体で使用する書式設定関数集
class Formatters {
  /// 数値を容量表示用にフォーマット (例：1234.5 -> 1,234.5 L)
  static String formatVolume(double value, {int decimalPlaces = 1}) {
    final formatter = NumberFormat.decimalPattern()
      ..minimumFractionDigits = decimalPlaces
      ..maximumFractionDigits = decimalPlaces;
    return '${formatter.format(value)} L';
  }
  
  /// 数値を検尺表示用にフォーマット (例：1234.5 -> 1,234.5 mm)
  static String formatMeasurement(double value, {int decimalPlaces = 1}) {
    final formatter = NumberFormat.decimalPattern()
      ..minimumFractionDigits = decimalPlaces
      ..maximumFractionDigits = decimalPlaces;
    return '${formatter.format(value)} mm';
  }
  
  /// アルコール度数をパーセント表示用にフォーマット (例：15.5 -> 15.5%)
  static String formatAlcoholPercentage(double value, {int decimalPlaces = 1}) {
    final formatter = NumberFormat.decimalPattern()
      ..minimumFractionDigits = decimalPlaces
      ..maximumFractionDigits = decimalPlaces;
    return '${formatter.format(value)}%';
  }
  
  /// 日付を標準形式でフォーマット (例：2023/01/01)
  static String formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
  
  /// 日付と時刻を標準形式でフォーマット (例：2023/01/01 12:30)
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  /// CSVエクスポート用の日付フォーマット (例：2023-01-01)
  static String formatDateForCsv(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// タンク番号を表示用にフォーマット
  static String formatTankNumber(String tankNumber) {
    return tankNumber;
  }
}