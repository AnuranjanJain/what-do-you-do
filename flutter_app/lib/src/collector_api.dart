import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class CollectorApi {
  CollectorApi({http.Client? client}) : _client = client ?? http.Client();

  static const baseUrl = 'http://127.0.0.1:17321';
  final http.Client _client;

  Future<Map<String, dynamic>> health() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/health'))
        .timeout(const Duration(seconds: 3));
    if (response.statusCode != 200) {
      throw Exception('Collector responded with ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<SessionsResponse> sessions(String date) async {
    final uri = Uri.parse(
      '$baseUrl/sessions',
    ).replace(queryParameters: {'date': date});
    final response = await _client.get(uri).timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) {
      throw Exception('Collector responded with ${response.statusCode}');
    }
    return SessionsResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<Hackathon>> hackathons() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/hackathons'))
        .timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) {
      throw Exception('Hackathon store responded with ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['hackathons'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Hackathon.fromJson)
        .toList();
  }
}
