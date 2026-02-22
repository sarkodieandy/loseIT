import '../../data/models/journal_entry.dart';
import '../../data/models/mood_log.dart';
import '../../data/models/relapse_log.dart';

enum RiskLevel { low, medium, high }

class RiskInsight {
  const RiskInsight({
    required this.score,
    required this.level,
    required this.factors,
    required this.suggestions,
    required this.hotHours,
    required this.topWords,
  });

  /// 0..100
  final int score;
  final RiskLevel level;
  final List<String> factors;
  final List<String> suggestions;

  /// Hours (0-23) that appear frequently in relapse logs / low moods.
  final List<int> hotHours;

  /// Token -> count from recent journal/relapse notes.
  final Map<String, int> topWords;
}

class WeeklyReport {
  const WeeklyReport({
    required this.start,
    required this.end,
    required this.journalCount,
    required this.moodCount,
    required this.relapseCount,
    required this.moodBreakdown,
    required this.moneySaved,
    required this.timeRegainedHours,
    required this.highlights,
  });

  final DateTime start;
  final DateTime end;
  final int journalCount;
  final int moodCount;
  final int relapseCount;
  final Map<String, int> moodBreakdown;
  final double moneySaved;
  final double timeRegainedHours;
  final List<String> highlights;
}

class InsightsEngine {
  static WeeklyReport buildWeeklyReport({
    required DateTime now,
    required List<JournalEntry> journal,
    required List<MoodLog> moods,
    required List<RelapseLog> relapses,
    required double dailySpend,
    required int dailyMinutes,
    String? habitId,
  }) {
    final end = now;
    final start = now.subtract(const Duration(days: 7));
    final journalInRange = journal.where((e) {
      if (habitId != null && e.habitId != habitId) return false;
      return e.entryDate.isAfter(start);
    }).toList(growable: false);

    final moodsInRange = moods.where((m) {
      final date = DateTime(m.loggedDate.year, m.loggedDate.month, m.loggedDate.day);
      return date.isAfter(DateTime(start.year, start.month, start.day));
    }).toList(growable: false);

    final relapsesInRange = relapses.where((r) => r.relapseDate.isAfter(start)).toList(growable: false);

    final moodBreakdown = <String, int>{};
    for (final log in moodsInRange) {
      final key = log.mood.trim().toLowerCase();
      if (key.isEmpty) continue;
      moodBreakdown[key] = (moodBreakdown[key] ?? 0) + 1;
    }

    final moneySaved = dailySpend * 7.0;
    final timeRegainedHours = (dailyMinutes * 7) / 60.0;

    final highlights = <String>[];
    if (journalInRange.isNotEmpty) {
      highlights.add('You journaled ${journalInRange.length} time(s) in the last 7 days.');
    } else {
      highlights.add('No journal entries in the last 7 days.');
    }
    if (moodsInRange.isNotEmpty) {
      final topMood = moodBreakdown.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (topMood.isNotEmpty) {
        highlights.add('Most logged mood: ${topMood.first.key}.');
      }
    }
    if (relapsesInRange.isNotEmpty) {
      highlights.add('Relapse logs: ${relapsesInRange.length}. Be kind to yourself and keep going.');
    }

    return WeeklyReport(
      start: start,
      end: end,
      journalCount: journalInRange.length,
      moodCount: moodsInRange.length,
      relapseCount: relapsesInRange.length,
      moodBreakdown: moodBreakdown,
      moneySaved: moneySaved,
      timeRegainedHours: timeRegainedHours,
      highlights: highlights,
    );
  }

