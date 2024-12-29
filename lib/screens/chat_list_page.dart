// lib/screens/chat_list_page.dart
import 'package:flutter/material.dart';
import 'package:shelaw/app_colors.dart';
import 'package:shelaw/services/chat_storage_service.dart';
import 'package:shelaw/screens/auth_page.dart';
import 'package:shelaw/auth_services.dart';
import 'package:shelaw/pages/chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  bool _isLoading = false;
  bool _isLoggingOut = false;
  bool _error = false;
  Map<String, dynamic>? _userData;

  final AuthServices _authServices = AuthServices();
  final ChatStorageService _storageService = ChatStorageService();

  List<Map<String, dynamic>> _chatSessions = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData().then((_) => _loadChatSessions());
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _error = false;
    });

    try {
      final userInfo = await _authServices.getUserInfo();
      setState(() {
        _userData = userInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChatSessions() async {
    try {
      final sessions = await _storageService.listAllSessions();
      setState(() {
        _chatSessions = sessions;
      });
    } catch (e) {
      debugPrint("Error loading sessions: $e");
    }
  }

  Future<void> _handleLogout() async {
    setState(() {
      _isLoggingOut = true;
    });

    final result = await _authServices.logoutFromServer();
    if (result["success"] == true) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => AuthPage()),
        (route) => false,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Logout failed: ${result['message']}"),
          backgroundColor: AppColors.primaryRed,
        ),
      );
      setState(() {
        _isLoggingOut = false;
      });
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    // Optional: confirm with user
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Chat"),
        content:
            const Text("Are you sure you want to delete this chat history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.deleteChatSession(sessionId);
      _loadChatSessions(); // refresh
    }
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.primaryRed.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            const Text(
              "Failed to load user details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryRed,
      elevation: 0,
      title: const Text(
        "SheLaw AI",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
          onPressed: _handleLogout,
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Column(
        children: [
          // Profile Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              color: Colors.white,
            ),
            child: ClipOval(
              child: _userData?['profile_image'] != null
                  ? Image.network(
                      _userData!['profile_image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.primaryRed),
                    )
                  : const Icon(Icons.person,
                      size: 40, color: AppColors.primaryRed),
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            _userData?['full_name']?.toUpperCase() ?? 'NO NAME',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // Email
          Text(
            _userData?['email'] ?? 'No email',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_chatSessions.isEmpty) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(20),
          alignment: Alignment.center,
          child: const Text(
            "No chat history found.\nStart a new conversation!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HISTORY',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkPurple,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _chatSessions.length,
                itemBuilder: (context, index) {
                  final session = _chatSessions[index];
                  final sessionId = session['sessionId'] as String;
                  final title = session['title'] as String? ?? sessionId;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.lightPink.withOpacity(0.5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.lightPink.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Left icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.lightPink.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppColors.primaryRed.withOpacity(0.7),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Title (tapping it navigates to Chat)
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                // Pass existingSessionId so ChatPage loads conversation
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ChatPage(existingSessionId: sessionId),
                                  ),
                                );
                                _loadChatSessions(); // refresh after returning
                              },
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          // Delete button (trash icon)
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            onPressed: () => _deleteSession(sessionId),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewChatButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: () async {
          // Start a brand-new chat
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatPage(),
            ),
          );
          _loadChatSessions(); // reload sessions after new chat
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          minimumSize: const Size(double.infinity, 50),
          elevation: 2,
        ),
        child: const Text(
          "Start New Chat",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggingOut) {
      return _buildLoadingState();
    }
    if (_isLoading) {
      return _buildLoadingState();
    }
    if (_error) {
      return _buildErrorState();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildProfileSection(),
          _buildHistorySection(),
          _buildNewChatButton(),
        ],
      ),
    );
  }
}
