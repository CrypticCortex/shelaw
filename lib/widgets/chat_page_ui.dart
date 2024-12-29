import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../viewmodels/chat_page_viewmodel.dart';
import '../models/chat_block.dart';
import '../app_colors.dart';
import 'chat_styles.dart';

class ChatPageUI extends StatelessWidget {
  final ChatPageViewModel viewModel;

  const ChatPageUI({Key? key, required this.viewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final showEphemeralBubble =
        viewModel.waitingForFinal && viewModel.currentStatusMessage != null;
    final itemCount = viewModel.blocks.length + (showEphemeralBubble ? 1 : 0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "SheLaw AI",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          _buildToneButton("casual", context),
          _buildToneButton("detailed", context),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                image: DecorationImage(
                  image: const AssetImage(
                      'assets/chat_background.png'), // Add a subtle background pattern
                  opacity: 0.05,
                  repeat: ImageRepeat.repeat,
                ),
              ),
              child: ListView.builder(
                controller: viewModel.scrollController,
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (showEphemeralBubble && index == viewModel.blocks.length) {
                    return _buildEphemeralBubble(context);
                  }
                  return _buildChatBlock(context, viewModel.blocks[index]);
                },
              ),
            ),
          ),
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildToneButton(String tone, BuildContext context) {
    final isSelected = viewModel.selectedTone == tone;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: () => viewModel.switchTone(tone),
        style: TextButton.styleFrom(
          backgroundColor:
              isSelected ? AppColors.darkPurple : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          tone.capitalize(),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEphemeralBubble(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: ChatStyles.ephemeralBubbleDecoration(),
          child: Shimmer.fromColors(
            period: const Duration(milliseconds: 1500),
            baseColor: AppColors.lightPink.withOpacity(0.4),
            highlightColor: Colors.white,
            child: Text(
              viewModel.currentStatusMessage!,
              style: ChatStyles.ephemeralTextStyle(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatBlock(BuildContext context, ChatBlock block) {
    final isUser = block.role == "user";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: isUser
                ? ChatStyles.userBubbleDecoration()
                : ChatStyles.assistantBubbleDecoration(),
            child: isUser
                ? Text(
                    block.content,
                    style: ChatStyles.userTextStyle(),
                  )
                : MarkdownBody(
                    data: block.content,
                    selectable: true,
                    styleSheet: ChatStyles.buildMarkdownStyle(context),
                  ),
          ),
          if (!isUser && _shouldShowInfoButtons(block))
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: _buildInfoButtons(context, block),
            ),
        ],
      ),
    );
  }

  bool _shouldShowInfoButtons(ChatBlock block) {
    return block.hiddenMessages.isNotEmpty ||
        (block.webSearchNeeded && block.sources != null);
  }

  Widget _buildInfoButtons(BuildContext context, ChatBlock block) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (block.hiddenMessages.isNotEmpty)
          _buildInfoButton(
            icon: Icons.psychology_outlined,
            label: "AI Thought About",
            onTap: () => _showHiddenMessages(context, block),
          ),
        if (block.hiddenMessages.isNotEmpty &&
            block.webSearchNeeded &&
            block.sources != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text("•",
                style:
                    TextStyle(color: ChatStyles.infoIconColor(), fontSize: 8)),
          ),
        if (block.webSearchNeeded && block.sources != null)
          _buildInfoButton(
            icon: Icons.source_outlined,
            label: "Sources",
            onTap: () => _showSources(context, block.sources!),
          ),
      ],
    );
  }

  Widget _buildInfoButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: ChatStyles.infoIconColor()),
            const SizedBox(width: 4),
            Text(label, style: ChatStyles.infoButtonTextStyle()),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: viewModel.controller,
              enabled: !viewModel.waitingForFinal,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: "Type your message...",
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.primaryRed),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onEditingComplete:
                  viewModel.waitingForFinal ? null : viewModel.sendMessage,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded),
              color: Colors.white,
              onPressed:
                  viewModel.waitingForFinal ? null : viewModel.sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _showHiddenMessages(BuildContext context, ChatBlock block) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology_outlined,
                      color: AppColors.primaryRed, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    "AI Thought Process",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: block.hiddenMessages.map((msg) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          msg,
                          style: TextStyle(
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryRed,
                  ),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSources(BuildContext context, List<dynamic> sources) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.source_outlined,
                      color: AppColors.primaryRed, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    "Sources",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < sources.length; i++) ...[
                        if (sources[i] is Map && sources[i].containsKey("url"))
                          _buildSourceWithUrl(sources[i], i)
                        else
                          _buildSimpleSource(sources[i], i),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryRed,
                  ),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceWithUrl(Map source, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _launchURL(source['url']),
            child: Text(
              "Source ${index + 1}",
              style: TextStyle(
                color: AppColors.primaryRed,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (source.containsKey('summary'))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Summary: ${source['summary']}",
                style: TextStyle(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSimpleSource(dynamic source, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Source ${index + 1}",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            source.toString(),
            style: TextStyle(
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch $url");
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
