class TankData {
  final String tankNumber;  // タンク番号
  final double capacity;    // 容量（L）
  final double measurement; // 空寸/検尺（mm）

  TankData({
    required this.tankNumber,
    required this.capacity,
    required this.measurement,
  });

  @override
  String toString() {
    return 'タンク: $tankNumber, 容量: $capacity L, 検尺: $measurement mm';
  }
}