  static RiskInsight buildRiskForecast({
    required DateTime now,
    required DateTime soberStart,
    required List<JournalEntry> journal,
    required List<MoodLog> moods,
    required List<RelapseLog> relapses,
    String? habitId,
  }) {
    var score = 20;
    final factors = <String>[];
    final suggestions = <String>[];

    // Journal gap risk
    final recentJournal = journal
        .where((e) => habitId == null || e.habitId == habitId)
        .toList(growable: false);
    recentJournal.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    final lastEntry = recentJournal.isEmpty ? null : recentJournal.first.entryDate;
    if (lastEntry == null) {
      score += 20;
      factors.add('No journal entries yet.');
      suggestions.add('Write a 2-minute check-in to clear your head.');
    } else {
      final gapDays = now.difference(lastEntry).inDays;
      if (gapDays >= 4) {
        score += 30;
        factors.add('No journal entry in $gapDays days.');
        suggestions.add('Do a quick journal check-in (even 2 sentences).');
      } else if (gapDays >= 2) {
        score += 15;
        factors.add('Journal gap: $gapDays days.');
        suggestions.add('Log how today is going to reduce rumination.');
      }
    }

    // Mood risk (last 3 days)
    final cutoffMood = now.subtract(const Duration(days: 3));
    final recentMoods = moods.where((m) => m.loggedDate.isAfter(cutoffMood)).toList(growable: false);
    final negativeCount = _countNegativeMoods(recentMoods);
    if (recentMoods.isEmpty) {
      score += 5;
      factors.add('No mood check-ins recently.');
      suggestions.add('Log a mood check-in to spot patterns.');
    } else if (negativeCount >= 3) {
      score += 25;
      factors.add('High stress/low mood trend recently.');
      suggestions.add('Open Craving Rescue and do a 90s breathing reset.');
    } else if (negativeCount >= 1) {
      score += 12;
      factors.add('Some stress/low mood in the last few days.');
      suggestions.add('Try a short walk + 90s breathing reset.');
    }

    // Relapse history (last 30 days)
    final cutoffRelapse = now.subtract(const Duration(days: 30));
    final recentRelapses = relapses.where((r) => r.relapseDate.isAfter(cutoffRelapse)).toList(growable: false);
    if (recentRelapses.isNotEmpty) {
      final add = (recentRelapses.length * 12).clamp(12, 36).toInt();
      score += add;
      factors.add('Recent relapse activity in the last 30 days.');
      suggestions.add('Make a simple if/then plan for your top trigger.');
    }

    // Hot hours (from relapse logs + negative moods)
    final hotHours = _hotHours(now: now, moods: moods, relapses: relapses);
    if (hotHours.contains(now.hour)) {
      score += 10;
      factors.add('This time of day is a common trigger window for you.');
      suggestions.add('Avoid scrolling and switch to a planned distraction.');
    }

    // Streak factor (compassionate): very early days can be fragile.
    final streakDays = now.difference(soberStart).inDays + 1;
    if (streakDays <= 3) {
      score += 8;
      factors.add('Early streak days can feel intense. Keep support close.');
      suggestions.add('Post a quick check-in in the community for encouragement.');
    }

    score = score.clamp(0, 100);
    final level = score >= 70
        ? RiskLevel.high
        : score >= 40
            ? RiskLevel.medium
            : RiskLevel.low;

    final topWords = _topWords(
      journal: journal,
      relapses: relapses,
      now: now,
      habitId: habitId,
    );

    return RiskInsight(
      score: score,
      level: level,
      factors: factors.take(5).toList(growable: false),
      suggestions: suggestions.take(5).toList(growable: false),
      hotHours: hotHours,
      topWords: topWords,
    );
  }

  static int _countNegativeMoods(List<MoodLog> moods) {
    var count = 0;
    for (final log in moods) {
      final mood = log.mood.trim().toLowerCase();
      if (mood.isEmpty) continue;
      if (mood.contains('stress') ||
          mood.contains('sad') ||
          mood.contains('anx') ||
          mood.contains('angry') ||
          mood.contains('tired') ||
          mood.contains('lonely')) {
        count += 1;
      }
    }
    return count;
  }

  static List<int> _hotHours({
    required DateTime now,
    required List<MoodLog> moods,
    required List<RelapseLog> relapses,
  }) {
    final counts = <int, int>{};

    final relapseCutoff = now.subtract(const Duration(days: 60));
    for (final r in relapses) {
      if (r.relapseDate.isBefore(relapseCutoff)) continue;
      final h = r.relapseDate.hour;
      counts[h] = (counts[h] ?? 0) + 2;
    }

    final moodCutoff = now.subtract(const Duration(days: 14));
    for (final m in moods) {
      if (m.loggedDate.isBefore(moodCutoff)) continue;
      final mood = m.mood.trim().toLowerCase();
      if (mood.contains('stress') || mood.contains('sad') || mood.contains('anx')) {
        // Use a loose proxy: if mood logged, likely around user's typical check-in time.
        final h = m.createdAt.hour;
        counts[h] = (counts[h] ?? 0) + 1;
      }
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).map((e) => e.key).toList(growable: false);
  }

  static Map<String, int> _topWords({
    required List<JournalEntry> journal,
    required List<RelapseLog> relapses,
    required DateTime now,
    String? habitId,
  }) {
    final cutoff = now.subtract(const Duration(days: 14));
    final buffers = <String>[];

    for (final e in journal) {
      if (habitId != null && e.habitId != habitId) continue;
      if (e.entryDate.isBefore(cutoff)) continue;
      buffers.add(e.content);
    }
    for (final r in relapses) {
      if (r.relapseDate.isBefore(cutoff)) continue;
      if (r.note != null) buffers.add(r.note!);
    }

    final text = buffers.join(' ').toLowerCase();
    final tokens = text
        .replaceAll(RegExp(r'[^a-z0-9\\s]'), ' ')
        .split(RegExp(r'\\s+'))
        .where((t) => t.length >= 3 && t.length <= 18)
        .where((t) => !_stopwords.contains(t))
        .toList(growable: false);

    final counts = <String, int>{};
    for (final t in tokens) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map<String, int>.fromEntries(entries.take(8));
  }

  static const Set<String> _stopwords = <String>{
    'the',
    'and',
    'for',
    'that',
    'this',
    'with',
    'have',
    'just',
    'like',
    'from',
    'when',
    'then',
    'were',
    'been',
    'what',
    'your',
    'you',
    'but',
    'not',
    'are',
    'was',
    'too',
    'out',
    'into',
    'over',
    'after',
    'before',
    'today',
    'yesterday',
    'really',
    'very',
    'feel',
    'feels',
    'feeling',
    'about',
    'still',
    'back',
    'again',
    'time',
    'times',
    'week',
    'weeks',
    'month',
    'months',
    'day',
    'days',
    'now',
    'there',
    'here',
    'they',
    'them',
    'their',
    'im',
    'its',
    'cant',
    'don',
    'didn',
    'doesn',
    'won',
    'should',
    'could',
    'would',
    'because',
    'also',
    'more',
    'less',
  };
}
