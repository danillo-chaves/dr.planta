import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_limits.dart';
import '../models/diary_entry.dart';
import '../models/plant.dart';
import '../models/plant_health.dart';
import '../models/plant_species.dart';
import '../repositories/diary_repository.dart';
import '../repositories/plant_repository.dart';

/// Controller da Home: lista de plantas, diário de cuidados, status e saúde.
class PlantController extends ChangeNotifier {
  PlantController({
    required PlantRepository plantRepository,
    required DiaryRepository diaryRepository,
    this.isPremium = false,
  })  : _plants = plantRepository,
        _diary = diaryRepository;

  static const _uuid = Uuid();

  final PlantRepository _plants;
  final DiaryRepository _diary;

  /// Será ligado ao plano real quando a monetização existir.
  bool isPremium;

  List<Plant> _items = [];

  /// Todos os registros, do mais recente para o mais antigo.
  List<DiaryEntry> _entries = [];
  final Map<DiaryAction, Map<String, DateTime>> _lastByAction = {};
  bool _loading = false;

  List<Plant> get plants => List.unmodifiable(_items);
  bool get isLoading => _loading;
  bool get canAddPlant => isPremium || _items.length < AppLimits.freeMaxPlants;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    _items = await _plants.getAll();
    _entries = await _diary.getAll();
    _reindex();

