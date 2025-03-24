class MeasurementCapacityPair {
  final double measurement; // 検尺値（mm）
  final double capacity;    // 対応する容量（L）
  
  MeasurementCapacityPair({
    required this.measurement,
    required this.capacity,
  });
  
  @override
  String toString() {
    return '検尺: $measurement mm, 容量: $capacity L';
  }
}