import 'package:dr_folha_vida/controllers/plant_controller.dart';
import 'package:dr_folha_vida/core/constants/app_limits.dart';
import 'package:dr_folha_vida/models/diary_entry.dart';
import 'package:dr_folha_vida/models/plant.dart';
import 'package:dr_folha_vida/models/plant_health.dart';
import 'package:dr_folha_vida/models/plant_species.dart';
import 'package:dr_folha_vida/repositories/memory/in_memory_diary_repository.dart';
import 'package:dr_folha_vida/repositories/memory/in_memory_plant_repository.dart';
import 'package:dr_folha_vida/repositories/memory/local_species_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PlantController controller;
  late PlantSpecies jiboia; // luz ideal: indireta, rega a cada 7 dias

  Future<Plant?> add({
    PlantSpecies? species,
    LightLevel? light,
    DateTime? lastWateredAt,
  }) {
    final s = species ?? jiboia;
    return controller.addPlant(
      species: s,
      name: s.name,
      location: 'Sala',
      sunExposure: light ?? s.light,
      wateringHour: 8,
      wateringMinute: 30,
      lastWateredAt: lastWateredAt,
    );
  }

  setUp(() async {
    final species = await LocalSpeciesRepository().getAll();
    jiboia = species.firstWhere((s) => s.id == 'jiboia');
    controller = PlantController(
      plantRepository: InMemoryPlantRepository(),
      diaryRepository: InMemoryDiaryRepository(),
    );
    await controller.load();
  });

  test('plano free bloqueia a 4ª planta', () async {
    for (var i = 0; i < AppLimits.freeMaxPlants; i++) {
      expect(await add(), isNotNull);
    }
    expect(controller.canAddPlant, isFalse);
    expect(await add(), isNull);

    controller.isPremium = true;
    expect(await add(), isNotNull);
  });

  test('cuidados vêm da espécie e a luz ajusta a rega', () async {
    final ideal = (await add())!;
    expect(ideal.speciesId, 'jiboia');
    expect(ideal.wateringIntervalDays, 7);
    expect(ideal.fertilizingIntervalDays, jiboia.fertilizingIntervalDays);

    final sunny = (await add(light: LightLevel.high))!;
    expect(sunny.wateringIntervalDays, lessThan(7)); // seca mais rápido

    final dark = (await add(light: LightLevel.low))!;
    expect(dark.wateringIntervalDays, greaterThan(7)); // seca mais devagar
  });

  test('luz demais ou de menos muda o intervalo da espécie', () async {
    final basil = (await LocalSpeciesRepository().getAll())
        .firstWhere((s) => s.id == 'manjericao'); // rega a cada 2 dias
    final fit = basil.lightFit(LightLevel.low);
    expect(fit, LightFit.tooLittle);
    expect(basil.wateringIntervalFor(LightLevel.low), greaterThan(2));
    expect(basil.wateringIntervalFor(LightLevel.high), 2);
  });

  test('última rega informada no cadastro vira registro no diário', () async {
    final when = DateTime.now().subtract(const Duration(days: 2));
    final plant = (await add(lastWateredAt: when))!;

    expect(controller.lastAction(plant.id, DiaryAction.water), when);
    expect(controller.statusFor(plant), PlantStatus.moist);

    final next = controller.nextWateringFor(plant)!;
    expect(next.hour, 8);
    expect(next.minute, 30);
    expect(
      DateTime(next.year, next.month, next.day)
          .difference(DateTime(when.year, when.month, when.day))
          .inDays,
      7,
    );
  });

  test('sem rega informada o status é desconhecido e não há próxima rega',
      () async {
    final plant = (await add())!;
    expect(controller.statusFor(plant), PlantStatus.unknown);
    expect(controller.nextWateringFor(plant), isNull);
  });

  test('registro antigo não sobrescreve uma rega mais recente', () async {
    final plant = (await add())!;
    final recent = DateTime.now();
    await controller.logAction(plant.id, DiaryAction.water, date: recent);
    await controller.logAction(
      plant.id,
      DiaryAction.water,
      date: recent.subtract(const Duration(days: 5)),
    );
    expect(controller.lastAction(plant.id, DiaryAction.water), recent);
  });

  test('status segue o intervalo de rega', () async {
    final plant = (await add(lastWateredAt: DateTime.now()))!;
    final now = DateTime.now();
    final interval = plant.wateringIntervalDays;

    expect(controller.statusFor(plant, now: now), PlantStatus.moist);
    expect(
      controller.statusFor(plant, now: now.add(Duration(days: interval))),
      PlantStatus.waterToday,
    );
    expect(
      controller.statusFor(plant, now: now.add(Duration(days: interval + 2))),
      PlantStatus.overdue,
    );
  });

  group('histórico', () {
    test('ações viram registros, mais recente primeiro, com filtro', () async {
      final plant = (await add())!;
      final t = DateTime.now();
      await controller.logAction(plant.id, DiaryAction.water,
          date: t.subtract(const Duration(days: 3)));
      await controller.logAction(plant.id, DiaryAction.prune, date: t);
      await controller.logAction(plant.id, DiaryAction.fertilize,
          date: t.subtract(const Duration(days: 1)));

      final all = controller.historyFor(plant.id);
      expect(all.map((e) => e.action),
          [DiaryAction.prune, DiaryAction.fertilize, DiaryAction.water]);
      expect(controller.historyFor(plant.id, action: DiaryAction.water),
          hasLength(1));
    });

    test('remover e desfazer atualizam a última ação', () async {
      final plant = (await add())!;
      final older = DateTime.now().subtract(const Duration(days: 4));
      await controller.logAction(plant.id, DiaryAction.water, date: older);
      await controller.logAction(plant.id, DiaryAction.water);

      final newest = controller.historyFor(plant.id).first;
      final removed = await controller.removeEntry(newest.id);
      expect(removed?.id, newest.id);
      expect(controller.lastAction(plant.id, DiaryAction.water), older);

      await controller.restoreEntry(removed!);
      expect(controller.lastAction(plant.id, DiaryAction.water), newest.date);
      expect(await controller.removeEntry('nao-existe'), isNull);
    });
  });

  group('saúde', () {
    test('sem nenhuma rega não há dados', () async {
      final plant = (await add())!;
      expect(controller.healthFor(plant, species: jiboia).health,
          PlantHealth.unknown);
    });

    test('regada em dia, luz ideal e adubo em dia: saudável', () async {
      final plant = (await add(lastWateredAt: DateTime.now()))!;
      expect(controller.healthFor(plant, species: jiboia).health,
          PlantHealth.thriving);
    });

    test('rega atrasada: com sede; muito atrasada: em risco', () async {
      final plant = (await add(lastWateredAt: DateTime.now()))!;
      final now = DateTime.now();
      expect(
        controller
            .healthFor(plant, species: jiboia, now: now.add(const Duration(days: 9)))
            .health,
        PlantHealth.thirsty,
      );
      expect(
        controller
            .healthFor(plant, species: jiboia, now: now.add(const Duration(days: 15)))
            .health,
        PlantHealth.critical,
      );
    });

    test('regar duas vezes em poucas horas: excesso de água', () async {
      final plant = (await add(
        lastWateredAt: DateTime.now().subtract(const Duration(hours: 3)),
      ))!;
      await controller.logAction(plant.id, DiaryAction.water);
      expect(controller.healthFor(plant, species: jiboia).health,
          PlantHealth.overwatered);
    });

    test('luz diferente da ideal: luz inadequada', () async {
      final plant =
          (await add(light: LightLevel.high, lastWateredAt: DateTime.now()))!;
      expect(controller.healthFor(plant, species: jiboia).health,
          PlantHealth.lightIssue);
    });

    test('muito tempo sem adubar: precisa de adubo; adubar resolve', () async {
      final plant = (await add())!;
      final now = DateTime.now().add(const Duration(days: 45));
      // Rega em dia (ontem, em relação a "now"), mas sem nunca ter adubado.
      await controller.logAction(plant.id, DiaryAction.water,
          date: now.subtract(const Duration(days: 1)));
      expect(controller.healthFor(plant, species: jiboia, now: now).health,
          PlantHealth.hungry);

      await controller.logAction(plant.id, DiaryAction.fertilize, date: now);
      expect(controller.healthFor(plant, species: jiboia, now: now).health,
          PlantHealth.thriving);
    });
  });
}
