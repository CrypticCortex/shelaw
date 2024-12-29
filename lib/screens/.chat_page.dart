import 'dart:convert';
import 'dart:async'; // For Timer if you want debounce logic
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // For rendering Markdown

// To open links in the device browser:
import 'package:url_launcher/url_launcher.dart';

import '../services/chat_service.dart';

/// Represents a single chat block: either user or assistant.
/// For assistant blocks, we store hiddenMessages containing the intermediate steps,
/// plus optional 'sources' if web search was used.
class ChatBlock {
  final String role; // "user" or "assistant"
  final String content;
  final List<String> hiddenMessages;
  final bool webSearchNeeded;
  final List<dynamic>? sources; // optional array of link data or summaries

  ChatBlock({
    required this.role,
    required this.content,
    required this.hiddenMessages,
    this.webSearchNeeded = false,
    this.sources,
  });
}

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

/// Add SingleTickerProviderStateMixin or TickerProviderStateMixin
/// to ensure stable animations while scrolling.
class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  late WebSocketChannel _channel;

  // The entire conversation is stored as a list of ChatBlocks.
  List<ChatBlock> _blocks = [];

  // Ephemeral intermediate steps from status updates
  List<String> _currentIntermediate = [];

  // Single, most recent status line to be displayed with a shimmer
  String? _currentStatusMessage;

  // Whether we are actively waiting for a final answer
  bool _waitingForFinal = false;

  // Whether the pipeline says we need web search (from ephemeral status)
  bool _webSearchNeeded = false;

  // Current session id
  String? _sessionId;

  // Current tone: "casual" or "detailed"
  String _selectedTone = "detailed";

  // Scroll controller
  final ScrollController _scrollController = ScrollController();

  // Optional: Debounce timer if you want to avoid spammy scrolling calls
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    // Start chat automatically in "detailed" mode (default)
    _startNewChat();
  }

  /// Starts (or restarts) a new chat session by calling /ask
  /// then connecting to the WebSocket with the chosen tone.
  void _startNewChat() async {
    // Clear conversation if you want to start fresh
    setState(() {
      _blocks.clear();
      _currentIntermediate.clear();
      _currentStatusMessage = null;
      _waitingForFinal = false;
      _webSearchNeeded = false;
    });

    final sessionId = await _chatService.startNewChat("Hello");
    setState(() {
      _sessionId = sessionId;
    });

    // Connect with the chosen tone
    _channel = _chatService.connectToWebSocket(sessionId, tone: _selectedTone);

    // Listen for incoming WebSocket messages
    _channel.stream.listen((rawMessage) {
      final data = jsonDecode(rawMessage);

      if (data['type'] == 'status') {
        // Intermediate status update
        final msg = data['message'] ?? "";
        _updateIntermediateStatus(msg);

        // If the pipeline says "Web search needed = 1", set this flag
        if (msg.contains("Web search needed = 1")) {
          setState(() {
            _webSearchNeeded = true;
          });
        }
      } else if (data['type'] == 'final_answer') {
        // Final answer arrived
        // If tone is "casual", show short_answer
        // If tone is "detailed", show full_answer
        final answer = (_selectedTone == "casual")
            ? data['short_answer']
            : data['full_answer'];

        // We also have sources, source_type, etc.
        final sources = data['sources']; // might be a list or null

        _handleFinalAnswer(answer, sources);
      } else if (data['type'] == 'error') {
        // Handle error if desired
        final errMsg = data['message'] ?? "Unknown error";
        debugPrint("Error from server: $errMsg");
      }
    }, onError: (err) {
      debugPrint("WebSocket error: $err");
    }, onDone: () {
      debugPrint("WebSocket closed.");
    });
  }

  /// Send user message
  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;

    // Add a user block
    setState(() {
      _blocks.add(ChatBlock(
        role: "user",
        content: message,
        hiddenMessages: [],
      ));
    });

    // Reset ephemeral status data for this new Q→A
    setState(() {
      _waitingForFinal = true;
      _currentStatusMessage = null;
      _currentIntermediate.clear();
      // Reset webSearchNeeded each time user sends a new question
      _webSearchNeeded = false;
    });

    // Send to WebSocket
    _channel.sink.add(jsonEncode({"user_input": message}));
    _controller.clear();

    // Scroll to bottom (or scroll if near bottom)
    _scrollToBottomIfNear();
  }

  /// Handle ephemeral status messages
  void _updateIntermediateStatus(String content) {
    setState(() {
      _currentStatusMessage = content;
      _currentIntermediate.add(content);
    });
    // Auto-scroll (or only if near bottom)
    _scrollToBottomIfNear();
  }

  /// Handle final answer
  void _handleFinalAnswer(String answer, List<dynamic>? sources) {
    setState(() {
      // Create an assistant block with final text (Markdown) + ephemeral messages
      _blocks.add(
        ChatBlock(
          role: "assistant",
          content: answer,
          hiddenMessages: List.from(_currentIntermediate),
          webSearchNeeded: _webSearchNeeded,
          sources: sources,
        ),
      );

      // Clear ephemeral data
      _currentIntermediate.clear();
      _currentStatusMessage = null;
      _waitingForFinal = false;
      // Reset _webSearchNeeded so it doesn't carry over to next question
      _webSearchNeeded = false;
    });
    // Scroll to bottom
    _scrollToBottomIfNear();
  }

  /// Show a popup with the intermediate steps
  void _showHiddenMessages(List<String> hidden) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("AI Thought About"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: hidden.map((msg) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    msg,
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  /// Opens a URL in the device browser
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch $url");
    }
  }

  /// Show a popup with the sources if user taps "Sources".
  /// - "Source 1" is a clickable text; tapping it opens the link.
  /// - Then "Summary: ..." is displayed below.
  void _showSources(List<dynamic> sources) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Sources"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < sources.length; i++) ...[
                  // Each "Source i+1" is clickable
                  if (sources[i] is Map && sources[i].containsKey("url")) ...[
                    InkWell(
                      onTap: () => _launchURL(sources[i]['url']),
                      child: Text(
                        "Source ${i + 1}",
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // If there's a summary, display it
                    if (sources[i].containsKey('summary'))
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
                        child: Text("Summary: ${sources[i]['summary']}"),
                      ),
                  ] else ...[
                    // fallback for unknown format
                    Text("Source ${i + 1}",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(sources[i].toString()),
                    )
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  /// (Optional) Check if user is near bottom of the list
  bool _isNearBottom() {
    if (!_scrollController.hasClients) return false;
    final threshold = 100.0; // how close to bottom is "near"
    final position = _scrollController.position;
    return position.maxScrollExtent - position.pixels <= threshold;
  }

  /// Conditionally scroll to bottom if user is near bottom
  void _scrollToBottomIfNear() {
    if (_isNearBottom()) {
      _scrollToBottom();
    }
  }

  /// Smooth scroll to bottom (with checks & try/catch)
  void _scrollToBottom() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      try {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } catch (e) {
        debugPrint('Scrolling error: $e');
      }
    });
  }

  /// (Alternative) Debounced version if you get multiple updates quickly
  void _scrollToBottomDebounced() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 300), () {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _channel.sink.close();
    _scrollController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If we're waiting for final, show 1 ephemeral bubble at the bottom after all blocks
    final showEphemeralBubble =
        _waitingForFinal && _currentStatusMessage != null;
    final itemCount = _blocks.length + (showEphemeralBubble ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: Text("Chat"),
        actions: [
          TextButton(
            onPressed: () {
              // Switch to "casual" only if not already
              if (_selectedTone != "casual") {
                setState(() {
                  _selectedTone = "casual";
                });
                _startNewChat();
              }
            },
            child: Text(
              "Casual",
              style: TextStyle(
                color: _selectedTone == "casual" ? Colors.yellow : Colors.white,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // Switch to "detailed" only if not already
              if (_selectedTone != "detailed") {
                setState(() {
                  _selectedTone = "detailed";
                });
                _startNewChat();
              }
            },
            child: Text(
              "Detailed",
              style: TextStyle(
                color:
                    _selectedTone == "detailed" ? Colors.yellow : Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: itemCount,
              itemBuilder: (context, index) {
                // If ephemeral bubble is active, it occupies the last item
                if (showEphemeralBubble && index == _blocks.length) {
                  // A fixed bubble that grows by text size, with the text shimmering
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: Align(
                      alignment: Alignment.centerLeft, // Bot/assistant style
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // Shimmer just for text
                        child: Shimmer.fromColors(
                          period: const Duration(milliseconds: 1200),
                          baseColor: Colors.white54,
                          highlightColor: Colors.white,
                          child: Text(
                            _currentStatusMessage!,
                            style: const TextStyle(
                              color: Colors.black,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Render normal chat blocks (user or assistant)
                final block = _blocks[index];
                final isUser = block.role == "user";
                final isAssistant = block.role == "assistant";

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  child: Column(
                    crossAxisAlignment: isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      // Bubble
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.blue[100] : Colors.green[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // If assistant, we interpret block.content as Markdown
                        child: isAssistant
                            ? MarkdownBody(
                                data: block.content,
                                selectable: true,
                                styleSheet: _buildMarkdownStyle(context),
                              )
                            : Text(
                                block.content,
                                style: TextStyle(
                                  color: isUser ? Colors.blue : Colors.black,
                                ),
                              ),
                      ),
                      // If assistant:
                      // 1) "AI Thought About" if hiddenMessages is not empty.
                      // 2) If webSearchNeeded == true, add " | Sources" next to it if sources != null.
                      if (isAssistant &&
                          (block.hiddenMessages.isNotEmpty ||
                              (block.webSearchNeeded && block.sources != null)))
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // "AI Thought About" button if hidden messages exist
                              if (block.hiddenMessages.isNotEmpty)
                                GestureDetector(
                                  onTap: () =>
                                      _showHiddenMessages(block.hiddenMessages),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: Colors.grey),
                                      SizedBox(width: 6),
                                      Text(
                                        "AI Thought About",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // If both hiddenMessages and webSearchNeeded are true, show '|'
                              if (block.hiddenMessages.isNotEmpty &&
                                  block.webSearchNeeded &&
                                  block.sources != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Text("|",
                                      style: TextStyle(color: Colors.grey)),
                                ),
                              // "Sources" button if webSearchNeeded = true
                              if (block.webSearchNeeded &&
                                  block.sources != null)
                                GestureDetector(
                                  onTap: () => _showSources(block.sources!),
                                  child: Row(
                                    children: [
                                      Icon(Icons.link, color: Colors.grey),
                                      SizedBox(width: 6),
                                      Text(
                                        "Sources",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Input field & send button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_waitingForFinal, // disable until final answer
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                    onEditingComplete: () => _waitingForFinal
                        ? null // do nothing if waiting
                        : _sendMessage(_controller.text),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  // disable button if waiting
                  onPressed: _waitingForFinal
                      ? null
                      : () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a MarkdownStyleSheet that ensures no null fontSize issues.
  MarkdownStyleSheet _buildMarkdownStyle(BuildContext context) {
    final theme = Theme.of(context);

    // Grab any existing bodyMedium. If null or missing fontSize, provide a fallback.
    final bodyMedium =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final safeBodyMedium = bodyMedium.fontSize == null
        ? bodyMedium.copyWith(fontSize: 14)
        : bodyMedium;

    // Merge into a new theme that replaces bodyMedium with a safe fallback.
    final safeTheme = theme.copyWith(
      textTheme: theme.textTheme.copyWith(
        bodyMedium: safeBodyMedium,
      ),
    );

    return MarkdownStyleSheet.fromTheme(safeTheme);
  }
}
