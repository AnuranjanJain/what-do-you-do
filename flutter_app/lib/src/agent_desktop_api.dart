import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class AgentDesktopApi {
  AgentDesktopApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<AgentDesktopSnapshot> snapshot() async {
    final pairing = await _discoverPairing();
    final responses = await Future.wait([
      _get(pairing, '/api/live'),
      _get(pairing, '/api/desktop/status'),
      _get(pairing, '/api/workers'),
      _get(pairing, '/api/hackathons'),
      _get(pairing, '/api/placements'),
      _get(pairing, '/api/neopat'),
    ]);

    return AgentDesktopSnapshot.fromJson(
      baseUrl: pairing.baseUrl,
      live: responses[0],
      desktop: responses[1],
      workers: responses[2],
      hackathons: responses[3],
      placements: responses[4],
      neopat: responses[5],
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

    final decoded = jsonDecode(response.body);
    if (decoded is List<dynamic>) return {'items': decoded};
    return decoded as Map<String, dynamic>;
  }

  List<String> _candidateBaseUrls() {
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
    return uri
        .replace(path: '', query: '', fragment: '')
        .toString()
        .replaceAll(RegExp(r'/+$'), '');
  }
}

class _Pairing {
  const _Pairing({required this.baseUrl, required this.token});

  final String baseUrl;
  final String token;
}
