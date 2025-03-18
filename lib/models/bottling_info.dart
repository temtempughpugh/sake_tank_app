class BottlingInfo {
  final String id;
  final DateTime date;
  final String sakeName;
  final List<BottleEntry> bottleEntries;
  final double remainingAmount; // 1.8L換算の残り本数
  final double alcoholPercentage;
  final double? actualAlcoholPercentage; // 記帳サポートで計算される実際値
  final double? temperature;
  
  BottlingInfo({
    required this.id,
    required this.date,
    required this.sakeName,
    required this.bottleEntries,
    required this.remainingAmount,
    required this.alcoholPercentage,
    this.actualAlcoholPercentage,
    this.temperature,
  });
  
  // 総リットル数計算
  double get totalVolume {
    double bottleVolume = bottleEntries.fold<double>(
        0, (sum, entry) => sum + entry.totalVolume);
    double remainingVolume = remainingAmount * 1.8; // 1.8L換算
    return bottleVolume + remainingVolume;
  }
  
  // 純アルコール量計算
  double get pureAlcohol {
    return totalVolume * alcoholPercentage / 100;
  }
  
  // JSON変換メソッド
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'sakeName': sakeName,
      'bottleEntries': bottleEntries.map((e) => e.toJson()).toList(),
      'remainingAmount': remainingAmount,
      'alcoholPercentage': alcoholPercentage,
      'actualAlcoholPercentage': actualAlcoholPercentage,
      'temperature': temperature,
    };
  }
  
  factory BottlingInfo.fromJson(Map<String, dynamic> json) {
    return BottlingInfo(
      id: json['id'],
      date: DateTime.parse(json['date']),
      sakeName: json['sakeName'],
      bottleEntries: (json['bottleEntries'] as List)
          .map((e) => BottleEntry.fromJson(e))
          .toList(),
      remainingAmount: json['remainingAmount'],
      alcoholPercentage: json['alcoholPercentage'],
      actualAlcoholPercentage: json['actualAlcoholPercentage'],
      temperature: json['temperature'],
    );
  }
  
  // コピーメソッド
  BottlingInfo copyWith({
    String? id,
    DateTime? date,
    String? sakeName,
    List<BottleEntry>? bottleEntries,
    double? remainingAmount,
    double? alcoholPercentage,
    double? actualAlcoholPercentage,
    double? temperature,
  }) {
    return BottlingInfo(
      id: id ?? this.id,
      date: date ?? this.date,
      sakeName: sakeName ?? this.sakeName,
      bottleEntries: bottleEntries ?? this.bottleEntries,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      alcoholPercentage: alcoholPercentage ?? this.alcoholPercentage,
      actualAlcoholPercentage: actualAlcoholPercentage ?? this.actualAlcoholPercentage,
      temperature: temperature ?? this.temperature,
    );
  }
}

class BottleEntry {
  final BottleType bottleType;
  final int caseCount;
  final int looseCount;
  
  BottleEntry({
    required this.bottleType,
    required this.caseCount,
    required this.looseCount,
  });
  
  // 総本数計算
  int get totalBottles => (caseCount * bottleType.bottlesPerCase) + looseCount;
  
  // 総リットル数計算 (L単位)
  double get totalVolume => totalBottles * (bottleType.volumeInMl / 1000);
  
  // JSON変換メソッド
  Map<String, dynamic> toJson() {
    return {
      'bottleType': bottleType.toJson(),
      'caseCount': caseCount,
      'looseCount': looseCount,
    };
  }
  
  factory BottleEntry.fromJson(Map<String, dynamic> json) {
    return BottleEntry(
      bottleType: BottleType.fromJson(json['bottleType']),
      caseCount: json['caseCount'],
      looseCount: json['looseCount'],
    );
  }
}

class BottleType {
  final String name;
  final double volumeInMl;
  int bottlesPerCase; // 変更可能なケース入数
  final bool isCustom;
  
  BottleType({
    required this.name,
    required this.volumeInMl,
    required this.bottlesPerCase,
    this.isCustom = false,
  });
  
  // 定型瓶のための静的インスタンス
  static BottleType get large => BottleType(
    name: '1,800ml', 
    volumeInMl: 1800, 
    bottlesPerCase: 6, 
    isCustom: false
  );
  
  static BottleType get medium => BottleType(
    name: '720ml', 
    volumeInMl: 720, 
    bottlesPerCase: 12, 
    isCustom: false
  );
  
  static BottleType get small => BottleType(
    name: '300ml', 
    volumeInMl: 300, 
    bottlesPerCase: 24, 
    isCustom: false
  );
  
  // ケース入数変更メソッド
  void updateBottlesPerCase(int newCount) {
    bottlesPerCase = newCount;
  }
  
  // カスタム瓶作成メソッド
  static BottleType custom(double volume, int bottlesPerCase) {
  return BottleType(
    name: 'カスタム (${volume.toInt()}ml)',
    volumeInMl: volume,
    bottlesPerCase: bottlesPerCase,
    isCustom: true,
  );
}
  
  // JSON変換メソッド
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'volumeInMl': volumeInMl,
      'bottlesPerCase': bottlesPerCase,
      'isCustom': isCustom,
    };
  }
  
  factory BottleType.fromJson(Map<String, dynamic> json) {
    return BottleType(
      name: json['name'],
      volumeInMl: json['volumeInMl'],
      bottlesPerCase: json['bottlesPerCase'],
      isCustom: json['isCustom'],
    );
  }
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is BottleType &&
        runtimeType == other.runtimeType &&
        name == other.name &&
        volumeInMl == other.volumeInMl &&
        bottlesPerCase == other.bottlesPerCase &&
        isCustom == other.isCustom;

  @override
  int get hashCode =>
    name.hashCode ^
    volumeInMl.hashCode ^
    bottlesPerCase.hashCode ^
    isCustom.hashCode;
}
