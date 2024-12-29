/// Represents a single chat block: either user or assistant.
class ChatBlock {
  final String role; // "user" or "assistant"
  final String content;
  final List<String> hiddenMessages;
  final bool webSearchNeeded;
  final List<dynamic>? sources;

  ChatBlock({
    required this.role,
    required this.content,
    required this.hiddenMessages,
    this.webSearchNeeded = false,
    this.sources,
  });
}
