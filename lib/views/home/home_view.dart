import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/plant_controller.dart';
import '../../controllers/species_controller.dart';
import '../../models/diary_entry.dart';
import '../chat/chat_view.dart';
import '../plant/add_plant_view.dart';
import '../plant/plant_history_view.dart';
import 'widgets/home_header.dart';
import 'widgets/plant_card.dart';

/// Dashboard "Meus Vasos": header com busca + cards das plantas do usuário.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final plantsCtrl = context.watch<PlantController>();
    final species = context.watch<SpeciesController>();
    final plants = plantsCtrl.plants;
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: HomeHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      'Meus vasos',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    if (plants.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${plants.length}',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (plantsCtrl.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (plants.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverList.separated(
                  itemCount: plants.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final plant = plants[i];
                    return PlantCard(
                      plant: plant,
                      species: species.byId(plant.speciesId),
                      health: plantsCtrl.healthFor(
                        plant,
                        species: species.byId(plant.speciesId),
                      ),
                      status: plantsCtrl.statusFor(plant),
                      lastWatered:
                          plantsCtrl.lastAction(plant.id, DiaryAction.water),
                      onAction: (action) {
                        plantsCtrl.logAction(plant.id, action);
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(
                            content: Text(
                              '${action.emoji} ${plant.name}: ${action.label} registrado!',
                            ),
                          ));
                      },
                      onHistory: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PlantHistoryView(plant: plant),
                        ),
                      ),
                      onChat: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatView(plant: plant),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final added = await AddPlantView.open(context);
            if (added) {
              messenger.showSnackBar(
                const SnackBar(content: Text('🌱 Planta cadastrada!')),
              );
            }
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nova planta'),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌱', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(
            'Seu jardim está vazio',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Pesquise uma planta lá em cima, veja os cuidados e adicione aos seus vasos.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
