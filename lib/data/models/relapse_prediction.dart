class RelapsePrediction {
  const RelapsePrediction({
    required this.riskScore, // 0-100
    required this.riskLevel, // 'low', 'medium', 'high', 'critical'
    required this.topTriggers,
    required this.recommendations,
    required this.confidence, // 0-100
    required this.generatedAt,
  });

  final int riskScore;
  final String riskLevel;
  final List<String> topTriggers; // Top 3 triggers
  final List<String> recommendations; // Personalized advice
  final int confidence;
  final DateTime generatedAt;

  @override
  String toString() {
    return 'RelapsePrediction(risk: $riskScore, level: $riskLevel, triggers: ${topTriggers.length}, confidence: $confidence%)';
  }
}
