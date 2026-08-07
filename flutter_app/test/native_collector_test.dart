import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:what_do_you_do/src/collector_api.dart';

void main() {
  test(
    'native collector captures and persists activity without HTTP',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'wdyd-native-collector-',
      );
      addTearDown(() => temp.delete(recursive: true));
      var snapshot = {
        'processName': 'Code',
        'foregroundWindowTitle': 'project - Visual Studio Code',
        'idleMs': 0,
      };
      final collector = NativeCollectorApi(
        dataDirectory: temp,
        pollInterval: const Duration(days: 1),
        snapshotReader: () async => snapshot,
      );
      addTearDown(collector.stop);

      await collector.start();
      var response = await collector.sessions(
        DateTime.now().toIso8601String().substring(0, 10),
      );
      expect(response.sessions.single.appName, 'VS Code');
      expect(response.sessions.single.category.name, 'coding');

      snapshot = {
        'processName': 'Discord',
        'foregroundWindowTitle': 'Friends',
        'idleMs': 0,
      };
      await collector.captureNow();
      response = await collector.sessions(
        DateTime.now().toIso8601String().substring(0, 10),
      );
      expect(response.sessions.first.appName, 'Discord');
      expect(response.sessions.last.category.name, 'coding');
      expect(
        await File(
          '${temp.path}\\activity-sessions\\${response.date}.json',
        ).exists(),
        isTrue,
      );
    },
  );

  test('native collector marks one minute of idle time as away', () async {
    final temp = await Directory.systemTemp.createTemp('wdyd-native-idle-');
    addTearDown(() => temp.delete(recursive: true));
    final collector = NativeCollectorApi(
      dataDirectory: temp,
      pollInterval: const Duration(days: 1),
      snapshotReader: () async => {
        'processName': 'chrome',
        'foregroundWindowTitle': 'Private page title',
        'idleMs': 61000,
      },
    );
    addTearDown(collector.stop);

    await collector.start();
    final response = await collector.sessions(
      DateTime.now().toIso8601String().substring(0, 10),
    );

    expect(response.sessions.single.appName, 'Desktop');
    expect(response.sessions.single.category.name, 'idle');
    expect(response.sessions.single.subcategory, 'Away from keyboard');
  });

  test('native collector quarantines corrupt daily storage and recovers', () async {
    final temp = await Directory.systemTemp.createTemp('wdyd-native-recovery-');
    addTearDown(() => temp.delete(recursive: true));
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final sessionsDirectory = Directory('${temp.path}\\activity-sessions');
    await sessionsDirectory.create(recursive: true);
    final target = File('${sessionsDirectory.path}\\$date.json');
    await target.writeAsString('{"version":2,"sessions":"broken"}');
    final collector = NativeCollectorApi(
      dataDirectory: temp,
      pollInterval: const Duration(days: 1),
      snapshotReader: () async => {
        'processName': 'Code',
        'foregroundWindowTitle': 'Recovery test',
        'idleMs': 0,
      },
    );
    addTearDown(collector.stop);

    await collector.start();
    final response = await collector.sessions(date);
    final quarantined = await sessionsDirectory
        .list()
        .where((entry) => entry.path.contains('.corrupt-'))
        .toList();

    expect(response.sessions, isNotEmpty);
    expect(await target.exists(), isTrue);
    expect(quarantined, hasLength(1));
  });
}