    _loading = false;
    notifyListeners();
  }

  /// Cadastra uma planta ligada a uma [species] real. Os intervalos de cuidado
  /// saem da espécie, ajustados pela luz ([sunExposure]). Se [lastWateredAt]
  /// vier preenchido, vira o primeiro registro de rega no diário.
  ///
  /// [wateringHour]/[wateringMinute] é o horário em que o usuário rega (base
  /// dos lembretes). Retorna null se atingiu o limite do plano free.
  Future<Plant?> addPlant({
    required PlantSpecies species,
    required String name,
    required String location,
    required LightLevel sunExposure,
    required int wateringHour,
    required int wateringMinute,
    DateTime? lastWateredAt,
  }) async {
    if (!canAddPlant) return null;
    final plant = Plant(
      id: _uuid.v4(),
      name: name.trim(),
      speciesId: species.id,
      location: location.trim(),
      sunExposure: sunExposure,
      wateringHour: wateringHour,
      wateringMinute: wateringMinute,
      wateringIntervalDays: species.wateringIntervalFor(sunExposure),
      fertilizingIntervalDays: species.fertilizingIntervalDays,
      createdAt: DateTime.now(),
    );
    await _plants.save(plant);
    _items = [..._items, plant];
    if (lastWateredAt != null) {
      await logAction(plant.id, DiaryAction.water, date: lastWateredAt);
    } else {
      notifyListeners();
    }
    return plant;
  }

  Future<void> removePlant(String plantId) async {
    await _plants.delete(plantId);
    await _diary.deleteByPlant(plantId);
    _items = _items.where((p) => p.id != plantId).toList();
    _entries = _entries.where((e) => e.plantId != plantId).toList();
    _reindex();
    notifyListeners();
  }

  // ---------------------------------------------------------------- Diário

  /// Registro rápido de 1 toque (Reguei / Adubei / Podei).
  /// [date] permite registrar uma ação passada (ex: última rega no cadastro).
  Future<void> logAction(String plantId, DiaryAction action,
      {String? note, DateTime? date}) {
    return _addEntry(DiaryEntry(
      id: _uuid.v4(),
      plantId: plantId,
      action: action,
      date: date ?? DateTime.now(),
      note: note,
    ));
  }

  /// Histórico de uma planta (mais recente primeiro), opcionalmente filtrado.
  List<DiaryEntry> historyFor(String plantId, {DiaryAction? action}) {
    return _entries
        .where((e) => e.plantId == plantId && (action == null || e.action == action))
        .toList();
  }

  /// Remove um registro (ex: toque sem querer). Devolve o registro removido
  /// para a UI poder oferecer "Desfazer" via [restoreEntry].
  Future<DiaryEntry?> removeEntry(String entryId) async {
    final index = _entries.indexWhere((e) => e.id == entryId);
    if (index < 0) return null;
    final entry = _entries[index];
    await _diary.delete(entryId);
    _entries = [..._entries]..removeAt(index);
    _reindex();
    notifyListeners();
    return entry;
  }

  Future<void> restoreEntry(DiaryEntry entry) => _addEntry(entry);

  Future<void> _addEntry(DiaryEntry entry) async {
    await _diary.add(entry);
    _entries = [..._entries, entry];
    _reindex();
    notifyListeners();
  }

  /// Reordena os registros e refaz o índice "última vez de cada ação".
  void _reindex() {
    _entries.sort((a, b) => b.date.compareTo(a.date));
    _lastByAction.clear();
    for (final e in _entries) {
      _lastByAction
          .putIfAbsent(e.action, () => {})
          .putIfAbsent(e.plantId, () => e.date);
    }
  }

  DateTime? lastAction(String plantId, DiaryAction action) =>
      _lastByAction[action]?[plantId];

  // ---------------------------------------------------------------- Status

  /// Próxima rega: última rega + intervalo, no horário em que o usuário rega.
  /// Null enquanto não houver nenhuma rega registrada.
  DateTime? nextWateringFor(Plant plant) {
    final last = lastAction(plant.id, DiaryAction.water);
    if (last == null) return null;
    final due = _dateOnly(last).add(Duration(days: plant.wateringIntervalDays));
    return DateTime(
      due.year,
      due.month,
      due.day,
      plant.wateringHour,
      plant.wateringMinute,
    );
  }

  PlantStatus statusFor(Plant plant, {DateTime? now}) {
    final last = lastAction(plant.id, DiaryAction.water);
    if (last == null) return PlantStatus.unknown;

    final elapsed = _daysSince(last, now);
    if (elapsed < plant.wateringIntervalDays) return PlantStatus.moist;
    if (elapsed == plant.wateringIntervalDays) return PlantStatus.waterToday;
    return PlantStatus.overdue;
  }

  /// Avalia a saúde da planta pelos registros recentes. Em ordem de
  /// prioridade: rega muito atrasada, rega atrasada, excesso de água, luz
  /// inadequada (precisa da [species]), adubo atrasado e, se nada disso,
  /// saudável. Sem nenhuma rega registrada, não há dados para avaliar.
  HealthReport healthFor(Plant plant, {PlantSpecies? species, DateTime? now}) {
    final lastWater = lastAction(plant.id, DiaryAction.water);
    if (lastWater == null) {
      return const HealthReport(
        PlantHealth.unknown,
        'Registre a primeira rega para eu começar a acompanhar a saúde dela.',
      );
    }

    final interval = plant.wateringIntervalDays;
    final sinceWater = _daysSince(lastWater, now);

    if (sinceWater >= interval * 2 && sinceWater > interval + 1) {
      return HealthReport(
        PlantHealth.critical,
        'Faz $sinceWater dias sem rega (o ideal é a cada $interval). '
        'Regue assim que puder e observe se as folhas se recuperam.',
      );
    }
    if (sinceWater > interval) {
      final late = sinceWater - interval;
      return HealthReport(
        PlantHealth.thirsty,
        'A rega está atrasada há $late ${late == 1 ? 'dia' : 'dias'}. '
        'Que tal regar agora?',
      );
    }
    if (_overwatered(plant, sinceWater, now ?? DateTime.now())) {
      return const HealthReport(
        PlantHealth.overwatered,
        'Você regou várias vezes em pouco tempo. Espere o solo secar antes '
        'da próxima rega para não apodrecer as raízes.',
      );
    }
    if (species != null) {
      switch (species.lightFit(plant.sunExposure)) {
        case LightFit.tooMuch:
          return HealthReport(
            PlantHealth.lightIssue,
            'Ela recebe mais luz do que ${species.name} gosta. Se as folhas '
            'amarelarem ou queimarem, afaste da janela.',
          );
        case LightFit.tooLittle:
          return HealthReport(
            PlantHealth.lightIssue,
            'Ela recebe menos luz do que ${species.name} gosta. Se crescer '
            'fraca ou esticada, aproxime de uma janela.',
          );
        case LightFit.ideal:
          break;
      }
    }

    final lastFertilized = lastAction(plant.id, DiaryAction.fertilize);
    final sinceFertilizer = _daysSince(lastFertilized ?? plant.createdAt, now);
    if (sinceFertilizer > plant.fertilizingIntervalDays + 7) {
      return HealthReport(
        PlantHealth.hungry,
        lastFertilized == null
            ? 'Ela ainda não foi adubada. O ideal é a cada '
                '${plant.fertilizingIntervalDays} dias.'
            : 'Faz $sinceFertilizer dias desde a última adubação (o ideal é a '
                'cada ${plant.fertilizingIntervalDays}).',
      );
    }

    return HealthReport(
      PlantHealth.thriving,
      sinceWater == interval
          ? 'Tudo certo com os registros recentes. Hoje é dia de regar!'
          : 'Sua planta está saudável de acordo com os registros recentes.',
    );
  }

  /// Excesso de rega: 3+ regas dentro de um intervalo, ou as duas últimas
  /// regas muito próximas (menos de 40% do intervalo) em plantas de rega
  /// espaçada.
  bool _overwatered(Plant plant, int sinceLastWater, DateTime now) {
    final interval = plant.wateringIntervalDays;
    if (sinceLastWater >= interval) return false;

    final waters = historyFor(plant.id, action: DiaryAction.water);
    final windowStart = now.subtract(Duration(days: interval));
    if (waters.where((e) => e.date.isAfter(windowStart)).length >= 3) {
      return true;
    }
    if (interval >= 4 && waters.length >= 2) {
      final gap = waters[0].date.difference(waters[1].date);
      return gap < Duration(hours: (interval * 24 * 0.4).round());
    }
    return false;
  }

  int _daysSince(DateTime date, DateTime? now) =>
      _dateOnly(now ?? DateTime.now()).difference(_dateOnly(date)).inDays;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
