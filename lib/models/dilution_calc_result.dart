// /lib/models/dilution_calc_result.dart として新しいファイルを作成

/// 割水計算結果モデル
class DilutionCalcResult {
  final double initialVolume;
  final double initialAlcoholPercentage;
  final double targetAlcoholPercentage;
  final double waterToAdd;
  final double finalVolume;
  
  DilutionCalcResult({
    required this.initialVolume,
    required this.initialAlcoholPercentage,
    required this.targetAlcoholPercentage,
    required this.waterToAdd,
    required this.finalVolume,
  });
}