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

  // Create a copy with some fields updated
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

  // Convert to and from JSON for storage
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