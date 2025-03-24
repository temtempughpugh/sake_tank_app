/// タンク情報のデータモデル
class Tank {
  final String tankNumber;          // タンク番号
  final List<MeasurementData> measurementData; // このタンクの検尺-容量データのリスト
  
  Tank({
    required this.tankNumber,
    required this.measurementData,
  });
  
  /// 最大容量を取得
  double get maxCapacity {
    if (measurementData.isEmpty) return 0;
    
    // 検尺値でソート
    measurementData.sort((a, b) => a.measurement.compareTo(b.measurement));
    
    // 検尺が0の時が最大容量
    for (var data in measurementData) {
      if (data.measurement == 0) return data.capacity;
    }
    
    // 検尺0がない場合は最小検尺のデータを使用
    return measurementData.first.capacity;
  }
  
  /// 最小容量を取得
  double get minCapacity {
    if (measurementData.isEmpty) return 0;
    
    // 容量でソート
    measurementData.sort((a, b) => a.capacity.compareTo(b.capacity));
    
    return measurementData.first.capacity;
  }
  
  /// 最大検尺値を取得
  double get maxMeasurement {
    if (measurementData.isEmpty) return 0;
    
    // 検尺値でソート（降順）
    measurementData.sort((a, b) => b.measurement.compareTo(a.measurement));
    
    return measurementData.first.measurement;
  }
  
  /// タンクカテゴリを取得
  String get category {
    // 「仕込水タンク」は特殊扱い
    if (tankNumber == "仕込水タンク") return "水タンク";
    
    // No.のプレフィックスを削除して番号だけ抽出
    String cleanNumber = tankNumber.replaceAll(RegExp(r'No\.|No'), '').trim();
    
    // タンク番号をパースして数値に変換
    int? tankId;
    try {
      tankId = int.parse(cleanNumber);
    } catch (_) {
      return "その他";
    }
    
    // 番号からカテゴリを判定
    if ([16, 58].contains(tankId)) {
      return "蔵出しタンク";
    } else if ([40, 42, 87, 131, 132, 135].contains(tankId)) {
      return "貯蔵用サーマルタンク";
    } else if ([69, 70, 71, 72, 39, 84, 38].contains(tankId)) {
      return "貯蔵用タンク(冷蔵庫A)";
    } else if ([86, 44, 45, 85].contains(tankId)) {
      return "貯蔵用タンク(冷蔵庫B)";
    } else if ([102, 108, 101, 99, 31, 41, 109, 107, 100, 103, 33, 83, 15,
              144, 36, 37, 35, 121, 25, 34, 137].contains(tankId)) {
      return "貯蔵用タンク";
    } else if ([262, 263, 264, 288, 888, 227, 226, 225, 28, 68, 62, 63, 19, 10, 18, 64, 6].contains(tankId)) {
      return "仕込み用タンク";
    } else if ([88].contains(tankId)) {
      return "水タンク";
    }
    
    return "その他";
  }
  
  /// このタンクが重要度が低いタンクかどうか判定
  bool get isLessProminent {
    // No.のプレフィックスを削除して番号だけ抽出
    String cleanNumber = tankNumber.replaceAll(RegExp(r'No\.|No'), '').trim();
    
    // タンク番号をパースして数値に変換
    int? tankId;
    try {
      tankId = int.parse(cleanNumber);
    } catch (_) {
      return false;
    }
    
    return [25, 34, 35, 36, 37, 121, 137, 144].contains(tankId);
  }
  
  @override
  String toString() {
    return 'タンク: $tankNumber, カテゴリ: $category, 最大容量: $maxCapacity L';
  }
}

/// 検尺と容量のデータペア
class MeasurementData {
  final double capacity;    // 容量（L）
  final double measurement; // 検尺値（mm）
  
  MeasurementData({
    required this.capacity,
    required this.measurement,
  });
  
  @override
  String toString() {
    return '検尺: $measurement mm, 容量: $capacity L';
  }
}