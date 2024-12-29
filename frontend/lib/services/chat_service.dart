import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config.dart';
import 'api_helper.dart';

class ChatService {
  /// Start a new chat by hitting the /ask endpoint
  Future<String> startNewChat(String userInput) async {
    final response = await ApiHelper.post("/ask", {"user_input": userInput});
    return response['session_id'];
  }

  /// Connect to WebSocket with the given sessionId and tone
  WebSocketChannel connectToWebSocket(String sessionId, {String tone = "detailed"}) {
    // Example: ws://[YOUR_SERVER_URL]/ws?session_id=abc-123&tone=detailed
    final url = "$webSocketUrl?session_id=$sessionId&tone=$tone";
    return WebSocketChannel.connect(Uri.parse(url));
  }
}
