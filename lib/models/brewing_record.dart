import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // @requiredアノテーション用

class BrewingRecord {
  final String id;
  final String bottlingInfoId; // 関連する瓶詰め情報ID
  final ProcessType processType;
  final DateTime date;
  
  // タンク情報
  final String tankNumber;
  final String? destinationTankNumber;
  
  // 割水後情報
  final double dilutedVolume;         // 割水後総量
  final double dilutedMeasurement;    // 割水後検尺
  final double dilutedAlcoholPercentage;  // 目標アルコール度数
  final double? actualDilutedAlcoholPercentage; // 実際のアルコール度数
  
  // 割水前情報
  final double originalAlcoholPercentage; // 割水前アルコール度数
  final double originalLiquorVolume;     // 計算された割水前酒量
  final double selectedOriginalLiquorVolume; // 選択された近似値の割水前酒量
  final double originalLiquorMeasurement; // 割水前検尺
  
  // 割水・欠減情報
  final double dilutionAmount;       // 割水量
  final double reductionAmount;      // 欠減量（デフォルト0）
  final double? temperature;         // 品温
  
  BrewingRecord({
    required this.id,
    required this.bottlingInfoId,
    required this.processType,
    required this.date,
    required this.tankNumber,
    this.destinationTankNumber,
    required this.dilutedVolume,
    required this.dilutedMeasurement,
    required this.dilutedAlcoholPercentage,
    this.actualDilutedAlcoholPercentage,
    required this.originalAlcoholPercentage,
    required this.originalLiquorVolume,
    required this.selectedOriginalLiquorVolume,
    required this.originalLiquorMeasurement,
    required this.dilutionAmount,
    this.reductionAmount = 0.0,
    this.temperature,
  });
  
  // JSON変換メソッド
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bottlingInfoId': bottlingInfoId,
      'processType': processType.index,
      'date': date.toIso8601String(),
      'tankNumber': tankNumber,
      'destinationTankNumber': destinationTankNumber,
      'dilutedVolume': dilutedVolume,
      'dilutedMeasurement': dilutedMeasurement,
      'dilutedAlcoholPercentage': dilutedAlcoholPercentage,
      'actualDilutedAlcoholPercentage': actualDilutedAlcoholPercentage,
      'originalAlcoholPercentage': originalAlcoholPercentage,
      'originalLiquorVolume': originalLiquorVolume,
      'selectedOriginalLiquorVolume': selectedOriginalLiquorVolume,
      'originalLiquorMeasurement': originalLiquorMeasurement,
      'dilutionAmount': dilutionAmount,
      'reductionAmount': reductionAmount,
      'temperature': temperature,
    };
  }
  
  factory BrewingRecord.fromJson(Map<String, dynamic> json) {
    return BrewingRecord(
      id: json['id'],
      bottlingInfoId: json['bottlingInfoId'],
      processType: ProcessType.values[json['processType']],
      date: DateTime.parse(json['date']),
      tankNumber: json['tankNumber'],
      destinationTankNumber: json['destinationTankNumber'],
      dilutedVolume: json['dilutedVolume'],
      dilutedMeasurement: json['dilutedMeasurement'],
      dilutedAlcoholPercentage: json['dilutedAlcoholPercentage'],
      actualDilutedAlcoholPercentage: json['actualDilutedAlcoholPercentage'],
      originalAlcoholPercentage: json['originalAlcoholPercentage'],
      originalLiquorVolume: json['originalLiquorVolume'],
      selectedOriginalLiquorVolume: json['selectedOriginalLiquorVolume'],
      originalLiquorMeasurement: json['originalLiquorMeasurement'],
      dilutionAmount: json['dilutionAmount'],
      reductionAmount: json['reductionAmount'] ?? 0.0,
      temperature: json['temperature'],
    );
  }
}

enum ProcessType {
  INSPECTION,    // 検定（上槽時）
  FILTRATION,    // ろ過
  PASTEURIZATION, // 火入れ
  SHIPPING_DILUTION, // 蔵出し/割水
  BOTTLING,      // 瓶詰め
}