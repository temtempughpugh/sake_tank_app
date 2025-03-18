// lib/models/tank_category.dart
import 'package:flutter/material.dart';

class TankCategory {
  final String name;
  final List<String> tankNumbers;
  final bool isCollapsed;
  final Color? color;
  final bool isLessProminent;

  TankCategory({
    required this.name,
    required this.tankNumbers,
    this.isCollapsed = false,
    this.color,
    this.isLessProminent = false,
  });
}

// Pre-defined tank categories
class TankCategories {
  static List<TankCategory> getCategories() {
  return [
    TankCategory(
      name: '蔵出しタンク',
      tankNumbers: ['No.16', 'No.58'],  // No.付きの形式で定義
      color: Colors.blue,
    ),
    TankCategory(
      name: '貯蔵用サーマルタンク',
      tankNumbers: ['No.40', 'No.42', 'No.87', 'No.131', 'No.132', 'No.135'],
      color: Colors.green,
    ),
    TankCategory(
      name: '貯蔵用タンク(冷蔵庫A)',
      tankNumbers: ['No.69', 'No.70', 'No.71', 'No.72', 'No.39', 'No.84', 'No.38'],
      color: Colors.purple,
    ),
    TankCategory(
      name: '貯蔵用タンク(冷蔵庫B)',
      tankNumbers: ['No.86', 'No.44', 'No.45', 'No.85'],
      color: Colors.deepPurple,
    ),
    TankCategory(
      name: '貯蔵用タンク',
      tankNumbers: [
        'No.102', 'No.108', 'No.101', 'No.99', 'No.31', 'No.41', 'No.109', 'No.107', 'No.100', 'No.103', 'No.33', 'No.83', 'No.15',
        // Less prominent tanks
        'No.144', 'No.36', 'No.37', 'No.35', 'No.121', 'No.25', 'No.34', 'No.137',
      ],
      color: Colors.teal,
    ),
    TankCategory(
      name: '仕込み用タンク',
      tankNumbers: [
        'No.262', 'No.263', 'No.264', 'No.288', 'No.888', 'No.227', 'No.226', 'No.225', 
        'No.28', 'No.68', 'No.62', 'No.63', 'No.19', 'No.10', 'No.18', 'No.64', 'No.6'
      ],
      color: Colors.orange,
    ),
    TankCategory(
      name: '水タンク',
      tankNumbers: ['No.88', '仕込水タンク'],
      color: Colors.lightBlue,
    ),
    TankCategory(
      name: 'その他',
      tankNumbers: [], // This will be populated with any tanks not in other categories
      color: Colors.grey,
    ),
  ];
}

  // Clean tank number for comparison - remove any "No." prefix and trim whitespace
  static String cleanTankNumber(String tankNumber) {
    // 特殊ケースのみ例外処理
    if (tankNumber == "仕込水タンク") return tankNumber;
    
    // 余計な処理をせず、単にトリムするだけ
    return tankNumber.trim();
  }

  // Utility method to get the category for a tank number
  static TankCategory getCategoryForTank(String tankNumber) {
    // Clean the input tank number first
    String cleanedTankNumber = cleanTankNumber(tankNumber);
    
    // 仕込水タンクの場合は特別に処理
    if (tankNumber == "仕込水タンク") {
      return getCategories().firstWhere(
        (category) => category.name == '水タンク',
        orElse: () => getCategories().last
      );
    }
    
    for (var category in getCategories()) {
      // Check if this tank number is in this category
      for (var categoryTank in category.tankNumbers) {
        if (categoryTank == cleanedTankNumber) {
          return category;
        }
      }
    }
    
    // Return "Other" category if not found
    return getCategories().last;
  }

  // Check if a tank is considered "less prominent"
 // Check if a tank is considered "less prominent"
static bool isLessProminentTank(String tankNumber) {
  final lessPronimentTanks = ['No.25', 'No.34', 'No.35', 'No.36', 'No.37', 'No.121', 'No.137', 'No.144'];
  final cleanedTankNumber = cleanTankNumber(tankNumber);
  
  return lessPronimentTanks.contains(cleanedTankNumber);
}
}