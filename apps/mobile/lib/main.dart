// main.dart
//
// Purpose:
// → App bootstrap: load .env, init Supabase & Workmanager, wrap dengan ProviderScope.
//   Navigation flow logic dipindah ke core/app_flow.dart.
//
// Used By:
// → Flutter entrypoint
//
// Depends On:
// → supabase_flutter, flutter_dotenv, hooks_riverpod, workmanager
//
// Impact:
// → Every screen in the app

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'core/app_flow.dart';
import 'core/env_config.dart';
import 'core/sensor_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/supabase_auth_repository.dart';
import 'features/auth/presentation/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load .env
  await EnvConfig.load();

  // 2. Init Supabase
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    publishableKey: EnvConfig.supabaseAnonKey,
  );

  // 3. Init Workmanager background callback & task
  await Workmanager().initialize(callbackDispatcher);

  await Workmanager().registerPeriodicTask(
    '1',
    kBackgroundSyncTaskName,
    frequency: const Duration(minutes: 15),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.connected),
  );

  // 4. Build AuthRepository after Supabase is ready
  final authRepository = SupabaseAuthRepository(
    supabase: Supabase.instance.client,
    serverClientId: EnvConfig.googleWebClientId,
  );

  runApp(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
      child: const GlicoApp(),
    ),
  );
}

class GlicoApp extends ConsumerWidget {
  const GlicoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Glicoo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppEntryPoint(),
    );
  }
}
