import 'package:flutter/material.dart';

import '../../../models/diary_entry.dart';
import '../../../models/plant.dart';
import '../../../models/plant_health.dart';
import '../../../models/plant_species.dart';
import '../../plant/health_style.dart';

class PlantCard extends StatelessWidget {
  const PlantCard({
    super.key,
    required this.plant,
    required this.status,
    required this.onAction,
    required this.onChat,
    required this.onHistory,
    required this.health,
    this.species,
    this.lastWatered,
  });

  final Plant plant;
  final PlantStatus status;
  final PlantSpecies? species;
  final DateTime? lastWatered;
  final ValueChanged<DiaryAction> onAction;
  final VoidCallback onChat;
  final VoidCallback onHistory;
  final HealthReport health;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subtitle = [
      if (species != null) species!.name,
      plant.location,
    ].join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    species?.emoji ?? '🪴',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Histórico de cuidados',
                  onPressed: onHistory,
                  icon: const Icon(Icons.history_rounded),
                ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  tooltip: 'Falar com o Dr. FolhaVida',
                  onPressed: onChat,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _StatusPill(status: status),
                _HealthPill(health: health.health),
                Text(
                  _lastWateredText(lastWatered),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final action in DiaryAction.values) ...[
                  Expanded(
                    child: _ActionButton(
                      action: action,
                      onPressed: () => onAction(action),
                    ),
                  ),
                  if (action != DiaryAction.values.last)
                    const SizedBox(width: 8),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _lastWateredText(DateTime? last) {
    if (last == null) return 'Ainda sem regas registradas';
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(last.year, last.month, last.day))
        .inDays;
    return switch (days) {
      0 => 'Regada hoje',
      1 => 'Regada ontem',
      _ => 'Regada há $days dias',
    };
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final PlantStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg, icon) = switch (status) {
      PlantStatus.moist => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          Icons.water_drop_rounded,
        ),
      PlantStatus.waterToday => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
          Icons.notifications_active_rounded,
        ),
      PlantStatus.overdue => (
          scheme.errorContainer,
          scheme.onErrorContainer,
          Icons.warning_amber_rounded,
        ),
      PlantStatus.unknown => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
          Icons.help_outline_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthPill extends StatelessWidget {
  const _HealthPill({required this.health});

  final PlantHealth health;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = health.level.colors(Theme.of(context).colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${health.emoji} ${health.label}',
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.onPressed});

  final DiaryAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(action.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(action.label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
