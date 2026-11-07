
import 'package:flutter/material.dart';

import '../../core/networking/api_client.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _messageController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [];

  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'content': message,
      });
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await defaultApiClient.post(
        '/ai/chat',
        data: {'message': message},
      );

      final answer = response.data['answer']?.toString() ??
          'I could not generate a response.';

      if (!mounted) return;

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': answer,
        });
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              'I could not connect to EcoMind AI. Please check your connection and try again.',
        });
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const forestGreen = Color(0xFF174D37);
    const background = Color(0xFFF5F8F5);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: forestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(
                Icons.eco,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EcoMind AI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Ecological Intelligence',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcome(forestGreen)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final message = _messages[index];
                      final isUser = message['role'] == 'user';

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.82,
                          ),
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUser
                                ? forestGreen
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 5,
                              ),
                            ],
                          ),

                        child: isUser
                            ? Text(
                                message['content'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  height: 1.5,
                                  fontSize: 14,
                                ),
                              )
                            : MarkdownBody(
                                data: message['content'] ?? '',
                                selectable: true,
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(
                                    color: Color(0xFF26352D),
                                    height: 1.6,
                                    fontSize: 14,
                                  ),
                                  h1: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF174D37),
                                  ),
                                  h2: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF174D37),
                                  ),
                                  h3: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF174D37),
                                  ),
                                  strong: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF174D37),
                                  ),
                                  listBullet: const TextStyle(
                                    color: Color(0xFF174D37),
                                ),
                              ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE5EBE6)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ask EcoMind about ecosystems...',
                        filled: true,
                        fillColor: background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _isLoading ? null : _sendMessage,
                    style: IconButton.styleFrom(
                      backgroundColor: forestGreen,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome(Color forestGreen) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco,
              size: 64,
              color: forestGreen,
            ),
            const SizedBox(height: 18),
            Text(
              'Welcome to EcoMind AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: forestGreen,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your ecological intelligence assistant. '
              'Explore biodiversity, understand ecosystem threats, '
              'and discover science-informed restoration strategies.',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.5,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Try asking:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _suggestionChip(
              'How can we restore degraded forests?',
              forestGreen,
            ),
            _suggestionChip(
              'Why is biodiversity important?',
              forestGreen,
            ),
            _suggestionChip(
              'What threatens native wildlife?',
              forestGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionChip(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ActionChip(
        label: Text(text),
        onPressed: () {
          _messageController.text = text;
          _sendMessage();
        },
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
    );
  }
}
