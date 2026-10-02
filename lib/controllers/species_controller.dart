import 'package:flutter/foundation.dart';

import '../models/plant_species.dart';
import '../repositories/species_repository.dart';

/// Controller do catálogo: carrega as fichas e faz a busca (sem acento, sem
/// diferenciar maiúsculas) por nome, nome científico e apelidos.
class SpeciesController extends ChangeNotifier {
  SpeciesController({required SpeciesRepository repository})
      : _repository = repository;

  final SpeciesRepository _repository;

  List<PlantSpecies> _all = [];
  bool _loading = false;

  List<PlantSpecies> get all => List.unmodifiable(_all);
  bool get isLoading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _all = await _repository.getAll();
    _loading = false;
    notifyListeners();
  }

  PlantSpecies? byId(String? id) {
    if (id == null) return null;
    for (final s in _all) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Sem [query], devolve o catálogo inteiro. Quem começa com o termo vem antes.
  List<PlantSpecies> search(String query) {
    final q = normalize(query);
    if (q.isEmpty) return all;

    final starts = <PlantSpecies>[];
    final contains = <PlantSpecies>[];
    for (final s in _all) {
      final names = [s.name, s.scientificName, ...s.aliases].map(normalize);
      if (names.any((n) => n.startsWith(q))) {
        starts.add(s);
      } else if (names.any((n) => n.contains(q))) {
        contains.add(s);
      }
    }
    return [...starts, ...contains];
  }

  static const _accents = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', '-': ' ',
  };

  @visibleForTesting
  static String normalize(String text) {
    final lower = text.toLowerCase().trim();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(_accents[ch] ?? ch);
    }
    return buffer.toString();
  }
}
