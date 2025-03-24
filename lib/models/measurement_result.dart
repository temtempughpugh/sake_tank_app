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

