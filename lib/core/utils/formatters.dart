import 'package:intl/intl.dart';

class Formatters {
  static final DateFormat date = DateFormat.yMMMd();
  static final DateFormat time = DateFormat.jm();

  static String formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    return '${days}d ${hours}h ${minutes}m';
  }

  static String formatMoney(double value) {
    final formatter = NumberFormat.simpleCurrency();
    return formatter.format(value);
  }

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.yMMMd().format(date);
  }
}
