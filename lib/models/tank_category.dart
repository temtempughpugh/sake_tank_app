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
        tankNumbers: ['16', '58'],
        color: Colors.blue,
      ),
      TankCategory(
        name: '貯蔵用サーマルタンク',
        tankNumbers: ['40', '42', '87', '131', '132', '135'],
        color: Colors.green,
      ),
      TankCategory(
        name: '貯蔵用タンク(冷蔵庫A)',
        tankNumbers: ['69', '70', '71', '72', '39', '84', '38'],
        color: Colors.purple,
      ),
      TankCategory(
        name: '貯蔵用タンク(冷蔵庫B)',
        tankNumbers: ['86', '44', '45', '85'],
        color: Colors.deepPurple,
      ),
      TankCategory(
        name: '貯蔵用タンク',
        tankNumbers: [
          '102', '108', '101', '99', '31', '41', '109', '107', '100', '103', '33', '83', '15',
          // Less prominent tanks
          '144', '36', '37', '35', '121', '25', '34', '137',
        ],
        color: Colors.teal,
      ),
      TankCategory(
        name: '仕込み用タンク',
        tankNumbers: [
          '262', '263', '264', '288', '888', '227', '226', '225', 
          '28', '68', '62', '63', '19', '10', '18', '64', '6'
        ],
        color: Colors.orange,
      ),
      TankCategory(
        name: '水タンク',
        tankNumbers: ['88', '仕込水タンク'],
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
    if (tankNumber == "仕込水タンク") return tankNumber;
    
    // 大文字小文字を区別せず、数字のゼロも考慮して No. または N0. を削除
    String cleaned = tankNumber.replaceAll(RegExp(r'(?i)No\.|N0\.'), '').trim();
    return cleaned;
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
  static bool isLessProminentTank(String tankNumber) {
    final lessPronimentTanks = ['25', '34', '35', '36', '37', '121', '137', '144'];
    final cleanedTankNumber = cleanTankNumber(tankNumber);
    
    return lessPronimentTanks.contains(cleanedTankNumber);
  }
}