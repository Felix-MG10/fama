import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'app_constants.dart';

/// Appel simple POST vers le backend pour tester l'API Orange Money.
/// Vérifie : status 200, présence de short_link, body vide, erreurs CORS.
Future<void> testOrangeBackend() async {
  final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.testOrangeBackendUri}');
  if (kDebugMode) {
    debugPrint('🧪 ÉTAPE 2 — Test FLUTTER → BACKEND');
    debugPrint('URL: $url');
  }

  try {
    final response = await http.post(url);

    if (kDebugMode) {
      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');
    }

    // Vérifications
    final is200 = response.statusCode == 200;
    final bodyEmpty = response.body.isEmpty;
    String? shortLink;
    try {
      final json = jsonDecode(response.body);
      shortLink = json['short_link'] ?? json['data']?['short_link'] ?? json['orange_response']?['short_link'];
    } catch (_) {}

    if (kDebugMode) {
      debugPrint('--- Vérifications ---');
      debugPrint('Status 200 ? $is200');
      debugPrint('short_link présent ? ${shortLink != null && shortLink.isNotEmpty}');
      debugPrint('Body vide ? $bodyEmpty');
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('❌ Erreur: $e');
      debugPrint('Stack: $st');
    }
  }
}
