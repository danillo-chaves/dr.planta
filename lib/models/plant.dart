import 'plant_species.dart';

/// Estado simples exibido no card da planta (Home).
enum PlantStatus {
  moist('Solo úmido'),
  waterToday('Regar hoje'),
  overdue('Rega atrasada'),
  unknown('Sem registros');

  const PlantStatus(this.label);
  final String label;
}

/// Planta cadastrada pelo usuário ("vaso"), sempre ligada a uma espécie real
/// do catálogo. Os intervalos de cuidado já vêm calculados a partir da espécie
/// e da luz que a planta recebe.
class Plant {
  const Plant({
    required this.id,
    required this.name,
    required this.speciesId,
    required this.location,
    required this.sunExposure,
    required this.wateringHour,
    required this.wateringMinute,
    required this.wateringIntervalDays,
    required this.fertilizingIntervalDays,
    required this.createdAt,
    this.photoPath,
  });

  final String id;

  /// Apelido dado pelo usuário (ex: "Jiboia da sala").
  final String name;

  /// Espécie do catálogo que define os cuidados.
  final String speciesId;

  /// Onde a planta fica (ex: "Sala", "Varanda"). Vai no contexto da IA.
  final String location;

  /// Quanta luz a planta realmente recebe neste local.
  final LightLevel sunExposure;

  /// Horário em que o usuário rega (base dos lembretes).
  final int wateringHour;
  final int wateringMinute;

  /// Intervalos efetivos, já ajustados pela luz recebida.
  final int wateringIntervalDays;
  final int fertilizingIntervalDays;

  final DateTime createdAt;
  final String? photoPath;

  Plant copyWith({
    String? name,
    String? location,
    LightLevel? sunExposure,
    int? wateringHour,
    int? wateringMinute,
    int? wateringIntervalDays,
    int? fertilizingIntervalDays,
    String? photoPath,
  }) {
    return Plant(
      id: id,
      speciesId: speciesId,
      createdAt: createdAt,
      name: name ?? this.name,
      location: location ?? this.location,
      sunExposure: sunExposure ?? this.sunExposure,
      wateringHour: wateringHour ?? this.wateringHour,
      wateringMinute: wateringMinute ?? this.wateringMinute,
      wateringIntervalDays: wateringIntervalDays ?? this.wateringIntervalDays,
      fertilizingIntervalDays:
          fertilizingIntervalDays ?? this.fertilizingIntervalDays,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] as String,
      name: json['name'] as String,
      speciesId: json['speciesId'] as String,
      location: json['location'] as String,
      sunExposure: LightLevel.values.byName(json['sunExposure'] as String),
      wateringHour: json['wateringHour'] as int,
      wateringMinute: json['wateringMinute'] as int,
      wateringIntervalDays: json['wateringIntervalDays'] as int,
      fertilizingIntervalDays: json['fertilizingIntervalDays'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      photoPath: json['photoPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'speciesId': speciesId,
        'location': location,
        'sunExposure': sunExposure.name,
        'wateringHour': wateringHour,
        'wateringMinute': wateringMinute,
        'wateringIntervalDays': wateringIntervalDays,
        'fertilizingIntervalDays': fertilizingIntervalDays,
        'createdAt': createdAt.toIso8601String(),
        'photoPath': photoPath,
      };
}
