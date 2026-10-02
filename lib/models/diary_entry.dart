/// Ações de registro rápido (1 toque) do diário.
enum DiaryAction {
  water('Reguei', '🪵'),
  fertilize('Adubei', '🧪'),
  prune('Podei', '✂️');

  const DiaryAction(this.label, this.emoji);
  final String label;
  final String emoji;
}

/// Registro do diário de cuidados de uma planta.
class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.plantId,
    required this.action,
    required this.date,
    this.note,
  });

  final String id;
  final String plantId;
  final DiaryAction action;
  final DateTime date;
  final String? note;

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String,
      plantId: json['plantId'] as String,
      action: DiaryAction.values.byName(json['action'] as String),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'plantId': plantId,
        'action': action.name,
        'date': date.toIso8601String(),
        'note': note,
      };
}
