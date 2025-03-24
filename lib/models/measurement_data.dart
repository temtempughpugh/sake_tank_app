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