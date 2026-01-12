class FormatUtils {
  FormatUtils._();

  static String elapsed(DateTime timestamp) {
    final duration = DateTime.now().difference(timestamp);
    if (duration.inMinutes < 1) {
      return 'just now';
    }
    if (duration.inHours < 1) {
      return '${duration.inMinutes} min ago';
    }
    if (duration.inDays < 1) {
      return '${duration.inHours} hr ago';
    }
    return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'} ago';
  }
}
