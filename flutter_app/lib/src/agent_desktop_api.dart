import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'models.dart';

class AgentDesktopApi {
  AgentDesktopApi({
    http.Client? client,
    List<String>? candidateBaseUrls,
    File? runtimeDescriptorFile,
    File? snapshotCacheFile,
    this.discoveryTimeout = const Duration(milliseconds: 700),
    this.requestTimeout = const Duration(seconds: 3),
  }) : _client = client ?? http.Client(),
       _candidateBaseUrlOverride = candidateBaseUrls,
       _runtimeDescriptorFile =
           runtimeDescriptorFile ?? _defaultRuntimeDescriptorFile(),
       _snapshotCacheFile = snapshotCacheFile ?? _defaultSnapshotCacheFile(),
       _useRuntimeDescriptor =
           candidateBaseUrls == null || runtimeDescriptorFile != null,
       _useSnapshotCache =
           candidateBaseUrls == null || snapshotCacheFile != null;

  final http.Client _client;
  final List<String>? _candidateBaseUrlOverride;
  final File _runtimeDescriptorFile;
  final File _snapshotCacheFile;
  final bool _useRuntimeDescriptor;
  final bool _useSnapshotCache;
  final Duration discoveryTimeout;
  final Duration requestTimeout;

  _Pairing? _pairing;
  AgentDesktopSnapshot? _lastGoodSnapshot;

  Future<AgentDesktopSnapshot?> cachedSnapshot() async {
    final cached = _lastGoodSnapshot ?? await _loadCachedSnapshot();
    if (cached == null) return null;
    _lastGoodSnapshot = cached;
    return cached.asStale('Checking the live local service now.');
  }

  Future<AgentDesktopSnapshot> snapshot({bool forceDiscovery = false}) async {
    Object? lastError;
    _Pairing? attemptedPairing;
    try {
      attemptedPairing = await _discoverPairing(forceProbe: forceDiscovery);
      return await _loadLiveSnapshot(attemptedPairing);
    } catch (error) {
      lastError = error;
      _pairing = null;
    }

    if (attemptedPairing != null && !forceDiscovery) {
      try {
        final recovered = await _discoverPairing(forceProbe: true);
        if (recovered != attemptedPairing) {
          return await _loadLiveSnapshot(recovered);
        }
      } catch (error) {
        lastError = error;
        _pairing = null;
      }
    }

    final cached = _lastGoodSnapshot ?? await _loadCachedSnapshot();
    if (cached != null) {
      _lastGoodSnapshot = cached;
      return cached.asStale(_friendly(lastError));
    }

    throw Exception(_friendly(lastError));
  }

  Future<void> answerPlanningQuestion({
    required int eventId,
    required PlanningProgressUpdate update,
  }) async {
    await _pairedRequest(
      'PATCH',
      '/api/planning-events/$eventId',
      body: update.toJson(),
    );
  }

  Future<void> createPlanningEvent(PlanningEventDraft draft) async {
    await _pairedRequest('POST', '/api/planning-events', body: draft.toJson());
  }

  Future<IntelligenceSyncResult> syncIntelligence() async {
    final result = await _pairedRequest('POST', '/api/intelligence/sync');
    return IntelligenceSyncResult.fromJson(result);
  }

  Future<bool> launchDesktop() async {
    for (final executable in _desktopExecutables()) {
      if (!await executable.exists()) continue;
      await Process.start(
        executable.path,
        const [],
        mode: ProcessStartMode.detached,
      );
      _pairing = null;
      return true;
    }
    return false;
  }

  void close() => _client.close();

  Future<AgentDesktopSnapshot> _loadLiveSnapshot(_Pairing pairing) async {
    final envelope = await _fetchEnvelope(pairing);
    final snapshot = _snapshotFromEnvelope(pairing.baseUrl, envelope);
    _pairing = pairing;
    _lastGoodSnapshot = snapshot;
    await _persistEnvelope(envelope);
    return snapshot;
  }

  Future<Map<String, dynamic>> _fetchEnvelope(_Pairing pairing) async {
    try {
      final consolidated = await _requestOrNull(
        pairing,
        'GET',
        pairing.snapshotPath,
        allowNotFound: true,
      );
      if (consolidated != null &&
          consolidated['service'] == 'aios-assistant' &&
          consolidated['schema_version'] == 1) {
        return consolidated;
      }
    } on _AgentHttpException catch (error) {
      if (error.statusCode == 401) rethrow;
      // Older or mid-restart cores can still serve the compatibility feeds.
    }

    final live = await _request(pairing, 'GET', '/api/live');
    final optional = await Future.wait([
      _getOptional(pairing, '/api/desktop/status'),
      _getOptional(pairing, '/api/workers'),
      _getOptional(pairing, '/api/hackathons'),
      _getOptional(pairing, '/api/placements'),
      _getOptional(pairing, '/api/applications'),
      _getOptional(pairing, '/api/neopat'),
      _getOptional(pairing, '/api/projects/context'),
      _getOptional(pairing, '/api/college/pat'),
    ]);
    return {
      'ok': true,
      'service': 'aios-assistant',
      'schema_version': 0,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'live': live,
      'desktop': optional[0].data,
      'workers': optional[1].data,
      'hackathons': optional[2].data,
      'placements': optional[3].data,
      'applications': optional[4].data,
      'neopat': optional[5].data,
      'projects': optional[6].data,
      'college': optional[7].data,
      'unavailable_feeds': optional
          .where((result) => result.error != null)
          .map((result) => result.path)
          .toList(),
    };
  }

