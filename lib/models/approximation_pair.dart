// lib/models/approximation_pair.dart
class ApproximationPair {
  final double capacity;    // 容量 (L)
  final double measurement; // 検尺 (mm)
  
  ApproximationPair({
    required this.capacity,
    required this.measurement,
  });
  
  factory ApproximationPair.fromMap(Map<String, double> map) {
    return ApproximationPair(
      capacity: map['capacity']!,
      measurement: map['measurement']!,
    );
  }
  
  Map<String, double> toMap() {
    return {
      'capacity': capacity,
      'measurement': measurement,
    };
  }
  
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is ApproximationPair &&
        runtimeType == other.runtimeType &&
        capacity == other.capacity &&
        measurement == other.measurement;

  @override
  int get hashCode => capacity.hashCode ^ measurement.hashCode;
}

// lib/models/brewing_calculation.dart - 計算結果を一元管理するための新しいクラス
class BrewingCalculation {
  // 割水計算に関わる変数
  final double dilutedVolume;              // 割水後総量
  final double? selectedDilutedVolume;     // 選択された割水後総量
  final double? dilutedMeasurement;        // 割水後検尺
  final double? originalAlcoholPercentage; // 割水前アルコール度数
  final double? dilutionAmount;            // 割水量
  final double? originalLiquorVolume;      // 計算された割水前酒量
  final double? selectedOriginalLiquorVolume; // 選択された割水前酒量
  final double? originalLiquorMeasurement; // 割水前検尺
  final double? actualDilutedAlcoholPercentage; // 実際のアルコール度数

  // 近似値リスト
  final List<ApproximationPair> dilutedVolumeApproximations;
  final List<ApproximationPair> originalLiquorApproximations;

  BrewingCalculation({
    required this.dilutedVolume,
    this.selectedDilutedVolume,
    this.dilutedMeasurement,
    this.originalAlcoholPercentage,
    this.dilutionAmount,
    this.originalLiquorVolume,
    this.selectedOriginalLiquorVolume,
    this.originalLiquorMeasurement,
    this.actualDilutedAlcoholPercentage,
    this.dilutedVolumeApproximations = const [],
    this.originalLiquorApproximations = const [],
  });

  // 新しいインスタンスを返す (不変パターン)
  BrewingCalculation copyWith({
    double? dilutedVolume,
    double? selectedDilutedVolume,
    double? dilutedMeasurement,
    double? originalAlcoholPercentage,
    double? dilutionAmount,
    double? originalLiquorVolume,
    double? selectedOriginalLiquorVolume,
    double? originalLiquorMeasurement,
    double? actualDilutedAlcoholPercentage,
    List<ApproximationPair>? dilutedVolumeApproximations,
    List<ApproximationPair>? originalLiquorApproximations,
  }) {
    return BrewingCalculation(
      dilutedVolume: dilutedVolume ?? this.dilutedVolume,
      selectedDilutedVolume: selectedDilutedVolume ?? this.selectedDilutedVolume,
      dilutedMeasurement: dilutedMeasurement ?? this.dilutedMeasurement,
      originalAlcoholPercentage: originalAlcoholPercentage ?? this.originalAlcoholPercentage,
      dilutionAmount: dilutionAmount ?? this.dilutionAmount,
      originalLiquorVolume: originalLiquorVolume ?? this.originalLiquorVolume,
      selectedOriginalLiquorVolume: selectedOriginalLiquorVolume ?? this.selectedOriginalLiquorVolume,
      originalLiquorMeasurement: originalLiquorMeasurement ?? this.originalLiquorMeasurement,
      actualDilutedAlcoholPercentage: actualDilutedAlcoholPercentage ?? this.actualDilutedAlcoholPercentage,
      dilutedVolumeApproximations: dilutedVolumeApproximations ?? this.dilutedVolumeApproximations,
      originalLiquorApproximations: originalLiquorApproximations ?? this.originalLiquorApproximations,
    );
  }

  // 計算がある程度完了しているかチェックするヘルパーメソッド
  bool get hasOriginalLiquorCalculation => originalLiquorVolume != null && dilutionAmount != null;
  bool get hasSelectedDilutedVolume => selectedDilutedVolume != null && dilutedMeasurement != null;
  bool get hasSelectedOriginalLiquorVolume => selectedOriginalLiquorVolume != null && originalLiquorMeasurement != null;
  bool get hasActualAlcoholCalculation => actualDilutedAlcoholPercentage != null;
  
  // 入力検証
  bool validate() {
    return hasSelectedDilutedVolume && 
           originalAlcoholPercentage != null && 
           hasSelectedOriginalLiquorVolume;
  }
}