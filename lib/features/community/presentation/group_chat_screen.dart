import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/utils/anonymous_name.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/app_motion.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animated_reveal.dart';
import '../../../data/models/group_message.dart';
import '../../../data/services/local_cache_service.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/group_chat_unread_providers.dart';
import '../../../providers/repository_providers.dart';
import 'tribe_colors.dart';

class _ChatColors {
  static Color bgTop(BuildContext context) => TribeColors.bgTop(context);
  static Color bgBottom(BuildContext context) => TribeColors.bgBottom(context);
  static Color card(BuildContext context) => TribeColors.card(context);
  static Color cardBorder(BuildContext context) =>
      TribeColors.cardBorder(context);
  static Color muted(BuildContext context) => TribeColors.muted(context);
  static Color accent(BuildContext context) => TribeColors.accent(context);
  static Color field(BuildContext context) => TribeColors.field(context);
  static Color textPrimary(BuildContext context) =>
      TribeColors.textPrimary(context);

  static Color mineBubble(BuildContext context) => TribeColors.accent(context);
  static Color otherBubble(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;
}

class GroupChatScreen extends ConsumerStatefulWidget {
  const GroupChatScreen({
    super.key,
    required this.groupId,
  });

  final String groupId;

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _controller = TextEditingController();
  bool _sending = false;
  bool _hasText = false;
  DateTime? _lastSeenUtc;
  final Set<String> _openingAttachmentIds = <String>{};
  final LinkedHashMap<String, Uint8List> _imagePreviewCache =
      LinkedHashMap<String, Uint8List>();
  static const int _imagePreviewCacheMax = 20;
  final ImagePicker _imagePicker = ImagePicker();

  late SupabaseClient _client;
  RealtimeChannel? _typingChannel;
  final Set<String> _typingUserIds = <String>{};
  Timer? _typingIdleTimer;
  bool _isTyping = false;
  DateTime? _lastTypingTrackUtc;
  bool _typingChannelEnabled = false;
  String? _presenceUserId;

  @override
  void initState() {
    super.initState();
    _client = ref.read(supabaseClientProvider);
  }

