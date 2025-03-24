class DilutionResult {
  final double initialVolume;
  final double initialAlcoholPercentage;
  final double targetAlcoholPercentage;
  final double waterToAdd;
  final double finalVolume;
  final double finalMeasurement;
  
  // 近似値リストを容量と検尺のペアで保持
  final List<Map<String, double>> nearestAvailablePairs;
  
  final bool isExactMatch;
  final double? adjustedWaterToAdd;
  final double? adjustedFinalVolume;
  final double? adjustedFinalMeasurement;
  final double? adjustedAlcoholPercentage;

  DilutionResult({
    required this.initialVolume,
    required this.initialAlcoholPercentage,
    required this.targetAlcoholPercentage,
    required this.waterToAdd,
    required this.finalVolume,
    required this.finalMeasurement,
    this.nearestAvailablePairs = const [],
    required this.isExactMatch,
    this.adjustedWaterToAdd,
    this.adjustedFinalVolume,
    this.adjustedFinalMeasurement,
    this.adjustedAlcoholPercentage,
  });
}