import 'dart:convert';
import 'package:http/http.dart' as http;

/// Reusable service for calling the Mule Detection AI model API.
class AiModelService {
  static const String _url =
      'https://tensorflow-model-skrv.onrender.com/predict';

  /// Sends [features] map to the AI model.
  /// Returns the full response map on success, or null on failure/timeout.
  static Future<Map<String, dynamic>?> predict(
      Map<String, dynamic> features) async {
    try {
      final res = await http
          .post(
            Uri.parse(_url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'features': features}),
          )
          .timeout(const Duration(seconds: 90));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Converts a raw Firebase nested map to Map<String, dynamic> safely.
  static Map<String, dynamic> toStringMap(dynamic raw) {
    if (raw is Map) {
      return raw.map((k, v) =>
          MapEntry(k.toString(), v is Map ? toStringMap(v) : v));
    }
    return {};
  }
}
