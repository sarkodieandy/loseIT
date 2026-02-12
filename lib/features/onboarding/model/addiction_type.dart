enum AddictionType { smoking, gambling, porn, alcohol, socialMedia, custom }

extension AddictionTypeX on AddictionType {
  String get label {
    return switch (this) {
      AddictionType.smoking => 'Smoking',
      AddictionType.gambling => 'Gambling',
      AddictionType.porn => 'Porn',
      AddictionType.alcohol => 'Alcohol',
      AddictionType.socialMedia => 'Social Media',
      AddictionType.custom => 'Custom',
    };
  }
}
