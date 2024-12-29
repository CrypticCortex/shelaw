// lib/viewmodels/chat_page_viewmodel.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../services/chat_service.dart';
import '../services/chat_storage_service.dart';
import '../models/chat_block.dart';

class ChatPageViewModel extends ChangeNotifier {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final ChatService chatService = ChatService();
  final ChatStorageService _storageService = ChatStorageService();

  late WebSocketChannel channel;

  List<ChatBlock> blocks = [];
  List<String> currentIntermediate = [];
  String? currentStatusMessage;
  bool waitingForFinal = false;
  bool webSearchNeeded = false;
  String? sessionId;
  String selectedTone = "detailed";

  Timer? scrollTimer;

  // --------------------------------------------------
  // Load existing or start new
  // --------------------------------------------------
  Future<void> loadOrStartChat(String? existingSessionId) async {
    // Clear old state
    blocks.clear();
    currentIntermediate.clear();
    currentStatusMessage = null;
    waitingForFinal = false;
    webSearchNeeded = false;
    notifyListeners();

    if (existingSessionId == null) {
      // Start new chat session
      final newSessionId = await chatService.startNewChat("Hello");
      sessionId = newSessionId;
    } else {
      // Try loading from local JSON
      final loadedData = await _storageService.loadChatSession(existingSessionId);
      if (loadedData != null) {
        sessionId = loadedData['sessionId'] as String?;
        final loadedBlocks = loadedData['blocks'] as List<dynamic>;
        // Safely map each block
        blocks = loadedBlocks.map((b) {
          return ChatBlock(
            role: b['role'] ?? 'assistant',
            content: b['content'] ?? '',
            hiddenMessages: (b['hiddenMessages'] ?? [])
                .map<String>((item) => item.toString())
                .toList(),
            webSearchNeeded: b['webSearchNeeded'] ?? false,
            sources: b['sources'],
          );
        }).toList();
      } else {
        // Not found or parse error - start new
        final newSessionId = await chatService.startNewChat("Hello");
        sessionId = newSessionId;
      }
    }

    // Now connect the WebSocket
    if (sessionId != null) {
      _connectWebSocket(sessionId!);
    }
  }

  void _connectWebSocket(String sessionId) {
    channel = chatService.connectToWebSocket(sessionId, tone: selectedTone);

    channel.stream.listen(
      (rawMessage) => _handleServerMessage(rawMessage),
      onError: (err) => debugPrint("WebSocket error: $err"),
      onDone: () => debugPrint("WebSocket closed."),
    );
  }

  void disposeViewModel() {
    channel.sink.close();
    scrollController.dispose();
    scrollTimer?.cancel();
    controller.dispose();
  }

  // --------------------------------------------------
  // Server message handling
  // --------------------------------------------------
  void _handleServerMessage(dynamic rawMessage) {
    final data = jsonDecode(rawMessage);
    final type = data['type'];

    if (type == 'status') {
      _handleStatus(data['message'] ?? "");
    } else if (type == 'final_answer') {
      _handleFinalAnswer(data);
    } else if (type == 'error') {
      final errMsg = data['message'] ?? "Unknown error";
      debugPrint("Error from server: $errMsg");
    }
  }

  void _handleStatus(String content) {
    currentStatusMessage = content;
    currentIntermediate.add(content);

    if (content.contains("Web search needed = 1")) {
      webSearchNeeded = true;
    }

    notifyListeners();
    _scrollToBottomIfNear();
  }

  void _handleFinalAnswer(Map<String, dynamic> data) {
    final shortAnswer = data['short_answer'] as String? ?? "";
    final fullAnswer = data['full_answer'] as String? ?? "";
    final answer = (selectedTone == "casual") ? shortAnswer : fullAnswer;
    final sources = data['sources'];

    blocks.add(
      ChatBlock(
        role: "assistant",
        content: answer.isNotEmpty ? answer : "[No answer returned]",
        hiddenMessages: List.from(currentIntermediate),
        webSearchNeeded: webSearchNeeded,
        sources: sources,
      ),
    );

    currentIntermediate.clear();
    currentStatusMessage = null;
    waitingForFinal = false;
    webSearchNeeded = false;

    notifyListeners();
    _scrollToBottomIfNear();
    _persistChatLocally();
  }

  // --------------------------------------------------
  // User message
  // --------------------------------------------------
  void sendMessage() {
    final message = controller.text.trim();
    if (message.isEmpty) return;

    blocks.add(
      ChatBlock(
        role: "user",
        content: message,
        hiddenMessages: [],
      ),
    );

    waitingForFinal = true;
    currentStatusMessage = null;
    currentIntermediate.clear();
    webSearchNeeded = false;

    channel.sink.add(jsonEncode({"user_input": message}));
    controller.clear();

    notifyListeners();
    _scrollToBottomIfNear();
    _persistChatLocally();
  }

  void switchTone(String newTone) {
    if (selectedTone == newTone) return;
    selectedTone = newTone;
    notifyListeners();
  }

  // --------------------------------------------------
  // Local persistence
  // --------------------------------------------------
  Future<void> _persistChatLocally() async {
    if (sessionId == null) return;

    final data = {
      'sessionId': sessionId,
      'blocks': blocks.map((b) => {
        'role': b.role,
        'content': b.content,
        'hiddenMessages': b.hiddenMessages,
        'webSearchNeeded': b.webSearchNeeded,
        'sources': b.sources,
      }).toList(),
    };

    try {
      await _storageService.saveChatSession(sessionId!, data);
    } catch (e) {
      debugPrint("Error saving chat session: $e");
    }
  }

  // --------------------------------------------------
  // Scrolling
  // --------------------------------------------------
  bool _isNearBottom() {
    if (!scrollController.hasClients) return false;
    final threshold = 100.0;
    final position = scrollController.position;
    return position.maxScrollExtent - position.pixels <= threshold;
  }

  void _scrollToBottomIfNear() {
    if (_isNearBottom()) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      try {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } catch (e) {
        debugPrint("Scrolling error: $e");
      }
    });
  }
}
