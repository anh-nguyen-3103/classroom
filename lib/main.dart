import 'dart:async';

import 'package:classroom/app.dart';
import 'package:classroom/core/configs/load_env.dart';
import 'package:classroom/core/services/analytics_service.dart';
import 'package:classroom/core/services/haptic_service.dart';
import 'package:classroom/core/services/log_service.dart';
import 'package:classroom/core/services/notification_service.dart';
import 'package:classroom/core/services/storage_service.dart';
import 'package:classroom/core/utils/helpers/platform.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';

final _log = LogService();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  _log.info('Handling a background message: ${message.messageId}');
}

Future<void> _initialize() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _log.error(
      'Flutter error caught: ${details.exception}',
      details.exception,
      details.stack,
    );
  };

  WidgetsFlutterBinding.ensureInitialized();

  try {
    await loadEnv();

    await StorageService.init();
    await HapticService.light();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService().init();
    await AnalyticsService().init();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    if (isWeb) {
      runApp(
        DevicePreview(
          enabled: !kReleaseMode,
          builder: (context) => ProviderScope(child: App()),
        ),
      );
    } else {
      runApp(const ProviderScope(child: App()));
    }
  } catch (error, trace) {
    _log.error('Initialization error: $error', error, trace);
    runApp(Placeholder());
  }
}

Future<void> main() async {
  runZonedGuarded(_initialize, (error, trace) {
    _log.error('Initialization error: $error', error, trace);
    runApp(Placeholder());
  });
}
