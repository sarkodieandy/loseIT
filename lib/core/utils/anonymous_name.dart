String anonymousNameFor(String userId) {
  final compact = userId.replaceAll('-', '').toUpperCase();
  final suffix = compact.length >= 4 ? compact.substring(0, 4) : compact.padRight(4, '0');
  return 'SoberFriend#$suffix';
}
