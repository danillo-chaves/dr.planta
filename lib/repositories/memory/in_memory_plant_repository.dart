import '../../models/plant.dart';
import '../plant_repository.dart';

class InMemoryPlantRepository implements PlantRepository {
  final Map<String, Plant> _plants = {};

  @override
  Future<List<Plant>> getAll() async => _plants.values.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<void> save(Plant plant) async => _plants[plant.id] = plant;

  @override
  Future<void> delete(String plantId) async => _plants.remove(plantId);
}
