import 'package:flutter/material.dart';

import '../../models/plant_health.dart';

/// Cores de cada gravidade de saúde, derivadas do tema.
extension HealthLevelColors on HealthLevel {
  (Color background, Color foreground) colors(ColorScheme scheme) =>
      switch (this) {
        HealthLevel.good => (scheme.primaryContainer, scheme.onPrimaryContainer),
        HealthLevel.neutral => (
            scheme.surfaceContainerHighest,
            scheme.onSurfaceVariant,
          ),
        HealthLevel.warning => (
            scheme.tertiaryContainer,
            scheme.onTertiaryContainer,
          ),
        HealthLevel.danger => (scheme.errorContainer, scheme.onErrorContainer),
      };
}
