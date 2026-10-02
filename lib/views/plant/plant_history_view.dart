import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/plant_controller.dart';
import '../../controllers/species_controller.dart';
import '../../core/utils/date_format.dart';
import '../../models/diary_entry.dart';
import '../../models/plant.dart';
import '../../models/plant_health.dart';
import 'health_style.dart';

/// Histórico de cuidados de uma planta + avaliação de saúde.
class PlantHistoryView extends StatefulWidget {
  const PlantHistoryView({super.key, required this.plant});

  final Plant plant;

  @override
  State<PlantHistoryView> createState() => _PlantHistoryViewState();
}

class _PlantHistoryViewState extends State<PlantHistoryView> {
  DiaryAction? _filter; // null = todos

  Future<void> _remove(DiaryEntry entry) async {
    final controller = context.read<PlantController>();
    final messenger = ScaffoldMessenger.of(context);
    final removed = await controller.removeEntry(entry.id);
    if (removed == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('Registro removido'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => controller.restoreEntry(removed),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final plants = context.watch<PlantController>();
    final species = context.read<SpeciesController>().byId(widget.plant.speciesId);
    final health = plants.healthFor(widget.plant, species: species);
    final entries = plants.historyFor(widget.plant.id, action: _filter);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.plant.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _HealthCard(report: health),
          const SizedBox(height: 12),
          _WateringSummary(
            last: plants.lastAction(widget.plant.id, DiaryAction.water),
            next: plants.nextWateringFor(widget.plant),
          ),
          const SizedBox(height: 24),
          Text(
            'Histórico',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              for (final action in DiaryAction.values)
                ChoiceChip(
                  label: Text('${action.emoji} ${action.label}'),
                  selected: _filter == action,
                  onSelected: (_) => setState(() => _filter = action),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const _EmptyHistory()
          else
            ..._buildGroups(entries),
        ],
      ),
    );
  }

  /// Agrupa os registros (já ordenados) por dia, com um cabeçalho em cada.
  List<Widget> _buildGroups(List<DiaryEntry> entries) {
    final widgets = <Widget>[];
    String? currentDay;
    for (final entry in entries) {
      final label = dayLabel(entry.date);
      if (label != currentDay) {
        currentDay = label;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ));
      }
      widgets.add(_EntryTile(entry: entry, onDelete: () => _remove(entry)));
    }
    return widgets;
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.report});

  final HealthReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg) = report.health.level.colors(theme.colorScheme);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(report.health.emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.health.label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(report.message, style: TextStyle(color: fg)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WateringSummary extends StatelessWidget {
  const _WateringSummary({required this.last, required this.next});

  final DateTime? last;
  final DateTime? next;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            emoji: '💧',
            label: 'Última rega',
            value: last == null
                ? 'Sem registro'
                : '${dayLabel(last!)}, ${formatTime(last!)}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            emoji: '🔔',
            label: 'Próxima rega',
            value: next == null
                ? '—'
                : '${dayLabel(next!)}, ${formatTime(next!)}',
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.emoji,
    required this.label,
    required this.value,
  });

  final String emoji;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$emoji $label',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.onDelete});

  final DiaryEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Text(entry.action.emoji, style: const TextStyle(fontSize: 18)),
        ),
        title: Text(entry.action.label),
        subtitle: Text(
          entry.note == null || entry.note!.isEmpty
              ? formatTime(entry.date)
              : '${formatTime(entry.date)} · ${entry.note}',
        ),
        trailing: IconButton(
          tooltip: 'Remover registro',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Text('📝', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 8),
          Text(
            'Nenhum registro por aqui',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Toque em Reguei, Adubei ou Podei no card da planta para registrar.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
