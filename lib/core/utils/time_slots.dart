class SlotRange {
  const SlotRange({required this.startSlot, required this.endSlot});

  /// Inclusive start slot. Slots are 30-min intervals in `[0, 47]`.
  final int startSlot;

  /// Exclusive end slot. Can be less than [startSlot] to indicate wrap-around.
  final int endSlot;

  bool get wrapsMidnight => endSlot < startSlot;

  int get slotCount {
    if (!wrapsMidnight) return endSlot - startSlot;
    return (48 - startSlot) + endSlot;
  }
}

List<SlotRange> slotRangesFrom(Set<int> slots) {
  if (slots.isEmpty) return const <SlotRange>[];

  final sorted = slots.toList()..sort();
  final ranges = <SlotRange>[];

  var start = sorted.first;
  var prev = sorted.first;
  for (var i = 1; i < sorted.length; i++) {
    final current = sorted[i];
    if (current == prev + 1) {
      prev = current;
      continue;
    }
    ranges.add(SlotRange(startSlot: start, endSlot: prev + 1));
    start = current;
    prev = current;
  }
  ranges.add(SlotRange(startSlot: start, endSlot: prev + 1));

  // Merge midnight wrap (e.g. 47,0).
  if (ranges.length >= 2 &&
      ranges.first.startSlot == 0 &&
      ranges.last.endSlot == 48) {
    final merged = SlotRange(
      startSlot: ranges.last.startSlot,
      endSlot: ranges.first.endSlot,
    );
    ranges
      ..removeLast()
      ..removeAt(0)
      ..insert(0, merged);
  }

  return ranges;
}

SlotRange? longestSlotRange(Set<int> slots) {
  final ranges = slotRangesFrom(slots);
  if (ranges.isEmpty) return null;
  ranges.sort((a, b) => b.slotCount.compareTo(a.slotCount));
  return ranges.first;
}

String formatMinutesTime(int minutes) {
  final normalized = minutes % 1440;
  final hour24 = normalized ~/ 60;
  final minute = normalized % 60;

  final isPm = hour24 >= 12;
  var hour12 = hour24 % 12;
  if (hour12 == 0) hour12 = 12;

  final mm = minute.toString().padLeft(2, '0');
  final suffix = isPm ? 'PM' : 'AM';
  return '$hour12:$mm $suffix';
}

String formatSlotTime(int slot) {
  final minutes = (slot % 48) * 30;
  return formatMinutesTime(minutes);
}

String formatSlotRange(SlotRange range) {
  final start = formatSlotTime(range.startSlot);
  final end = formatSlotTime(range.endSlot % 48);
  return '$start – $end';
}
