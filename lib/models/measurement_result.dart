class MeasurementResult {
  final double measurement; // 検尺値
  final double capacity;    // 対応する容量
  final bool isExactMatch;  // 正確なマッチかどうか
  final bool isOverCapacity; // 最大容量オーバーかどうか
  final bool isOverLimit;   // 検尺上限オーバーかどうか

  MeasurementResult({
    required this.measurement,
    required this.capacity,
    this.isExactMatch = true,
    this.isOverCapacity = false,
    this.isOverLimit = false,
  });
}