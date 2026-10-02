import 'package:dr_folha_vida/controllers/species_controller.dart';
import 'package:dr_folha_vida/repositories/memory/local_species_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SpeciesController controller;

  setUp(() async {
    controller = SpeciesController(repository: LocalSpeciesRepository());
    await controller.load();
  });

  test('busca vazia devolve o catálogo inteiro', () {
    expect(controller.search('  '), hasLength(controller.all.length));
  });

  test('ignora acento, maiúscula e hífen', () {
    expect(controller.search('COSTELA DE ADAO').first.id, 'costela-de-adao');
    expect(controller.search('lirio').first.id, 'lirio-da-paz');
    expect(controller.search('espada-de-sao').first.id, 'espada-de-sao-jorge');
  });

  test('encontra por nome científico e apelido', () {
    expect(controller.search('monstera').first.id, 'costela-de-adao');
    expect(controller.search('aloe').first.id, 'babosa');
  });

  test('quem começa com o termo vem antes de quem só contém', () {
    final ids = controller.search('suc').map((s) => s.id).toList();
    expect(ids.first, 'echeveria'); // alias "suculenta"
  });

  test('sem resultado devolve lista vazia; byId aceita null', () {
    expect(controller.search('xyz123'), isEmpty);
    expect(controller.byId(null), isNull);
    expect(controller.byId('jiboia')?.name, 'Jiboia');
  });
}