  AgentDesktopSnapshot _snapshotFromEnvelope(
    String baseUrl,
    Map<String, dynamic> envelope,
  ) {
    List<String> unavailableFeeds() =>
        (envelope['unavailable_feeds'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList();

    return AgentDesktopSnapshot.fromJson(
      baseUrl: baseUrl,
      live: _map(envelope['live']),
      desktop: _map(envelope['desktop']),
      workers: _map(envelope['workers']),
      hackathons: _map(envelope['hackathons']),
      placements: _map(envelope['placements']),
      applications: _map(envelope['applications']),
      neopat: _map(envelope['neopat']),
      projects: _map(envelope['projects']),
      college: _map(envelope['college']),
      unavailableFeeds: unavailableFeeds(),
    );
  }

  Future<_Pairing> _discoverPairing({bool forceProbe = false}) async {
    if (!forceProbe) {
      final pairing = _pairing;
      if (pairing != null) return pairing;
    }

    if (!forceProbe && _useRuntimeDescriptor) {
      final local = await _pairingFromRuntimeDescriptor();
      if (local != null) {
        _pairing = local;
        return local;
      }
    }

    final candidates = _candidateBaseUrls().toSet().toList();
    final results = await Future.wait(candidates.map(_probePairing));
    for (final pairing in results) {
      if (pairing == null) continue;
      _pairing = pairing;
      return pairing;
    }
    throw Exception('AiOS Desktop is not running.');
  }

  Future<_Pairing?> _pairingFromRuntimeDescriptor() async {
    try {
      if (!await _runtimeDescriptorFile.exists()) return null;
      final decoded = jsonDecode(await _runtimeDescriptorFile.readAsString());
      if (decoded is! Map<String, dynamic> ||
          decoded['service'] != 'aios-assistant') {
        return null;
      }
      return _pairingFromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<_Pairing?> _probePairing(String baseUrl) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/local/pairing'))
          .timeout(discoveryTimeout);
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> ||
          decoded['service'] != 'aios-assistant' ||
          decoded['ok'] != true) {
        return null;
      }
      return _pairingFromJson(decoded, fallbackBaseUrl: baseUrl);
    } catch (_) {
      return null;
    }
  }

  _Pairing? _pairingFromJson(
    Map<String, dynamic> data, {
    String fallbackBaseUrl = '',
  }) {
    final token = data['api_token']?.toString() ?? '';
    if (token.isEmpty) return null;
    final baseUrl = _normalizeLoopbackBaseUrl(
      data['base_url']?.toString() ?? fallbackBaseUrl,
    );
    final rawPath = data['snapshot_path']?.toString() ?? '/api/wdyd/snapshot';
    final snapshotPath = rawPath.startsWith('/') ? rawPath : '/$rawPath';
    return _Pairing(baseUrl: baseUrl, token: token, snapshotPath: snapshotPath);
  }

  Future<Map<String, dynamic>> _pairedRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final pairing = await _discoverPairing();
    try {
      return await _request(pairing, method, path, body: body);
    } on _AgentHttpException catch (error) {
      if (error.statusCode != 401) rethrow;
      _pairing = null;
      final recovered = await _discoverPairing(forceProbe: true);
      return _request(recovered, method, path, body: body);
    }
  }

  Future<_EndpointResult> _getOptional(_Pairing pairing, String path) async {
    try {
      return _EndpointResult(
        path: path,
        data: await _request(
          pairing,
          'GET',
          path,
          timeout: const Duration(seconds: 2),
        ),
      );
    } catch (error) {
      return _EndpointResult(path: path, data: const {}, error: error);
    }
  }

  Future<Map<String, dynamic>> _request(
    _Pairing pairing,
    String method,
    String path, {
    Map<String, dynamic>? body,
    Duration? timeout,
  }) async {
    final result = await _requestOrNull(
      pairing,
      method,
      path,
      body: body,
      timeout: timeout,
    );
    if (result == null) {
      throw _AgentHttpException(404, path, 'AiOS endpoint was not found.');
    }
    return result;
  }