  @override
  void dispose() {
    _typingIdleTimer?.cancel();
    unawaited(_setTyping(false));
    unawaited(_stopTypingChannel());
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markSeen({
    required String userId,
    required DateTime seenAt,
  }) async {
    await LocalCacheService.instance.setGroupChatLastSeen(
      userId: userId,
      groupId: widget.groupId,
      seenAt: seenAt,
    );
    ref.invalidate(groupChatLastSeenProvider(widget.groupId));
  }

  Future<void> _send() async {
    if (_sending) return;
    final session = ref.read(sessionProvider);
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to chat.')),
      );
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await _setTyping(false);
      await ref.read(challengesRepositoryProvider).sendGroupMessage(
            groupId: widget.groupId,
            content: text,
          );
      _controller.clear();
      _hasText = false;
      HapticFeedback.selectionClick();
    } catch (error, stackTrace) {
      AppLogger.error('groupChat.send', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _hasText = _controller.text.trim().isNotEmpty;
        });
      }
    }
  }

  Future<void> _sendAttachment() async {
    if (_sending) return;
    final action = await showModalBottomSheet<_AttachmentAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              decoration: BoxDecoration(
                color: _ChatColors.card(context),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _ChatColors.cardBorder(context)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: 10),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _ChatColors.cardBorder(context),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _AttachmentTile(
                    icon: Icons.photo_outlined,
                    title: 'Photo',
                    subtitle: 'Send an image',
                    onTap: () => Navigator.of(context)
                        .pop(_AttachmentAction.photoGallery),
                  ),
                  _AttachmentTile(
                    icon: Icons.videocam_outlined,
                    title: 'Video',
                    subtitle: 'Send a video',
                    onTap: () => Navigator.of(context)
                        .pop(_AttachmentAction.videoGallery),
                  ),
                  _AttachmentTile(
                    icon: Icons.insert_drive_file_outlined,
                    title: 'File',
                    subtitle: 'Send any file',
                    onTap: () =>
                        Navigator.of(context).pop(_AttachmentAction.file),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    switch (action) {
      case _AttachmentAction.photoGallery:
        await _pickAndSendPhoto();
        return;
      case _AttachmentAction.videoGallery:
        await _pickAndSendVideo();
        return;
      case _AttachmentAction.file:
        await _pickAndSendFile();
        return;
    }
  }

  Future<void> _pickAndSendPhoto() async {
    if (_sending) return;
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked == null) return;

      await _sendPickedFile(
        file: File(picked.path),
        fileName: picked.name,
        mimeType: _mimeFromName(picked.name),
      );
    } catch (error, stackTrace) {
      AppLogger.error('groupChat.pickPhoto', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to pick a photo.')),
      );
    }
  }

  Future<void> _pickAndSendVideo() async {
    if (_sending) return;
    try {
      final picked = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
      if (picked == null) return;

      await _sendPickedFile(
        file: File(picked.path),
        fileName: picked.name,
        mimeType: _mimeFromName(picked.name),
      );
    } catch (error, stackTrace) {
      AppLogger.error('groupChat.pickVideo', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to pick a video.')),
      );
    }
  }

  Future<void> _pickAndSendFile() async {
    final session = ref.read(sessionProvider);
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to share files.')),
      );
      return;
    }

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false,
      );
    } catch (error, stackTrace) {
      AppLogger.error('groupChat.pickFile', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to pick a file on this device.')),
      );
      return;
    }

    if (result == null || result.files.isEmpty) return;

    final selected = result.files.single;
    final path = selected.path;
    if (path == null || path.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File selection is not supported here.')),
      );
      return;
    }

    await _sendPickedFile(
      file: File(path),
      fileName: selected.name,
      sizeBytes: selected.size,
      mimeType: _mimeFromName(selected.name),
    );
  }

  Future<void> _sendPickedFile({
    required File file,
    required String fileName,
    int? sizeBytes,
    String? mimeType,
  }) async {
    if (_sending) return;
    final session = ref.read(sessionProvider);
    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to share files.')),
      );
      return;
    }

    const maxBytes = 80 * 1024 * 1024; // 80 MB safety cap
    final length = sizeBytes ?? await file.length();
    if (length > maxBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File too large (max 80 MB).')),
      );
      return;
    }

    final messageId = const Uuid().v4();
    final caption = _controller.text.trim();

    setState(() => _sending = true);
    try {
      await _setTyping(false);
      await ref.read(challengesRepositoryProvider).sendGroupFileMessage(
            groupId: widget.groupId,
            messageId: messageId,
            file: file,
            fileName: fileName,
            mimeType: mimeType,
            sizeBytes: length,
            caption: caption.isEmpty ? null : caption,
          );
      _controller.clear();
      _hasText = false;
      HapticFeedback.selectionClick();
    } catch (error, stackTrace) {
      AppLogger.error('groupChat.sendFile', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _hasText = _controller.text.trim().isNotEmpty;
        });
      }
    }
  }

  static String? _mimeFromName(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'm4v':
        return 'video/x-m4v';
      case 'webm':
        return 'video/webm';
      default:
        return null;
    }
  }

  Future<void> _openAttachment(GroupMessage message) async {
    final path = message.attachmentPath;
    if (path == null || path.trim().isEmpty) return;
    if (_openingAttachmentIds.contains(message.id)) return;

    _openingAttachmentIds.add(message.id);
    try {
      final isImage = _isImageAttachment(message);
      final isVideo = _isVideoAttachment(message);
      final bytes = isImage
          ? await _loadImagePreviewBytes(message)
          : await ref
              .read(challengesRepositoryProvider)
              .downloadGroupAttachment(path);
      final dir = await getTemporaryDirectory();

      final rawName =
          (message.attachmentName ?? message.content).trim().isEmpty
              ? 'attachment'
              : (message.attachmentName ?? message.content).trim();
      final safeName = rawName.replaceAll(RegExp(r'[\\\\/]+'), '_');
      final file = File('${dir.path}/${message.id}_$safeName');
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;

      if (isImage || isVideo) {
        try {
          final result =
              await ImageGallerySaver.saveFile(file.path, name: safeName);
          final success =
              result is Map ? (result['isSuccess'] == true) : false;
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved to Photos.')),
            );
            return;
          }
        } catch (error, stackTrace) {
          AppLogger.error('groupChat.saveToGallery', error, stackTrace);
        }
      }

      await Share.shareXFiles(<XFile>[XFile(file.path)], text: safeName);
    } catch (error, stackTrace) {
      AppLogger.error('groupChat.openAttachment', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open attachment.')),
      );
    } finally {
      _openingAttachmentIds.remove(message.id);
    }
  }

  static bool _isImageAttachment(GroupMessage message) {
    final mime = message.attachmentMime?.toLowerCase().trim();
    if (mime != null && mime.startsWith('image/')) return true;
    final name = (message.attachmentName ?? '').toLowerCase().trim();
    if (!name.contains('.')) return false;
    final ext = name.split('.').last;
    return <String>{'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'}.contains(ext);
  }

  static bool _isVideoAttachment(GroupMessage message) {
    final mime = message.attachmentMime?.toLowerCase().trim();
    if (mime != null && mime.startsWith('video/')) return true;
    final name = (message.attachmentName ?? '').toLowerCase().trim();
    if (!name.contains('.')) return false;
    final ext = name.split('.').last;
    return <String>{'mp4', 'mov', 'm4v', 'webm', 'mkv', 'avi'}.contains(ext);
  }

  Future<Uint8List> _loadImagePreviewBytes(GroupMessage message) async {
    final cached = _imagePreviewCache[message.id];
    if (cached != null) return cached;
    final path = message.attachmentPath;
    if (path == null || path.trim().isEmpty) {
      throw Exception('Missing attachment path');
    }
    final bytes = await ref
        .read(challengesRepositoryProvider)
        .downloadGroupAttachment(path);
    _imagePreviewCache[message.id] = bytes;
    if (_imagePreviewCache.length > _imagePreviewCacheMax) {
      _imagePreviewCache.remove(_imagePreviewCache.keys.first);
    }
    return bytes;
  }

  void _handleOpenAttachment(GroupMessage message) {
    if (_isImageAttachment(message)) {
      unawaited(_openImageViewer(message));
      return;
    }
    unawaited(_openAttachment(message));
  }

  Future<void> _openImageViewer(GroupMessage message) async {
    if (!mounted) return;
    final bytesFuture = _loadImagePreviewBytes(message);
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (context, _, __) => _ImageViewerScreen(
          title: (message.attachmentName ?? 'Photo').trim().isEmpty
              ? 'Photo'
              : (message.attachmentName ?? 'Photo').trim(),
          bytesFuture: bytesFuture,
          onDownload: () => _openAttachment(message),
        ),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _handleComposerChanged(String value) {
    final hasText = value.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }

    if (!_typingChannelEnabled) return;

    if (!hasText) {
      _typingIdleTimer?.cancel();
      unawaited(_setTyping(false));
      return;
    }

    // Mark typing immediately (throttled), then clear it after a short idle window.
    unawaited(_setTyping(true));

    _typingIdleTimer?.cancel();
    _typingIdleTimer = Timer(const Duration(seconds: 2), () {
      unawaited(_setTyping(false));
    });
  }

  Future<void> _setTyping(bool typing) async {
    if (!_typingChannelEnabled) {
      _isTyping = false;
      return;
    }
    final channel = _typingChannel;
    final userId = _presenceUserId;
    if (channel == null || userId == null) {
      _isTyping = false;
      return;
    }

    final nowUtc = DateTime.now().toUtc();

    if (_isTyping == typing) {
      // Keep `typing_at` fresh while typing so other clients can treat it as
      // "live" and not get stuck if we never send an explicit `typing=false`.
      if (!typing) return;
      final last = _lastTypingTrackUtc;
      if (last != null &&
          nowUtc.difference(last) < const Duration(milliseconds: 900)) {
        return;
      }
    } else {
      _isTyping = typing;
    }

    try {
      _lastTypingTrackUtc = nowUtc;
      await channel.track(<String, dynamic>{
        'user_id': userId,
        'typing': typing,
        'typing_at': nowUtc.toIso8601String(),
      });
    } catch (error, stackTrace) {
      AppLogger.error('groupChat.typing.track', error, stackTrace);
    }
  }

  void _syncTypingChannel({
    required bool enabled,
    required String? userId,
  }) {
    if (_typingChannelEnabled == enabled && _presenceUserId == userId) return;

    _typingChannelEnabled = enabled;
    _presenceUserId = userId;

    // Defer to end of frame so we don't mutate channels while building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_applyTypingChannel(enabled: enabled, userId: userId));
    });
  }

  Future<void> _applyTypingChannel({
    required bool enabled,
    required String? userId,
  }) async {
    if (!enabled || userId == null) {
      _typingIdleTimer?.cancel();
      await _setTyping(false);
      await _stopTypingChannel();
      if (mounted && _typingUserIds.isNotEmpty) {
        setState(_typingUserIds.clear);
      }
      return;
    }

    if (_typingChannel == null) {
      final channel = _client.channel(
        'group_typing:${widget.groupId}',
        opts: RealtimeChannelConfig(key: userId),
      );

      void refreshPresence() {
        if (!mounted) return;
        final currentUserId = _presenceUserId;
        if (currentUserId == null) return;
        final next = <String>{};

        DateTime? parseTypingAt(dynamic raw) {
          if (raw is DateTime) return raw.toUtc();
          if (raw is String && raw.isNotEmpty) {
            try {
              return DateTime.parse(raw).toUtc();
            } catch (_) {
              return null;
            }
          }
          return null;
        }

        final nowUtc = DateTime.now().toUtc();

        for (final state in channel.presenceState()) {
          for (final presence in state.presences) {
            final payload = presence.payload;
            final otherUserId = payload['user_id']?.toString();
            if (otherUserId == null ||
                otherUserId.isEmpty ||
                otherUserId == currentUserId) {
              continue;
            }
            final typing = payload['typing'] == true;
            if (!typing) continue;

            final typingAt = parseTypingAt(payload['typing_at']);
            if (typingAt != null &&
                nowUtc.difference(typingAt) > const Duration(seconds: 6)) {
              continue;
            }

            next.add(otherUserId);
          }
        }

        if (_setsEqual(_typingUserIds, next)) return;
        setState(() {
          _typingUserIds
            ..clear()
            ..addAll(next);
        });
      }

      _typingChannel = channel
          .onPresenceSync((_) => refreshPresence())
          .onPresenceJoin((_) => refreshPresence())
          .onPresenceLeave((_) => refreshPresence())
          .subscribe((status, [error]) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          try {
            final currentUserId = _presenceUserId;
            if (currentUserId == null) return;
            await channel.track(<String, dynamic>{
              'user_id': currentUserId,
              'typing': false,
              'typing_at': DateTime.now().toUtc().toIso8601String(),
            });
          } catch (e, st) {
            AppLogger.error('groupChat.typing.subscribe', e, st);
          }
          refreshPresence();
        }
      });
    } else {
      // Ensure our presence is tracked with the latest userId.
      _typingIdleTimer?.cancel();
      _isTyping = false;
      final channel = _typingChannel;
      if (channel == null) return;
      try {
        await channel.track(<String, dynamic>{
          'user_id': userId,
          'typing': false,
          'typing_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (error, stackTrace) {
        AppLogger.error('groupChat.typing.track', error, stackTrace);
      }
    }
  }

  Future<void> _stopTypingChannel() async {
    final channel = _typingChannel;
    if (channel == null) return;
    _typingChannel = null;
    try {
      await channel.untrack();
    } catch (_) {}
    try {
      await _client.removeChannel(channel);
    } catch (_) {}
  }

  static bool _setsEqual(Set<String> a, Set<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }

  static String _typingLabel(List<String> names) {
    if (names.isEmpty) return '';
    if (names.length == 1) return '${names[0]} is typing';
    if (names.length == 2) return '${names[0]} and ${names[1]} are typing';
    return '${names[0]} and ${names.length - 1} others are typing';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final groupAsync = ref.watch(groupProvider(widget.groupId));
    final joinedAsync = ref.watch(userChallengesProvider);

    final isJoined = joinedAsync.asData?.value
            .any((item) => item.challengeId == widget.groupId) ??
        false;
    final messagesAsync = isJoined
        ? ref.watch(groupMessagesProvider(widget.groupId))
        : const AsyncValue<List<GroupMessage>>.data(<GroupMessage>[]);

    // Mark messages as seen whenever the latest message changes.
    // Only subscribe once the user is a member; otherwise RLS may return an
    // empty initial snapshot, and the stream can stay empty until new inserts.
    if (isJoined) {
      ref.listen<AsyncValue<List<GroupMessage>>>(
        groupMessagesProvider(widget.groupId),
        (previous, next) {
          final session = ref.read(sessionProvider);
          final messages = next.asData?.value;
          if (session == null || messages == null || messages.isEmpty) return;
          final latestUtc = messages.first.createdAt.toUtc();
          if (_lastSeenUtc != null && !latestUtc.isAfter(_lastSeenUtc!)) return;
          _lastSeenUtc = latestUtc;
          unawaited(_markSeen(
            userId: session.user.id,
            seenAt: latestUtc,
          ));
        },
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSend = isJoined && session != null && !_sending && _hasText;

    _syncTypingChannel(
      enabled: isJoined && session != null,
      userId: session?.user.id,
    );

    final typingNames =
        _typingUserIds.map(anonymousNameFor).toList(growable: false)..sort();

    return Scaffold(
      backgroundColor: _ChatColors.bgTop(context),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _ChatColors.textPrimary(context),
        title: groupAsync.maybeWhen(
          data: (group) {
            final title = group?.title ?? 'Group chat';
            final members = group?.memberCount ?? 0;
            final muted = _ChatColors.muted(context);
            final subtitleStyle =
                Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: muted,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ) ??
                    TextStyle(
                      color: muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.1,
                    );

            final subtitle = (isJoined && typingNames.isNotEmpty)
                ? Row(
                    key: const ValueKey('typing'),
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          _typingLabel(typingNames),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _TypingDots(color: muted),
                    ],
                  )
                : Text(
                    members == 1 ? '1 member' : '$members members',
                    key: const ValueKey('members'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                DefaultTextStyle(
                  style: subtitleStyle,
                  child: AnimatedSwitcher(
                    duration: AppMotion.fast,
                    switchInCurve: AppMotion.standard,
                    switchOutCurve: AppMotion.exit,
                    child: subtitle,
                  ),
                ),
              ],
            );
          },
          orElse: () => const Text('Group chat'),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    _ChatColors.bgTop(context),
                    _ChatColors.bgBottom(context),
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: _InfoCard(
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.shield_outlined,
                        color: _ChatColors.muted(context),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Anonymous group chat. No names. No personal info.',
                          style: TextStyle(
                            color: _ChatColors.textPrimary(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isJoined
                              ? TribeColors.green(context)
                                  .withValues(alpha: 0.14)
                              : TribeColors.chip(context),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isJoined
                                ? TribeColors.green(context)
                                    .withValues(alpha: 0.35)
                                : _ChatColors.cardBorder(context),
                          ),
                        ),
                        child: Text(
                          isJoined ? 'Member' : 'Join to chat',
                          style: TextStyle(
                            color: isJoined
                                ? TribeColors.green(context)
                                : _ChatColors.muted(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    if (!isJoined) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.lock_outline,
                                size: 42,
                                color: _ChatColors.muted(context)
                                    .withValues(alpha: 0.85),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Join this group to view the chat history.',
                                style: TextStyle(
                                  color: _ChatColors.muted(context),
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.forum_outlined,
                              size: 46,
                              color: _ChatColors.muted(context)
                                  .withValues(alpha: 0.8),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No messages yet.',
                              style:
                                  TextStyle(color: _ChatColors.muted(context)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Be the first to check in.',
                              style: TextStyle(
                                color: _ChatColors.muted(context)
                                    .withValues(alpha: 0.75),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final mine = session?.user.id == message.senderId;
                        return AnimatedReveal(
                          key: ValueKey('group_msg_${message.id}'),
                          duration: AppMotion.medium,
                          beginOffset: mine
                              ? const Offset(0.10, 0)
                              : const Offset(-0.10, 0),
                          beginScale: 0.985,
                          child: _Bubble(
                            message: message,
                            mine: mine,
                            onOpenAttachment:
                                message.isFile ? _handleOpenAttachment : null,
                            onDownloadAttachment:
                                message.isFile ? _openAttachment : null,
                            loadAttachmentBytes: _isImageAttachment(message)
                                ? _loadImagePreviewBytes
                                : null,
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _friendlyError(error),
                        style: TextStyle(color: _ChatColors.muted(context)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              if (session == null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Sign in to send messages.',
                      style: TextStyle(color: _ChatColors.muted(context)),
                    ),
                  ),
                )
              else if (!isJoined)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _ChatColors.accent(context),
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          await ref
                              .read(challengesRepositoryProvider)
                              .startChallenge(widget.groupId);
                          ref.invalidate(userChallengesProvider);
                          ref.invalidate(challengesProvider);
                          ref.invalidate(groupMessagesProvider(widget.groupId));
                          await NotificationService()
                              .refreshGroupChatSubscriptions();
                        },
                        child: const Text(
                          'Join group to chat',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                )
              else
                SafeArea(
                  top: false,
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _ChatColors.card(context)
                            .withValues(alpha: isDark ? 0.92 : 0.96),
                        borderRadius: BorderRadius.circular(22),
                        border:
                            Border.all(color: _ChatColors.cardBorder(context)),
                        boxShadow: isDark
                            ? null
                            : <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                      ),
                      child: Row(
                        children: <Widget>[
                          InkWell(
                            onTap: _sending ? null : _sendAttachment,
                            borderRadius: BorderRadius.circular(18),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              curve: Curves.easeOut,
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: _sending
                                    ? _ChatColors.field(context)
                                    : _ChatColors.card(context)
                                        .withValues(alpha: isDark ? 0.92 : 0.9),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: _ChatColors.cardBorder(context),
                                ),
                              ),
                              child: Center(
                                child: _sending
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _ChatColors.muted(context),
                                        ),
                                      )
                                    : Icon(
                                        Icons.attach_file_rounded,
                                        color: _ChatColors.muted(context),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              textInputAction: TextInputAction.send,
                              onChanged: (value) {
                                _handleComposerChanged(value);
                              },
                              onSubmitted: (_) {
                                if (canSend) _send();
                              },
                              style: TextStyle(
                                color: _ChatColors.textPrimary(context),
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Message…',
                                hintStyle: TextStyle(
                                    color: _ChatColors.muted(context)),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: canSend ? _send : null,
                            borderRadius: BorderRadius.circular(18),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              curve: Curves.easeOut,
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: canSend
                                    ? _ChatColors.accent(context)
                                    : _ChatColors.field(context),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: canSend
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withValues(alpha: 0.18)
                                      : _ChatColors.cardBorder(context),
                                ),
                              ),
                              child: Center(
                                child: _sending
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: canSend
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary
                                              : _ChatColors.muted(context),
                                        ),
                                      )
                                    : Icon(
                                        Icons.arrow_upward_rounded,
                                        color: canSend
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                            : _ChatColors.muted(context),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('relation \"public.group_messages\"') ||
        message.contains('group_messages')) {
      return 'Group chat backend is not set up yet.\n\n'
          'Run `supabase/schema.sql` in Supabase SQL Editor to create `group_messages` and policies.';
    }
    if (message.contains('violates row-level security policy') ||
        message.contains('permission denied')) {
      return 'Permission blocked by RLS.\n\nJoin the group first, and ensure RLS policies are installed.';
    }
    return 'Failed: $message';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ChatColors.card(context).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ChatColors.cardBorder(context)),
        boxShadow: isDark
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );
  }
}

enum _AttachmentAction {
  photoGallery,
  videoGallery,
  file,
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = _ChatColors.muted(context);
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _ChatColors.field(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _ChatColors.cardBorder(context)),
        ),
        child: Icon(icon, color: muted),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _ChatColors.textPrimary(context),
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: muted,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: muted),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots({
    required this.color,
  });

  final Color color;

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;

        double bounce(double phase) {
          final v = math.sin((t + phase) * math.pi * 2);
          return 0.55 + 0.45 * v.abs();
        }

        Widget dot(double phase) {
          return Transform.translate(
            offset: Offset(0, -2 * bounce(phase)),
            child: Opacity(
              opacity: 0.65 + 0.35 * bounce(phase),
              child: Container(
                width: 4.5,
                height: 4.5,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            dot(0.00),
            const SizedBox(width: 3),
            dot(0.18),
            const SizedBox(width: 3),
            dot(0.36),
          ],
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    this.onOpenAttachment,
    this.onDownloadAttachment,
    this.loadAttachmentBytes,
  });

  final GroupMessage message;
  final bool mine;
  final void Function(GroupMessage message)? onOpenAttachment;
  final void Function(GroupMessage message)? onDownloadAttachment;
  final Future<Uint8List> Function(GroupMessage message)? loadAttachmentBytes;

  static String _formatBytes(int bytes) {
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;
    if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)} GB';
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  static bool _isImage(String name, String? mime) {
    if (mime != null && mime.toLowerCase().startsWith('image/')) return true;
    final ext = name.split('.').last.toLowerCase();
    return <String>{'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'}
        .contains(ext);
  }

  static bool _isVideo(String name, String? mime) {
    if (mime != null && mime.toLowerCase().startsWith('video/')) return true;
    final ext = name.split('.').last.toLowerCase();
    return <String>{'mp4', 'mov', 'm4v', 'webm', 'mkv', 'avi'}
        .contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    final alias = anonymousNameFor(message.senderId);
    final time = Formatters.timeAgo(message.createdAt);
    final bubbleColor = mine
        ? _ChatColors.mineBubble(context)
        : _ChatColors.otherBubble(context);
    final onMine = Theme.of(context).colorScheme.onPrimary;
    final textColor = mine ? onMine : TribeColors.textPrimary(context);
    final attachmentName = message.attachmentName ?? '';
    final isImageAttachment =
        message.isFile && loadAttachmentBytes != null && _isImage(
          attachmentName,
          message.attachmentMime,
        );
    final isVideoAttachment = message.isFile && _isVideo(
      attachmentName,
      message.attachmentMime,
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(mine ? 18 : 4),
                bottomRight: Radius.circular(mine ? 4 : 18),
              ),
              border: Border.all(
                color: mine
                    ? onMine.withValues(alpha: 0.18)
                    : _ChatColors.cardBorder(context),
              ),
              boxShadow: Theme.of(context).brightness == Brightness.dark
                  ? null
                  : <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment:
                    mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: <Widget>[
                  if (!mine)
                    Text(
                      alias,
                      style: TextStyle(
                        color: _ChatColors.muted(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  if (!mine) const SizedBox(height: 4),
                  if (message.isFile)
                    isImageAttachment
                        ? _ImageAttachmentBubble(
                            message: message,
                            textColor: textColor,
                            mine: mine,
                            onOpen: onOpenAttachment == null
                                ? null
                                : () => onOpenAttachment!(message),
                            onDownload: onDownloadAttachment == null
                                ? null
                                : () => onDownloadAttachment!(message),
                            loadBytes: loadAttachmentBytes == null
                                ? null
                                : () => loadAttachmentBytes!(message),
                          )
                        : InkWell(
                            onTap: onOpenAttachment == null
                                ? null
                                : () => onOpenAttachment!(message),
                            borderRadius: BorderRadius.circular(14),
                            child: Ink(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: mine
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: 0.10)
                                    : Theme.of(context)
                                        .colorScheme
                                        .surface
                                        .withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: mine
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withValues(alpha: 0.18)
                                      : _ChatColors.cardBorder(context),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    _isVideo(attachmentName,
                                            message.attachmentMime)
                                        ? Icons.videocam_outlined
                                        : Icons.insert_drive_file_outlined,
                                    size: 20,
                                    color: textColor.withValues(alpha: 0.95),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          (message.attachmentName ??
                                                      message.content)
                                                  .trim()
                                                  .isEmpty
                                              ? isVideoAttachment
                                                  ? 'Video'
                                                  : 'Attachment'
                                              : (message.attachmentName ??
                                                      message.content)
                                                  .trim(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        if (message.content.trim().isNotEmpty &&
                                            message.attachmentName != null &&
                                            message.content.trim() !=
                                                message.attachmentName!
                                                    .trim())
                                          const SizedBox(height: 6),
                                        if (message.content.trim().isNotEmpty &&
                                            message.attachmentName != null &&
                                            message.content.trim() !=
                                                message.attachmentName!
                                                    .trim())
                                          Text(
                                            message.content.trim(),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: textColor.withValues(
                                                  alpha: 0.9),
                                              fontWeight: FontWeight.w700,
                                              height: 1.25,
                                            ),
                                          ),
                                        if (message.attachmentSize != null)
                                          const SizedBox(height: 2),
                                        if (message.attachmentSize != null)
                                          Text(
                                            _formatBytes(message.attachmentSize!),
                                            style: TextStyle(
                                              color: textColor.withValues(
                                                  alpha: 0.8),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 18,
                                    color: textColor.withValues(alpha: 0.9),
                                  ),
                                ],
                              ),
                            ),
                          )
                  else
                    Text(
                      message.content,
                      style: TextStyle(
                        color: textColor,
                        height: 1.32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: TextStyle(
                      color: mine
                          ? onMine.withValues(alpha: 0.75)
                          : _ChatColors.muted(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageAttachmentBubble extends StatelessWidget {
  const _ImageAttachmentBubble({
    required this.message,
    required this.textColor,
    required this.mine,
    this.onOpen,
    this.onDownload,
    this.loadBytes,
  });

  final GroupMessage message;
  final Color textColor;
  final bool mine;
  final VoidCallback? onOpen;
  final VoidCallback? onDownload;
  final Future<Uint8List> Function()? loadBytes;

  @override
  Widget build(BuildContext context) {
    final name = (message.attachmentName ?? '').trim();
    final caption = message.content.trim();
    final showCaption = caption.isNotEmpty && (name.isEmpty || caption != name);

    final borderColor = mine
        ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.18)
        : _ChatColors.cardBorder(context);

    Widget buildPreview() {
      final future = loadBytes?.call();
      if (future == null) {
        return Container(
          color: Colors.black.withValues(alpha: 0.12),
          alignment: Alignment.center,
          child: Icon(
            Icons.image_outlined,
            color: textColor.withValues(alpha: 0.8),
            size: 28,
          ),
        );
      }

      return FutureBuilder<Uint8List>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Container(
              color: Colors.black.withValues(alpha: 0.12),
              alignment: Alignment.center,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor.withValues(alpha: 0.85),
                ),
              ),
            );
          }

          final bytes = snapshot.data;
          if (snapshot.hasError || bytes == null) {
            return Container(
              color: Colors.black.withValues(alpha: 0.12),
              alignment: Alignment.center,
              child: Icon(
                Icons.broken_image_outlined,
                color: textColor.withValues(alpha: 0.85),
                size: 28,
              ),
            );
          }

          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        },
      );
    }

    final preview = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          buildPreview(),
          Positioned(
            right: 10,
            bottom: 10,
            child: Material(
              color: Colors.black.withValues(alpha: 0.45),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onDownload ?? onOpen,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.download_for_offline_outlined,
                    color: Colors.white.withValues(alpha: 0.92),
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: preview,
              ),
            ),
          ),
        ),
        if (showCaption) const SizedBox(height: 8),
        if (showCaption)
          Text(
            caption,
            style: TextStyle(
              color: textColor,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _ImageViewerScreen extends StatelessWidget {
  const _ImageViewerScreen({
    required this.title,
    required this.bytesFuture,
    required this.onDownload,
  });

  final String title;
  final Future<Uint8List> bytesFuture;
  final Future<void> Function() onDownload;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.2),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Download',
            onPressed: () async {
              await onDownload();
            },
            icon: const Icon(Icons.download_for_offline_outlined),
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<Uint8List>(
          future: bytesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator(
                color: Colors.white70,
              );
            }

            final bytes = snapshot.data;
            if (snapshot.hasError || bytes == null) {
              return Text(
                'Failed to load image.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w700,
                ),
              );
            }

            return InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            );
          },
        ),
      ),
    );
  }
}
