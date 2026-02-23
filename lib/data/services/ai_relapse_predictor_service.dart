import 'dart:async';
import '../../core/utils/app_logger.dart';
import '../models/relapse_prediction.dart';

class AiRelapsePredictorService {
  AiRelapsePredictorService._();

  static final AiRelapsePredictorService instance =
      AiRelapsePredictorService._();

  final StreamController<RelapsePrediction> _predictionController =
      StreamController<RelapsePrediction>.broadcast();

  Stream<RelapsePrediction> get predictionStream =>
      _predictionController.stream;
  RelapsePrediction? _lastPrediction;

  RelapsePrediction? get lastPrediction => _lastPrediction;

  /// Generate daily relapse risk prediction based on patterns
  Future<RelapsePrediction?> generateDailyPrediction({
    required int daysSober,
    required List<String> recentTriggers, // Last 5 triggers
    required int avgUrgesPerDay,
    required int stressLevel, // 1-10
    required List<int>
        historicalFailDays, // Days of week when user typically fails
  }) async {
    try {
      AppLogger.info('ai_predictor: generating daily prediction');

      // Calculate base risk score
      int riskScore =
          _calculateBaseRisk(daysSober, avgUrgesPerDay, stressLevel);

      // Adjust for time pattern
      riskScore = _adjustForTimeOfDay(riskScore, historicalFailDays);

      // Adjust for recent triggers
      riskScore = _adjustForTriggers(riskScore, recentTriggers);

      // Determine risk level
      final riskLevel = _getRiskLevel(riskScore);

      // Get top triggers
      final topTriggers = _getTopTriggers(recentTriggers);

      // Generate recommendations
      final recommendations =
          _generateRecommendations(riskLevel, topTriggers, stressLevel);

      // Calculate confidence based on data
      final confidence = _calculateConfidence(
        recentTriggers.length,
        historicalFailDays.length,
      );

      final prediction = RelapsePrediction(
        riskScore: riskScore.clamp(0, 100),
        riskLevel: riskLevel,
        topTriggers: topTriggers,
        recommendations: recommendations,
        confidence: confidence,
        generatedAt: DateTime.now(),
      );

      _lastPrediction = prediction;

      if (!_predictionController.isClosed) {
        _predictionController.add(prediction);
      }

      AppLogger.info(
        'ai_predictor: prediction generated - risk=$riskScore, level=$riskLevel',
      );

      return prediction;
    } catch (error, stackTrace) {
      AppLogger.error('ai_predictor.generate', error, stackTrace);
      return null;
    }
  }

  int _calculateBaseRisk(int daysSober, int avgUrgesPerDay, int stressLevel) {
    int risk = 20; // Base risk

    // Earlier days are higher risk
    if (daysSober < 7) {
      risk += 40;
    } else if (daysSober < 30) {
      risk += 25;
    } else if (daysSober < 90) {
      risk += 10;
    } else {
      risk += 5;
    }

    // Urge frequency
    if (avgUrgesPerDay > 5) {
      risk += 25;
    } else if (avgUrgesPerDay > 2) {
      risk += 15;
    }

    // Stress level
    risk += (stressLevel * 2); // Stress heavily weighted

    return risk;
  }

  int _adjustForTimeOfDay(int baseRisk, List<int> historicalFailDays) {
    final now = DateTime.now();
    final currentDayOfWeek = now.weekday; // 1-7 (Mon-Sun)

    if (historicalFailDays.contains(currentDayOfWeek)) {
      return (baseRisk * 1.2).toInt(); // 20% increase if pattern matches
    }

    return baseRisk;
  }

  int _adjustForTriggers(int baseRisk, List<String> recentTriggers) {
    if (recentTriggers.isEmpty) return baseRisk;

    // High-risk triggers
    final highRiskTriggers = [
      'stress',
      'sleep_deprived',
      'social_pressure',
      'isolation'
    ];
    final highRiskCount = recentTriggers
        .where((t) => highRiskTriggers.contains(t.toLowerCase()))
        .length;

    final adjustment = highRiskCount * 8; // 8% per high-risk trigger

    return baseRisk + adjustment;
  }

  String _getRiskLevel(int score) {
    if (score >= 75) return 'critical';
    if (score >= 60) return 'high';
    if (score >= 40) return 'medium';
    return 'low';
  }

  List<String> _getTopTriggers(List<String> recentTriggers) {
    if (recentTriggers.isEmpty) {
      return ['Unknown', 'General', 'Monitor'];
    }

    // Count occurrences
    final triggerCounts = <String, int>{};
    for (final trigger in recentTriggers) {
      triggerCounts[trigger] = (triggerCounts[trigger] ?? 0) + 1;
    }

    // Sort by count and take top 3
    final sorted = triggerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).take(3).toList();
  }

  List<String> _generateRecommendations(
    String riskLevel,
    List<String> triggers,
    int stressLevel,
  ) {
    final recommendations = <String>[];

    // Risk-based recommendations
    if (riskLevel == 'critical') {
      recommendations.add('🆘 Use Emergency SOS now for guided support');
      recommendations.add('📱 Contact your support network immediately');
      recommendations.add('🚶 Get outside or change your environment');
    } else if (riskLevel == 'high') {
      recommendations.add('🟠 High risk detected - use coping tools now');
      recommendations.add('⏱️ Start a focus session or breathing exercise');
      recommendations.add('💬 Reach out to your support network');
    } else if (riskLevel == 'medium') {
      recommendations.add('🟡 Moderate risk - stay vigilant');
      recommendations.add('🧘 Try a quick meditation or grounding exercise');
      recommendations.add('📝 Journal about your feelings');
    } else {
      recommendations.add('✅ You\'re in a good place today');
      recommendations.add('💪 Reinforce positive habits');
      recommendations.add('🎯 Track what\'s helping you succeed');
    }

    // Stress-based recommendations
    if (stressLevel >= 8) {
      recommendations
          .add('🧠 Consider stress management: exercise, sleep, social');
    }

    return recommendations.take(3).toList();
  }

  int _calculateConfidence(int triggerDataPoints, int patternDataPoints) {
    // Higher confidence with more data
    int confidence = 50;
    confidence += (triggerDataPoints * 5).clamp(0, 25);
    confidence += (patternDataPoints * 2).clamp(0, 25);
    return confidence.clamp(0, 100);
  }

  void dispose() {
    _predictionController.close();
  }
}
