// lib/services/chat_storage_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class ChatStorageService {
  /// Save a JSON map (e.g. { "sessionId": "...", "blocks": [...] }) to sessionId.json
  Future<void> saveChatSession(String sessionId, Map<String, dynamic> data) async {
    final file = await _getSessionFile(sessionId);
    await file.writeAsString(jsonEncode(data));
  }

  /// Load a chat session JSON from disk. Returns null if not found/invalid.
  Future<Map<String, dynamic>?> loadChatSession(String sessionId) async {
    try {
      final file = await _getSessionFile(sessionId);
      if (!await file.exists()) return null;
      final contents = await file.readAsString();
      return jsonDecode(contents) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// List all JSON files in the docs directory, parse each, and return a list of sessions:
  /// e.g. [ { "sessionId": "abc123", "title": "First user message...", "lastModified": "..." }, ... ]
  Future<List<Map<String, dynamic>>> listAllSessions() async {
    final dir = await _getDocumentsDirectory();
    final files = dir.listSync();

    final sessions = <Map<String, dynamic>>[];

    for (var entity in files) {
      if (entity is File && entity.path.endsWith('.json')) {
        final name = entity.uri.pathSegments.last;
        final sessionId = name.replaceAll('.json', '');
        final stat = await entity.stat();
        final lastModified = stat.modified;

        // Try to read the first user message as "title"
        String title = sessionId;
        try {
          final data = jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
          if (data['blocks'] is List) {
            final blocks = data['blocks'] as List<dynamic>;
            final firstUserBlock = blocks.firstWhere(
              (b) => b['role'] == 'user',
              orElse: () => null,
            );
            if (firstUserBlock != null && firstUserBlock['content'] is String) {
              title = firstUserBlock['content'];
            }
          }
        } catch (_) {
          // ignore parse errors, fallback to sessionId
        }

        sessions.add({
          'sessionId': sessionId,
          'title': title,
          'lastModified': lastModified.toIso8601String(),
        });
      }
    }

    // Sort descending by lastModified
    sessions.sort((a, b) => b['lastModified'].compareTo(a['lastModified']));
    return sessions;
  }

  /// Delete a specific session by removing the JSON file
  Future<void> deleteChatSession(String sessionId) async {
    final file = await _getSessionFile(sessionId);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Internal helper to get a File handle for sessionId.json
  Future<File> _getSessionFile(String sessionId) async {
    final dir = await _getDocumentsDirectory();
    return File('${dir.path}/$sessionId.json');
  }

  /// Returns the documents directory on each platform
  Future<Directory> _getDocumentsDirectory() async {
    return getApplicationDocumentsDirectory();
  }
}
