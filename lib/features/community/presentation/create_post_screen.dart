import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/anonymous_name.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/repository_providers.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  Future<void> _submit() async {
    if (_saving) return;
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something before posting.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final session = ref.read(sessionProvider);
      if (session == null) throw Exception('Not authenticated');
      final alias = anonymousNameFor(session.user.id);
      await ref
          .read(communityRepositoryProvider)
          .createPost(content: text, anonymousName: alias);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Post')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Stay anonymous. Be kind. Share what you need today.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Write your post…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Post',
              onPressed: _saving ? null : _submit,
              isLoading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}
