// /home/omen/shelaw/lib/pages/chat_page.dart

import 'package:flutter/material.dart';
import '../viewmodels/chat_page_viewmodel.dart';
import '../widgets/chat_page_ui.dart';

class ChatPage extends StatefulWidget {
  /// If not null, we load an existing session from local JSON and continue
  /// that conversation. Otherwise, we start a brand-new session.
  final String? existingSessionId;

  const ChatPage({Key? key, this.existingSessionId}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late ChatPageViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    _viewModel = ChatPageViewModel();

    // Load or start chat in the ViewModel
    _viewModel.loadOrStartChat(widget.existingSessionId);
  }

  @override
  void dispose() {
    _viewModel.disposeViewModel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild whenever notifyListeners() is called in ViewModel
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return ChatPageUI(viewModel: _viewModel);
      },
    );
  }
}
