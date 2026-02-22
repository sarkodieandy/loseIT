import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/anonymous_name.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_card.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';

class DmChatScreen extends ConsumerStatefulWidget {
  const DmChatScreen({
    super.key,
    this.threadId,
    this.otherUserId,
    this.otherAlias,
  });

  final String? threadId;
  final String? otherUserId;
  final String? otherAlias;

  @override
  ConsumerState<DmChatScreen> createState() => _DmChatScreenState();
}

class _DmChatScreenState extends ConsumerState<DmChatScreen> {
  final _controller = TextEditingController();
  bool _sending = false;
  late Future<String> _threadFuture;
  static const List<String> _nudges = <String>[
    'You got this.',
    'Proud of you for showing up.',
    'Breathe. One minute at a time.',
    'Stay strong tonight.',
    'If you slip, don’t disappear. Keep going.',
  ];

  @override
  void initState() {
    super.initState();
    _threadFuture = _resolveThreadId();
  }

  Future<String> _resolveThreadId() async {
    final repo = ref.read(dmRepositoryProvider);
    if (widget.threadId != null) {
      final thread = await repo.fetchThread(widget.threadId!);
      if (thread == null) {
        throw Exception('Thread not found.');
      }
      return thread.id;
    }
    final otherUserId = widget.otherUserId;
    if (otherUserId == null) {
      throw Exception('Missing recipient.');
    }
    final thread = await repo.getOrCreateThread(otherUserId);
    return thread.id;
  }

  Future<void> _send(String threadId) async {
    if (_sending) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await ref.read(dmRepositoryProvider).sendMessage(
            threadId: threadId,
            content: text,
          );
      _controller.clear();
    } catch (error, stackTrace) {
      AppLogger.error('dm.send', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _sendNudge(String threadId, String text) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(dmRepositoryProvider).sendMessage(
            threadId: threadId,
            content: text,
          );
    } catch (error, stackTrace) {
      AppLogger.error('dm.sendNudge', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (session == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to use direct messages.')),
      );
    }

    return FutureBuilder<String>(
      future: _threadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Direct Message')),
            body: Center(
              child: Text(snapshot.error?.toString() ?? 'Unable to load chat.'),
            ),
          );
        }
        final threadId = snapshot.data!;
        final messagesAsync = ref.watch(dmMessagesProvider(threadId));

        return Scaffold(
          appBar: AppBar(
            title: Text(_resolveTitle(session.user.id)),
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return const Center(child: Text('No messages yet.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMine = message.senderId == session.user.id;
                        return Align(
                          alignment:
                              isMine ? Alignment.centerRight : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 280),
                            child: SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    message.content,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    Formatters.timeAgo(message.createdAt),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('Failed: $error')),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  8 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final text = _nudges[index];
                          return ActionChip(
                            label: Text(text),
                            onPressed:
                                _sending ? null : () => _sendNudge(threadId, text),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemCount: _nudges.length,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(threadId),
                            decoration: const InputDecoration(
                              hintText: 'Write a message…',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: _sending ? null : () => _send(threadId),
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _resolveTitle(String currentUserId) {
    if (widget.otherAlias != null && widget.otherAlias!.isNotEmpty) {
      return widget.otherAlias!;
    }
    if (widget.otherUserId != null) {
      return anonymousNameFor(widget.otherUserId!);
    }
    return 'Direct Message';
  }
}
