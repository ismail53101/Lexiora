import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/navigation/home_destination.dart';
import 'package:lexiora/modules/ai_assistant/config/ai_config.dart';
import 'package:lexiora/modules/ai_assistant/data/datasources/ai_local_data_source.dart';
import 'package:lexiora/modules/ai_assistant/data/repositories/ai_repository_impl.dart';
import 'package:lexiora/modules/ai_assistant/data/services/ai_api_client.dart';
import 'package:lexiora/modules/ai_assistant/data/services/openai_compatible_chat_service.dart';
import 'package:lexiora/modules/ai_assistant/domain/repositories/ai_repository.dart';
import 'package:lexiora/modules/ai_assistant/domain/services/ai_chat_service.dart';
import 'package:lexiora/modules/ai_assistant/presentation/pages/ai_chat_page.dart';

/// Phase v0.10.0 — the AI Assistant.
///
/// A fully independent [FeatureModule]: it wires its own config, transport,
/// chat service, data source and repository into DI, contributes the `/ai`
/// route, and replaces the old "Coming Soon" tile with a live Home entry. The
/// provider is OpenAI-compatible and abstracted behind [AiChatService], so
/// swapping providers (or adding vision/voice/reasoning later) never touches the
/// UI. The API key comes from a compile-time env define and is never stored or
/// logged. Chat history is offline-first (two additive Drift tables).
class AiAssistantModule extends FeatureModule {
  @override
  String get id => 'ai_assistant';

  @override
  String get name => 'AI Assistant';

  @override
  void registerDependencies(GetIt getIt) {
    getIt
      ..registerLazySingleton<AiConfig>(AiConfig.fromEnvironment)
      ..registerLazySingleton<AiApiClient>(
        () => AiApiClient(getIt<AiConfig>()),
      )
      ..registerLazySingleton<AiChatService>(
        () => OpenAiCompatibleChatService(
            getIt<AiApiClient>(), getIt<AiConfig>()),
      )
      ..registerLazySingleton<AiLocalDataSource>(
        () => AiLocalDataSource(getIt<AppDatabase>()),
      )
      ..registerLazySingleton<AiRepository>(
        () => AiRepositoryImpl(
          getIt<AiLocalDataSource>(),
          getIt<AiChatService>(),
          getIt<AiConfig>(),
        ),
      );
  }

  @override
  List<RouteBase> routes(GetIt getIt) => <RouteBase>[
        GoRoute(
          path: AppRoutes.aiAssistant,
          builder: (_, _) => const AiChatPage(),
        ),
      ];

  @override
  List<HomeDestination> homeDestinations(GetIt getIt) => const <HomeDestination>[
        HomeDestination(
          id: 'ai_assistant',
          label: 'AI Assistant',
          subtitle: 'Chat, ask & learn',
          icon: Icons.smart_toy_outlined,
          imageAsset: 'assets/branding/ai_assistant_nav.png',
          routePath: AppRoutes.aiAssistant,
          order: 16,
        ),
      ];
}
