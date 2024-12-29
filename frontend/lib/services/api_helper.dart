import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiHelper {
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final url = "$apiBaseUrl$endpoint";
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception("Failed to connect to $url: $e");
    }
  }
}
