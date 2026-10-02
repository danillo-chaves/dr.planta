import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'controllers/plant_controller.dart';
import 'controllers/species_controller.dart';
import 'core/theme/app_theme.dart';
import 'repositories/chat_repository.dart';
import 'repositories/diary_repository.dart';
import 'repositories/memory/fake_chat_repository.dart';
import 'repositories/memory/in_memory_diary_repository.dart';
import 'repositories/memory/in_memory_plant_repository.dart';
import 'repositories/memory/local_species_repository.dart';
import 'repositories/plant_repository.dart';
import 'repositories/species_repository.dart';
import 'views/home/home_view.dart';

/// Raiz do app: registra repositórios e controllers globais.
/// Trocar uma implementação (ex: Firestore) é só mudar aqui.
class DrFolhaVidaApp extends StatelessWidget {
  const DrFolhaVidaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PlantRepository>(create: (_) => InMemoryPlantRepository()),
        Provider<DiaryRepository>(create: (_) => InMemoryDiaryRepository()),
        Provider<ChatRepository>(create: (_) => FakeChatRepository()),
        Provider<SpeciesRepository>(create: (_) => LocalSpeciesRepository()),
        ChangeNotifierProvider<SpeciesController>(
          create: (context) => SpeciesController(
            repository: context.read<SpeciesRepository>(),
          )..load(),
        ),
        ChangeNotifierProvider<PlantController>(
          create: (context) => PlantController(
            plantRepository: context.read<PlantRepository>(),
            diaryRepository: context.read<DiaryRepository>(),
          )..load(),
        ),
      ],
      child: MaterialApp(
        title: 'Dr. FolhaVida',
        debugShowCheckedModeBanner: false,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const HomeView(),
      ),
    );
  }
}
