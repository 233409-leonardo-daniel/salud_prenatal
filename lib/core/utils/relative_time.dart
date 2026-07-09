/// Formatea una fecha como tiempo relativo en español ("Hace 5 min",
/// "Hace 3 h", "Hace 2 d"), similar a lo que muestran Facebook/Twitter.
/// Para fechas de más de una semana, muestra la fecha corta (dd/mm/aaaa).
String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
  final difference = now.difference(localDateTime);

  if (difference.isNegative || difference.inSeconds < 30) {
    return 'Hace un momento';
  }
  if (difference.inMinutes < 1) {
    return 'Hace ${difference.inSeconds} s';
  }
  if (difference.inHours < 1) {
    return 'Hace ${difference.inMinutes} min';
  }
  if (difference.inDays < 1) {
    return 'Hace ${difference.inHours} h';
  }
  if (difference.inDays < 7) {
    return 'Hace ${difference.inDays} d';
  }

  final day = localDateTime.day.toString().padLeft(2, '0');
  final month = localDateTime.month.toString().padLeft(2, '0');
  return '$day/$month/${localDateTime.year}';
}
