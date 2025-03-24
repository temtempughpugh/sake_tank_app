/// 測定結果を表すモデルクラス
/// 検尺・容量計算の結果を保持する
class MeasurementResult {
  final double measurement; // 検尺値（mm）
  final double capacity;    // 容量（L）
  final bool isExactMatch;  // 正確な一致かどうか
  final bool isOverCapacity; // 最大容量オーバーかどうか
  final bool isOverLimit;   // 検尺上限オーバーかどうか

  MeasurementResult({
    required this.measurement,
    required this.capacity,
    this.isExactMatch = true,
    this.isOverCapacity = false,
    this.isOverLimit = false,
  });
  
  /// この結果が有効かどうか
  bool get isValid => !isOverCapacity && !isOverLimit;
  
  /// 近似値か完全一致かを表す説明テキスト
  String get matchDescription {
    if (isOverCapacity) return "容量オーバー";
    if (isOverLimit) return "検尺上限オーバー";
    return isExactMatch ? "完全一致" : "近似値";
  }
  
  @override
  String toString() {
    return 'MeasurementResult(検尺: $measurement mm, 容量: $capacity L, $matchDescription)';
  }
}

/// 割水計画モデル
class DilutionPlan {
  final String id;
  final String tankNumber;
  final double initialVolume;
  final double initialMeasurement;
  final double initialAlcoholPercentage;
  final double targetAlcoholPercentage;
  final double waterToAdd;
  final double finalVolume;
  final double finalMeasurement;
  final String sakeName;
  final String personInCharge;
  final DateTime plannedDate;
  final DateTime? completionDate;
  final bool isCompleted;

  DilutionPlan({
    required this.id,
    required this.tankNumber,
    required this.initialVolume,
    required this.initialMeasurement,
    required this.initialAlcoholPercentage,
    required this.targetAlcoholPercentage,
    required this.waterToAdd,
    required this.finalVolume,
    required this.finalMeasurement,
    this.sakeName = '',
    this.personInCharge = '',
    required this.plannedDate,
    this.completionDate,
    this.isCompleted = false,
  });

  /// 表示名を取得
  String get displayName => sakeName.isNotEmpty ? sakeName : 'タンク $tankNumber';
  
  /// 計画が古いかどうか（7日以上経過で未完了）
  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();
    final difference = now.difference(plannedDate).inDays;
    return difference > 7;
  }

  /// コピーを作成して一部のフィールドを更新
  DilutionPlan copyWith({
    String? id,
    String? tankNumber,
    double? initialVolume,
    double? initialMeasurement,
    double? initialAlcoholPercentage,
    double? targetAlcoholPercentage,
    double? waterToAdd,
    double? finalVolume,
    double? finalMeasurement,
    String? sakeName,
    String? personInCharge,
    DateTime? plannedDate,
    DateTime? completionDate,
    bool? isCompleted,
  }) {
    return DilutionPlan(
      id: id ?? this.id,
      tankNumber: tankNumber ?? this.tankNumber,
      initialVolume: initialVolume ?? this.initialVolume,
      initialMeasurement: initialMeasurement ?? this.initialMeasurement,
      initialAlcoholPercentage: initialAlcoholPercentage ?? this.initialAlcoholPercentage,
      targetAlcoholPercentage: targetAlcoholPercentage ?? this.targetAlcoholPercentage,
      waterToAdd: waterToAdd ?? this.waterToAdd,
      finalVolume: finalVolume ?? this.finalVolume,
      finalMeasurement: finalMeasurement ?? this.finalMeasurement,
      sakeName: sakeName ?? this.sakeName,
      personInCharge: personInCharge ?? this.personInCharge,
      plannedDate: plannedDate ?? this.plannedDate,
      completionDate: completionDate ?? this.completionDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tankNumber': tankNumber,
      'initialVolume': initialVolume,
      'initialMeasurement': initialMeasurement,
      'initialAlcoholPercentage': initialAlcoholPercentage,
      'targetAlcoholPercentage': targetAlcoholPercentage,
      'waterToAdd': waterToAdd,
      'finalVolume': finalVolume,
      'finalMeasurement': finalMeasurement,
      'sakeName': sakeName,
      'personInCharge': personInCharge,
      'plannedDate': plannedDate.toIso8601String(),
      'completionDate': completionDate?.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  /// JSONから作成
  factory DilutionPlan.fromJson(Map<String, dynamic> json) {
    return DilutionPlan(
      id: json['id'],
      tankNumber: json['tankNumber'],
      initialVolume: json['initialVolume'],
      initialMeasurement: json['initialMeasurement'],
      initialAlcoholPercentage: json['initialAlcoholPercentage'],
      targetAlcoholPercentage: json['targetAlcoholPercentage'],
      waterToAdd: json['waterToAdd'],
      finalVolume: json['finalVolume'],
      finalMeasurement: json['finalMeasurement'],
      sakeName: json['sakeName'] ?? '',
      personInCharge: json['personInCharge'] ?? '',
      plannedDate: DateTime.parse(json['plannedDate']),
      completionDate: json['completionDate'] != null ? DateTime.parse(json['completionDate']) : null,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}