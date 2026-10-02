import 'package:flutter/material.dart';

import '../../models/plant_species.dart';

/// Linha de espécie usada na busca da Home e no seletor do cadastro.
class SpeciesTile extends StatelessWidget {
  const SpeciesTile({super.key, required this.species, required this.onTap});

  final PlantSpecies species;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        child: Text(species.emoji, style: const TextStyle(fontSize: 20)),
      ),
      title: Text(species.name),
      subtitle: Text(
        species.scientificName,
        style: const TextStyle(fontStyle: FontStyle.italic),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
