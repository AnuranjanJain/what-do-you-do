import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class AgentDesktopApi {
  AgentDesktopApi({http.Client? client, List<String>? candidateBaseUrls})
    : _client = client ?? http.Client(),
      _candidateBaseUrlOverride = candidateBaseUrls;

  final http.Client _client;
  final List<String>? _candidateBaseUrlOverride;

  Future<AgentDesktopSnapshot> snapshot() async {
    final pairing = await _discoverPairing();
    final live = await _get(pairing, '/api/live');
    final optional = await Future.wait([
      _getOptional(pairing, '/api/desktop/status'),
      _getOptional(pairing, '/api/workers'),
      _getOptional(pairing, '/api/hackathons'),
      _getOptional(pairing, '/api/placements'),
      _getOptional(pairing, '/api/neopat'),
      _getOptional(pairing, '/api/projects/context'),
      _getOptional(pairing, '/api/college/pat'),
    ]);
    final unavailableFeeds = optional
        .where((result) => result.error != null)
        .map((result) => result.path)
        .toList();

    return AgentDesktopSnapshot.fromJson(
      baseUrl: pairing.baseUrl,
      live: live,
      desktop: optional[0].data,
      workers: optional[1].data,
      hackathons: optional[2].data,
      placements: optional[3].data,
      neopat: optional[4].data,
      projects: optional[5].data,
      college: optional[6].data,
      unavailableFeeds: unavailableFeeds,
    );
  }

  Future<void> answerPlanningQuestion({
    required int eventId,
    required PlanningProgressUpdate update,
  }) async {
    final pairing = await _discoverPairing();
    await _request(
      pairing,
      'PATCH',
      '/api/planning-events/$eventId',
      body: update.toJson(),
    );
  }

  Future<void> createPlanningEvent(PlanningEventDraft draft) async {
    final pairing = await _discoverPairing();
    await _request(
      pairing,
      'POST',
      '/api/planning-events',
      body: draft.toJson(),
    );
  }

  Future<IntelligenceSyncResult> syncIntelligence() async {
    final pairing = await _discoverPairing();
    final result = await _request(pairing, 'POST', '/api/intelligence/sync');
    return IntelligenceSyncResult.fromJson(result);
  }

  Future<_Pairing> _discoverPairing() async {
    for (final baseUrl in _candidateBaseUrls()) {
      try {
        final response = await _client
            .get(Uri.parse('$baseUrl/api/local/pairing'))
            .timeout(const Duration(milliseconds: 850));
        if (response.statusCode != 200) continue;

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['service'] != 'aios-assistant' || body['ok'] != true) {
          continue;
        }

        final pairedBaseUrl = _normalizeLoopbackBaseUrl(
          body['base_url']?.toString() ?? baseUrl,
        );
        final token = body['api_token']?.toString() ?? '';
        if (token.isEmpty) continue;

        return _Pairing(baseUrl: pairedBaseUrl, token: token);
      } catch (_) {
        // Try the next local desktop port.
      }
    }

    throw Exception('AiOS Desktop is not running.');
  }

  Future<Map<String, dynamic>> _get(_Pairing pairing, String path) async {
    return _request(pairing, 'GET', path);
  }

  Future<_EndpointResult> _getOptional(_Pairing pairing, String path) async {
    try {
      return _EndpointResult(path: path, data: await _get(pairing, path));
    } catch (error) {
      return _EndpointResult(path: path, data: const {}, error: error);
    }
  }

  Future<Map<String, dynamic>> _request(
    _Pairing pairing,
    String method,
    String path, {
    Map<String, dynamic>? body,
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
    }.timeout(const Duration(seconds: 4));

    if (response.statusCode == 401) {
      throw Exception('AiOS Desktop is locked.');
    }
    if (response.statusCode != 200) {
      throw Exception('AiOS Desktop responded with ${response.statusCode}.');
    }

    final responseBody = response.body.trimLeft();
    if (responseBody.startsWith('<')) {
      throw Exception(
        'AiOS $path returned a web page instead of local API data.',
      );
    }

    late final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw Exception('AiOS $path returned invalid local API data.');
    }
    if (decoded is List<dynamic>) return {'items': decoded};
    if (decoded is! Map<String, dynamic>) {
      throw Exception('AiOS $path returned an unexpected response.');
    }
    return decoded;
  }

  List<String> _candidateBaseUrls() {
    if (_candidateBaseUrlOverride case final values?) {
      return values;
    }
    return [
      'http://127.0.0.1:5050',
      'http://127.0.0.1:5000',
      for (var port = 5051; port <= 5069; port++) 'http://127.0.0.1:$port',
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
}

class _Pairing {
  const _Pairing({required this.baseUrl, required this.token});

  final String baseUrl;
  final String token;
}

class _EndpointResult {
  const _EndpointResult({required this.path, required this.data, this.error});

  final String path;
  final Map<String, dynamic> data;
  final Object? error;
}
