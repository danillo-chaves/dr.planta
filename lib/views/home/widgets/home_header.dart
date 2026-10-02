import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/species_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../species/species_detail_view.dart';
import '../../species/species_tile.dart';

/// Cabeçalho da Home: marca + barra de pesquisa de espécies.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('🌿', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. FolhaVida',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Seu jardim, sempre saudável',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Qual planta você\nquer conhecer?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              const _SpeciesSearchBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeciesSearchBar extends StatelessWidget {
  const _SpeciesSearchBar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SearchAnchor.bar(
      barHintText: 'Pesquise uma planta (ex: Jiboia)',
      viewHintText: 'Nome da planta',
      barBackgroundColor: WidgetStatePropertyAll(scheme.surface),
      barElevation: const WidgetStatePropertyAll(6),
      barLeading: Icon(Icons.search_rounded, color: scheme.primary),
      suggestionsBuilder: (context, controller) {
        final results =
            context.read<SpeciesController>().search(controller.text);

        if (results.isEmpty) {
          return [
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('Nenhuma planta encontrada 🥲\nTente outro nome.',
                    textAlign: TextAlign.center),
              ),
            ),
          ];
        }

        return [
          for (final species in results)
            SpeciesTile(
              species: species,
              onTap: () {
                controller.closeView('');
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SpeciesDetailView(species: species),
                  ),
                );
              },
            ),
        ];
      },
    );
  }
}
