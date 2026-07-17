import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'models.dart';

typedef ActivitySnapshotReader = Future<Map<String, dynamic>> Function();

class CollectorApi {
  Future<void> start() async {}
  void stop() {}

  Future<Map<String, dynamic>> health() {
    throw UnimplementedError();
  }

  Future<SessionsResponse> sessions(String date) {
    throw UnimplementedError();
  }

  Future<List<Hackathon>> hackathons() {
    throw UnimplementedError();
  }
}

class NativeCollectorApi extends CollectorApi {
  NativeCollectorApi({
    ActivitySnapshotReader? snapshotReader,
    Directory? dataDirectory,
    this.pollInterval = const Duration(milliseconds: 2500),
    this.idleThreshold = const Duration(minutes: 1),
  }) : _snapshotReader = snapshotReader ?? _readWindowsSnapshot,
       _dataDirectoryOverride = dataDirectory;

  static const _activityChannel = MethodChannel('wdyd/native_activity');
  static const _maxSessions = 96;

  final ActivitySnapshotReader _snapshotReader;
  final Directory? _dataDirectoryOverride;
  final Duration pollInterval;
  final Duration idleThreshold;

  Timer? _timer;
  bool _started = false;
  bool _persistenceReady = false;
  String? _lastError;
  String _activeDateKey = _dateKey(DateTime.now());
  Map<String, dynamic>? _currentSession;
  List<Map<String, dynamic>> _closedSessions = [];

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _sessionsDirectory.create(recursive: true);
    await _loadActiveDate(_activeDateKey);
    _persistenceReady = true;
    await captureNow();
    _timer = Timer.periodic(pollInterval, (_) => unawaited(captureNow()));
  }

  Future<void> captureNow() async {
    try {
      final raw = await _snapshotReader();
      final capturedAt = DateTime.now();
      final snapshot = _normalizeSnapshot(raw, capturedAt);
      await _updateSessions(snapshot, capturedAt);
      await _persistActiveDate();
      _lastError = null;
    } catch (error) {
      _lastError = error.toString().replaceFirst('Exception: ', '');
    }
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<Map<String, dynamic>> health() async {
    await start();
    return {
      'ok': true,
      'service': 'what-do-you-do-native-collector',
      'activeDateKey': _activeDateKey,
      'persistenceReady': _persistenceReady,
      'storage': 'local-daily-json',
      'lastError': _lastError,
      'runtime': 'in-process-dart',
    };
  }

  @override
  Future<SessionsResponse> sessions(String date) async {
    await start();
    final stored = date == _activeDateKey
        ? _StoredSessions(_currentSession, _closedSessions)
        : await _readSessionsForDate(date);
    final allSessions = [
      if (stored.current != null) stored.current!,
      ...stored.closed,
    ];
    return SessionsResponse.fromJson({
      'activeDateKey': _activeDateKey,
      'availableDates': await _availableDates(),
      'date': date,
      'isLiveDate': date == _activeDateKey,
      'sessions': allSessions,
    });
  }

  @override
  Future<List<Hackathon>> hackathons() async {
    try {
      final decoded = jsonDecode(await _hackathonsFile.readAsString());
      return (decoded['hackathons'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Hackathon.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _updateSessions(
    Map<String, dynamic> snapshot,
    DateTime capturedAt,
  ) async {
    final dateKey = _dateKey(capturedAt);
    if (_activeDateKey != dateKey) {
      if (_currentSession != null) {
        _currentSession!['endTime'] = _time(capturedAt);
        _closedSessions = [
          _currentSession!,
          ..._closedSessions,
        ].take(_maxSessions).toList();
        await _persistDate(_activeDateKey, null, _closedSessions);
      }
      await _loadActiveDate(dateKey);
    }

    final fingerprint = [
      snapshot['appName'],
      snapshot['category'],
      snapshot['subcategory'],
    ].join(':');
    if (_currentSession == null ||
        _currentSession!['fingerprint'] != fingerprint) {
      if (_currentSession != null) {
        _currentSession!['endTime'] = _time(capturedAt);
        _closedSessions = [
          _currentSession!,
          ..._closedSessions,
        ].take(_maxSessions).toList();
      }
      _currentSession = {
        'id': 'live-${capturedAt.millisecondsSinceEpoch}',
        'dateKey': dateKey,
        'fingerprint': fingerprint,
        'startDateMs': capturedAt.millisecondsSinceEpoch,
        'startTime': _time(capturedAt),
        'endTime': _time(capturedAt),
        'appName': snapshot['appName'],
        'category': snapshot['category'],
        'subcategory': snapshot['subcategory'],
        'durationMinutes': 1,
        'confidence': snapshot['confidence'],
        'signalSources': snapshot['idle'] == true
            ? ['idle-detector']
            : ['active-app'],
        'rawContentStored': false,
      };
      return;
    }

    _currentSession!['endTime'] = _time(capturedAt);
    final startedAt =
        _currentSession!['startDateMs'] as int? ??
        capturedAt.millisecondsSinceEpoch;
    _currentSession!['durationMinutes'] =
        ((capturedAt.millisecondsSinceEpoch - startedAt) / 60000).round().clamp(
          1,
          1440,
        );
    _currentSession!['confidence'] = snapshot['confidence'];
  }

  Map<String, dynamic> _normalizeSnapshot(
    Map<String, dynamic> raw,
    DateTime capturedAt,
  ) {
    final processName = raw['processName']?.toString() ?? 'Unknown';
    final title = raw['foregroundWindowTitle']?.toString() ?? '';
    final idleMs = (raw['idleMs'] as num?)?.toInt() ?? 0;
    final idle = idleMs >= idleThreshold.inMilliseconds;
    final category = idle ? 'idle' : _classify(processName, title);
    return {
      'capturedAt': capturedAt.toUtc().toIso8601String(),
      'appName': idle ? 'Desktop' : _prettyAppName(processName),
      'category': category,
      'subcategory': _subcategory(category, processName, title, idle),
      'confidence': idle ? 96 : _confidence(category, title),
      'idle': idle,
    };
  }

  Future<void> _loadActiveDate(String dateKey) async {
    final stored = await _readSessionsForDate(dateKey);
    _activeDateKey = dateKey;
    _currentSession = stored.current;
    _closedSessions = stored.closed;
  }

  Future<_StoredSessions> _readSessionsForDate(String dateKey) async {
    try {
      final decoded =
          jsonDecode(
                await File(
                  '${_sessionsDirectory.path}\\$dateKey.json',
                ).readAsString(),
              )
              as Map<String, dynamic>;
      return _StoredSessions(
        decoded['currentSession'] as Map<String, dynamic>?,
        (decoded['sessions'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .take(_maxSessions)
            .toList(),
      );
    } catch (_) {
      return const _StoredSessions(null, []);
    }
  }

  Future<void> _persistActiveDate() async {
    if (!_persistenceReady) return;
    await _persistDate(_activeDateKey, _currentSession, _closedSessions);
  }

  Future<void> _persistDate(
    String dateKey,
    Map<String, dynamic>? current,
    List<Map<String, dynamic>> closed,
  ) async {
    await _sessionsDirectory.create(recursive: true);
    final payload = {
      'version': 3,
      'date': dateKey,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'currentSession': current,
      'sessions': closed.take(_maxSessions).toList(),
      'privacy': {
        'storesScreenshots': false,
        'storesKeystrokes': false,
        'storesPrivateMessages': false,
        'storesRawWindowTitles': false,
      },
    };
    await File(
      '${_sessionsDirectory.path}\\$dateKey.json',
    ).writeAsString('${const JsonEncoder.withIndent('  ').convert(payload)}\n');
  }

  Future<List<String>> _availableDates() async {
    if (!await _sessionsDirectory.exists()) return [_activeDateKey];
    final dates = await _sessionsDirectory
        .list()
        .where((entry) => entry is File && entry.path.endsWith('.json'))
        .map((entry) => entry.uri.pathSegments.last.replaceAll('.json', ''))
        .where((value) => RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value))
        .toList();
    if (!dates.contains(_activeDateKey)) dates.add(_activeDateKey);
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  Directory get _dataDirectory {
    if (_dataDirectoryOverride case final directory?) return directory;
    final base =
        Platform.environment['LOCALAPPDATA'] ??
        Platform.environment['APPDATA'] ??
        Directory.current.path;
    return Directory('$base\\What Do You Do\\data');
  }

  Directory get _sessionsDirectory =>
      Directory('${_dataDirectory.path}\\activity-sessions');
  File get _hackathonsFile => File('${_dataDirectory.path}\\hackathons.json');

  static Future<Map<String, dynamic>> _readWindowsSnapshot() async {
    final value = await _activityChannel.invokeMapMethod<String, dynamic>(
      'getActivitySnapshot',
    );
    if (value == null) throw StateError('Windows activity API is unavailable.');
    return value;
  }

  static String _classify(String processName, String title) {
    final text = '$processName $title'.toLowerCase();
    if (_matches(text, [
      'code',
      'codex',
      'cursor',
      'devenv',
      'pycharm',
      'webstorm',
      'intellij',
      'terminal',
      'powershell',
    ])) {
      return 'coding';
    }
    if (_matches(text, [
      'discord',
      'slack',
      'teams',
      'zoom',
      'whatsapp',
      'telegram',
    ])) {
      return 'communication';
    }
    if (_matches(text, [
      'steam',
      'epicgameslauncher',
      'riot',
      'minecraft',
      'roblox',
      'valorant',
      'leagueclient',
    ])) {
      return 'gaming';
    }
    if (_matches(text, [
      'youtube',
      'netflix',
      'prime video',
      'vlc',
      'spotify',
      'twitch',
    ])) {
      return 'watching';
    }
    return 'browsing';
  }

  static String _subcategory(
    String category,
    String processName,
    String title,
    bool idle,
  ) {
    final text = '$processName $title'.toLowerCase();
    if (idle) return 'Away from keyboard';
    if (category == 'coding' &&
        _matches(text, ['debug', 'error', 'terminal', 'powershell'])) {
      return 'Debugging or terminal work';
    }
    if (category == 'coding') return 'Building or editing code';
    if (category == 'communication' &&
        _matches(text, ['voice', 'call', 'meeting'])) {
      return 'Call or meeting activity';
    }
    if (category == 'communication') return 'Chat or community activity';
    if (category == 'gaming') return 'Game session activity';
    if (category == 'watching') return 'Watching or listening';
    if (_matches(text, ['docs', 'documentation', 'github', 'stackoverflow'])) {
      return 'Research or documentation';
    }
    return 'Browsing or app activity';
  }

  static String _prettyAppName(String processName) {
    const names = {
      'code': 'VS Code',
      'codex': 'Codex',
      'cursor': 'Cursor',
      'chrome': 'Chrome',
      'msedge': 'Edge',
      'firefox': 'Firefox',
      'discord': 'Discord',
      'powershell': 'PowerShell',
    };
    return names[processName.toLowerCase()] ?? processName;
  }

  static int _confidence(String category, String title) {
    if (category == 'coding' || category == 'communication') return 82;
    if (category == 'gaming') return 76;
    if (category == 'watching') return 74;
    return title.length > 4 ? 70 : 62;
  }

  static bool _matches(String text, List<String> values) =>
      values.any(text.contains);
  static String _dateKey(DateTime value) =>
      DateFormat('yyyy-MM-dd').format(value);
  static String _time(DateTime value) => DateFormat('HH:mm').format(value);
}

class _StoredSessions {
  const _StoredSessions(this.current, this.closed);

  final Map<String, dynamic>? current;
  final List<Map<String, dynamic>> closed;
}
