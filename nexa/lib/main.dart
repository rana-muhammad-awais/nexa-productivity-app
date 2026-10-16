import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tzl;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'app.dart';
import 'services/notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone database for scheduled notifications
  tz.initializeTimeZones();
  try {
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tzl.setLocalLocation(tzl.getLocation(timeZoneName));
  } catch (_) {
    // Fallback — use UTC if timezone detection fails
    tzl.setLocalLocation(tzl.getLocation('UTC'));
  }

  // Initialize notification service
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();

  runApp(const ProviderScope(child: NexoraApp()));
}
