import 'dart:math' as math;

enum LightLevel {
  low('Pouca luz', '🌥️'),
  medium('Luz indireta', '⛅'),
  high('Sol pleno', '☀️');

  const LightLevel(this.label, this.emoji);
  final String label;
  final String emoji;
}

/// Ficha de espécie do catálogo (100% local/offline).
class PlantSpecies {
  const PlantSpecies({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.emoji,
    required this.description,
    required this.light,
    required this.wateringIntervalDays,
    required this.fertilizingIntervalDays,
    required this.petFriendly,
    required this.dos,
    required this.donts,
    this.aliases = const [],
  });

  final String id;
  final String name;
  final String scientificName;
  final String emoji;
  final String description;
  final LightLevel light;
  final int wateringIntervalDays;
  final int fertilizingIntervalDays;
  final bool petFriendly;

  /// O que pode / o que não pode fazer.
  final List<String> dos;
  final List<String> donts;

  /// Outros nomes populares, usados na busca.
  final List<String> aliases;

  /// Compara a luz que a planta recebe com a que a espécie prefere.
  LightFit lightFit(LightLevel actual) {
    final diff = actual.index - light.index;
    if (diff == 0) return LightFit.ideal;
    return diff > 0 ? LightFit.tooMuch : LightFit.tooLittle;
  }

  /// Intervalo de rega ajustado pela luz: com mais luz o solo seca mais rápido
  /// (rega mais frequente); com menos luz, mais devagar. Cada nível de
  /// diferença muda o intervalo em cerca de 20-25%.
  int wateringIntervalFor(LightLevel actual) {
    final diff = actual.index - light.index;
    if (diff == 0) return wateringIntervalDays;
    final factor = math.pow(diff > 0 ? 0.8 : 1.25, diff.abs());
    return math.max(1, (wateringIntervalDays * factor).round());
  }
}

/// Resultado de [PlantSpecies.lightFit].
enum LightFit { ideal, tooMuch, tooLittle }
