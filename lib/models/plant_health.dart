/// Gravidade usada pela UI para escolher a cor do status.
enum HealthLevel { good, neutral, warning, danger }

/// Situação de saúde da planta, calculada a partir do diário recente.
enum PlantHealth {
  thriving('Saudável', '🌿', HealthLevel.good),
  unknown('Sem dados', '🌱', HealthLevel.neutral),
  lightIssue('Luz inadequada', '☀️', HealthLevel.warning),
  hungry('Precisa de adubo', '🍽️', HealthLevel.warning),
  overwatered('Excesso de água', '🌊', HealthLevel.warning),
  thirsty('Com sede', '🥵', HealthLevel.warning),
  critical('Em risco', '🥀', HealthLevel.danger);

  const PlantHealth(this.label, this.emoji, this.level);
  final String label;
  final String emoji;
  final HealthLevel level;
}

/// Situação de saúde + explicação curta para o usuário.
class HealthReport {
  const HealthReport(this.health, this.message);

  final PlantHealth health;
  final String message;
}
