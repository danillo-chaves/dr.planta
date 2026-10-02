import '../models/plant_species.dart';

/// Contrato do catálogo de espécies. Local/offline: não consome a API de IA.
abstract class SpeciesRepository {
  Future<List<PlantSpecies>> getAll();
}
