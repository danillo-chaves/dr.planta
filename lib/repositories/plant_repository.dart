import '../models/plant.dart';

/// Contrato de acesso às plantas. Hoje em memória; depois local/Firestore.
abstract class PlantRepository {
  Future<List<Plant>> getAll();
  Future<void> save(Plant plant);
  Future<void> delete(String plantId);
}