  Future<Map<String, dynamic>?> _requestOrNull(
    _Pairing pairing,
    String method,
    String path, {
    Map<String, dynamic>? body,
    Duration? timeout,
    bool allowNotFound = false,
  }) async {
    final uri = Uri.parse('${pairing.baseUrl}$path');
    final headers = {
      'X-AiOS-Token': pairing.token,
      if (body != null) 'Content-Type': 'application/json',
    };
    final response = await switch (method) {
      'PATCH' => _client.patch(uri, headers: headers, body: jsonEncode(body)),
      'POST' => _client.post(uri, headers: headers, body: jsonEncode(body)),
      _ => _client.get(uri, headers: headers),
    }.timeout(timeout ?? requestTimeout);

    if (allowNotFound && response.statusCode == 404) return null;
    if (response.statusCode == 401) {
      throw _AgentHttpException(401, path, 'AiOS Desktop is locked.');
    }
    if (response.statusCode != 200) {
      throw _AgentHttpException(
        response.statusCode,
        path,
        'AiOS Desktop responded with ${response.statusCode}.',
      );
    }

    final responseBody = response.body.trimLeft();
    if (responseBody.startsWith('<')) {
      throw _AgentHttpException(
        response.statusCode,
        path,
        'AiOS $path returned a web page instead of local API data.',
      );
    }

    late final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw _AgentHttpException(
        response.statusCode,
        path,
        'AiOS $path returned invalid local API data.',
      );
    }
    if (decoded is List<dynamic>) return {'items': decoded};
    if (decoded is! Map<String, dynamic>) {
      throw _AgentHttpException(
        response.statusCode,
        path,
        'AiOS $path returned an unexpected response.',
      );
    }
    return decoded;
  }

  Future<void> _persistEnvelope(Map<String, dynamic> envelope) async {
    if (!_useSnapshotCache) return;
    try {
      await _snapshotCacheFile.parent.create(recursive: true);
      await _snapshotCacheFile.writeAsString(
        jsonEncode({
          'cached_at': DateTime.now().toUtc().toIso8601String(),
          'base_url': _pairing?.baseUrl ?? '',
          'snapshot': envelope,
        }),
        flush: true,
      );
    } catch (_) {
      // A cache failure must never break the live local connection.
    }
  }

  Future<AgentDesktopSnapshot?> _loadCachedSnapshot() async {
    if (!_useSnapshotCache) return null;
    try {
      if (!await _snapshotCacheFile.exists()) return null;
      final decoded = jsonDecode(await _snapshotCacheFile.readAsString());
      if (decoded is! Map<String, dynamic>) return null;
      final baseUrl = _normalizeLoopbackBaseUrl(
        decoded['base_url']?.toString() ?? '',
      );
      final envelope = _map(decoded['snapshot']);
      if (envelope['service'] != 'aios-assistant') return null;
      return _snapshotFromEnvelope(baseUrl, envelope);
    } catch (_) {
      return null;
    }
  }

  List<String> _candidateBaseUrls() {
    if (_candidateBaseUrlOverride case final values?) return values;
    return [
      'http://127.0.0.1:5050',
      'http://127.0.0.1:5000',
      for (var port = 5051; port <= 5069; port++) 'http://127.0.0.1:$port',
    ];
  }

  List<File> _desktopExecutables() {
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
    if (localAppData.isEmpty) return const [];
    return [
      File('$localAppData\\Programs\\AiOS Assistant\\aios_assistant.exe'),
      File('$localAppData\\Programs\\AiOS Assistant\\AiOS-Assistant.exe'),
    ];
  }

  String _normalizeLoopbackBaseUrl(String value) {
    final uri = Uri.parse(value);
    final isLoopback =
        uri.host == '127.0.0.1' || uri.host == 'localhost' || uri.host == '::1';
    if (!isLoopback || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw Exception('AiOS Desktop must stay on loopback.');
    }
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).toString().replaceAll(RegExp(r'/+$'), '');
  }

  String _friendly(Object? error) {
    if (error == null) return 'AiOS Desktop is unavailable.';
    return error.toString().replaceFirst(RegExp(r'^Exception: '), '');
  }

  static File _defaultRuntimeDescriptorFile() {
    final root = Platform.environment['LOCALAPPDATA'] ?? Directory.current.path;
    return File('$root\\AiOS Assistant\\runtime.json');
  }

  static File _defaultSnapshotCacheFile() {
    final root = Platform.environment['LOCALAPPDATA'] ?? Directory.current.path;
    return File('$root\\What Do You Do\\aios-snapshot-cache.json');
  }
}

class _Pairing {
  const _Pairing({
    required this.baseUrl,
    required this.token,
    required this.snapshotPath,
  });

  final String baseUrl;
  final String token;
  final String snapshotPath;

  @override
  bool operator ==(Object other) =>
      other is _Pairing &&
      other.baseUrl == baseUrl &&
      other.token == token &&
      other.snapshotPath == snapshotPath;

  @override
  int get hashCode => Object.hash(baseUrl, token, snapshotPath);
}

class _EndpointResult {
  const _EndpointResult({required this.path, required this.data, this.error});

  final String path;
  final Map<String, dynamic> data;
  final Object? error;
}

class _AgentHttpException implements Exception {
  const _AgentHttpException(this.statusCode, this.path, this.message);

  final int statusCode;
  final String path;
  final String message;

  @override
  String toString() => message;
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}
