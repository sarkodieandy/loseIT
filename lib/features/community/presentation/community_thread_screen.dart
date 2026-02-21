import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/anonymous_name.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_card.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';

class CommunityThreadScreen extends ConsumerStatefulWidget {
  const CommunityThreadScreen({
    super.key,
    required this.postId,
  });

  final String postId;

  @override
  ConsumerState<CommunityThreadScreen> createState() => _CommunityThreadScreenState();
}

class _CommunityThreadScreenState extends ConsumerState<CommunityThreadScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  Future<void> _sendReply() async {
    if (_sending) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final session = ref.read(sessionProvider);
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to reply.')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final alias = anonymousNameFor(session.user.id);
      await ref.read(communityRepositoryProvider).createReply(
            postId: widget.postId,
            content: text,
            anonymousName: alias,
          );
      _controller.clear();
    } catch (error) {
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

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(communityPostProvider(widget.postId));
    final repliesAsync = ref.watch(communityRepliesProvider(widget.postId));
    final media = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Replies')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: postAsync.when(
              data: (post) {
                if (post == null) {
                  return const SectionCard(
                    child: Text('Post not found.'),
                  );
                }
                return SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            post.anonymousName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            Formatters.timeAgo(post.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(post.content),
                    ],
                  ),
                );
              },
              loading: () => const SectionCard(child: Text('Loading post…')),
              error: (error, _) => SectionCard(child: Text('Error: $error')),
            ),
          ),
          Expanded(
            child: repliesAsync.when(
              data: (replies) {
                if (replies.isEmpty) {
                  return const Center(child: Text('No replies yet.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  itemBuilder: (context, index) {
                    final reply = replies[index];
                    return SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                reply.anonymousName,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                Formatters.timeAgo(reply.createdAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(reply.content),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: replies.length,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Failed: $error')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            8 + media.viewInsets.bottom,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendReply(),
                  decoration: const InputDecoration(
                    hintText: 'Write a reply…',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: _sending ? null : _sendReply,
                icon: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
