String _two(int n) => n.toString().padLeft(2, '0');

String formatDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}';

String formatTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

/// "Hoje", "Ontem" ou "dd/MM/aaaa".
String dayLabel(DateTime d, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final days = DateTime(today.year, today.month, today.day)
      .difference(DateTime(d.year, d.month, d.day))
      .inDays;
  return switch (days) {
    0 => 'Hoje',
    1 => 'Ontem',
    _ => '${formatDate(d)}/${d.year}',
  };
}
