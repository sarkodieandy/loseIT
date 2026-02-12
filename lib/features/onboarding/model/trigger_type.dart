enum TriggerType {
  stress,
  boredom,
  loneliness,
  anxiety,
  fatigue,
  conflict,
  socialPressure,
  lateNight,
  alcohol,
  celebration,
}

extension TriggerTypeX on TriggerType {
  String get label {
    return switch (this) {
      TriggerType.stress => 'Stress',
      TriggerType.boredom => 'Boredom',
      TriggerType.loneliness => 'Loneliness',
      TriggerType.anxiety => 'Anxiety',
      TriggerType.fatigue => 'Fatigue',
      TriggerType.conflict => 'Conflict',
      TriggerType.socialPressure => 'Social Pressure',
      TriggerType.lateNight => 'Late Night',
      TriggerType.alcohol => 'Alcohol',
      TriggerType.celebration => 'Celebration',
    };
  }
}
