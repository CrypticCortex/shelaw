import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../app_colors.dart';

/// All the chat bubble and text styling in one place.
class ChatStyles {
  // Bubbles
  static BoxDecoration userBubbleDecoration() {
    return BoxDecoration(
      color: AppColors.pastelPink.withOpacity(0.7),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(4),
      ),
    );
  }

  static BoxDecoration assistantBubbleDecoration() {
    return BoxDecoration(
      color: AppColors.deepPurple.withOpacity(0.7),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(4),
        bottomRight: Radius.circular(20),
      ),
    );
  }

  static BoxDecoration ephemeralBubbleDecoration() {
    return BoxDecoration(
      color: AppColors.lightPink.withOpacity(0.5),
      borderRadius: const BorderRadius.all(Radius.circular(16)),
    );
  }

  // Text style for user text
  static TextStyle userTextStyle() {
    return const TextStyle(
      color: Colors.black87,
      fontSize: 16,
    );
  }

  // Text style for ephemeral status text
  static TextStyle ephemeralTextStyle() {
    return TextStyle(
      color: AppColors.darkPurple,
      fontStyle: FontStyle.italic,
      fontSize: 14,
    );
  }

  // For "AI Thought About", "Sources" links, etc.
  static TextStyle infoButtonTextStyle() {
    return TextStyle(
      color: AppColors.magenta.withOpacity(0.7),
      fontStyle: FontStyle.italic,
      fontSize: 12,
    );
  }

  // Icon colors
  static Color infoIconColor() => AppColors.magenta.withOpacity(0.7);

  // Example of building a safe Markdown Style:
  static MarkdownStyleSheet buildMarkdownStyle(BuildContext context) {
    final theme = Theme.of(context);

    // Grab any existing bodyMedium. If null or missing fontSize, provide a fallback.
    final bodyMedium =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 16);
    final safeBodyMedium = bodyMedium.fontSize == null
        ? bodyMedium.copyWith(fontSize: 16)
        : bodyMedium;

    // Merge into a new theme that replaces bodyMedium with a safe fallback.
    final safeTheme = theme.copyWith(
      textTheme: theme.textTheme.copyWith(
        bodyMedium: safeBodyMedium.copyWith(
          color: Colors.white,
        ),
      ),
    );

    return MarkdownStyleSheet.fromTheme(safeTheme).copyWith(
      p: safeBodyMedium.copyWith(color: Colors.white),
      a: TextStyle(color: AppColors.pastelPink),
      code: TextStyle(
        backgroundColor: AppColors.darkPurple,
        color: AppColors.pastelPink,
      ),
    );
  }
}
