import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/presentation/app_config/app_config_controller.dart';
import 'package:snip_fair/core/services/notification_service.dart';
import 'package:snip_fair/core/version_checker.dart';
import 'package:snip_fair/features/onboarding/force_update_screen.dart';
import 'package:snip_fair/firebase_options.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    log('onChange(${bloc.runtimeType}, $change)');
    super.onChange(bloc, change);
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error)');
    super.onError(bloc, error, stackTrace);
  }
}

void _bootstrapLog(String message) {
  print(message);
  log(message);
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  _bootstrapLog('🚀 BOOTSTRAP STARTED');

  await configureDependencies();

  // ---------------------------
  // 🔥 FIREBASE INIT
  // ---------------------------
  _bootstrapLog('📱 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  _bootstrapLog('✅ Firebase Initialized');

  // ---------------------------
  // 🔍 REMOTE CONFIG / VERSION CHECK
  // ---------------------------
  _bootstrapLog('🔍 Running Version Check...');

  final updateRequired = await VersionChecker.isUpdateRequired();

  _bootstrapLog('📊 Version Check Result: $updateRequired');

  if (updateRequired) {
    _bootstrapLog('⚠️ FORCE UPDATE REQUIRED');

    runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ForceUpdateScreen(updateUrl: ''),
      ),
    );
    return;
  }

  // ---------------------------
  // REMOTE APP CONFIG / KILL SWITCH
  // ---------------------------
  _bootstrapLog('Running App Config Check...');
  await getIt<AppConfigController>().refresh();

  // ---------------------------
  // 🔔 NOTIFICATIONS
  // ---------------------------
  await NotificationService.instance.init();

  // ---------------------------
  // 📱 ORIENTATION LOCK
  // ---------------------------
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ---------------------------
  // 🚀 RUN APP
  // ---------------------------
  runApp(await builder());
}
