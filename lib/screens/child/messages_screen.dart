import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/child.dart';
import '../../models/message.dart';
import '../../services/message_service.dart';

class MessagesScreen extends StatefulWidget {
  final Child child;
  const MessagesScreen({super.key, required this.child});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Message> _messages = [];
  bool _loading = true;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final msgs = await MessageService.getMessagesRpc(
      familyId: widget.child.familyId,
      childId: widget.child.id,
    );
    setState(() {
      _messages = msgs;
      _loading = false;
    });
    _scrollToBottom();

    for (final msg in msgs.where((m) => !m.isRead && m.isFromParent)) {
      await MessageService.markAsReadRpc(msg.id);
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

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    await MessageService.sendFromChildRpc(
      familyId: widget.child.familyId,
      childId: widget.child.id,
      content: text,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💬 ', style: TextStyle(fontSize: 20)),
            Text('Mensagens'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('💬', style: TextStyle(fontSize: 48)),
                              SizedBox(height: 8),
                              Text('Nenhuma mensagem ainda', style: TextStyle(color: AppColors.textSecondary)),
                              SizedBox(height: 4),
                              Text('Envie uma mensagem para seus pais!', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isMe = !msg.isFromParent;

                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? AppColors.childGreen.withValues(alpha: 0.1)
                                      : AppColors.parentBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                                    bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isMe ? 'Voce' : 'Pai/Mae',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isMe ? AppColors.childGreen : AppColors.parentBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(msg.content, style: const TextStyle(fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatTime(msg.createdAt),
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'Escreva uma mensagem...',
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: AppColors.childGreen,
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white, size: 20),
                            onPressed: _send,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ontem ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }
}
