import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/species_controller.dart';
import '../../models/plant_species.dart';
import 'species_tile.dart';

/// Tela para escolher a espécie real da planta que está sendo cadastrada.
/// Devolve a [PlantSpecies] escolhida via `Navigator.pop`.
class SpeciesPickerView extends StatefulWidget {
  const SpeciesPickerView({super.key});

  @override
  State<SpeciesPickerView> createState() => _SpeciesPickerViewState();
}

class _SpeciesPickerViewState extends State<SpeciesPickerView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = context.watch<SpeciesController>().search(_query);

    return Scaffold(
      appBar: AppBar(title: const Text('Escolha a planta')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Pesquise pelo nome (ex: Jiboia)',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const Center(
                    child: Text('Nenhuma planta encontrada 🥲\nTente outro nome.',
                        textAlign: TextAlign.center),
                  )
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, i) => SpeciesTile(
                      species: results[i],
                      onTap: () => Navigator.of(context).pop<PlantSpecies>(results[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
