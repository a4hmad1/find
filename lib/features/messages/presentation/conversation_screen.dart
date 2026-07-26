import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../shared/models/message_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  XFile? _attachment;
  Uint8List? _attachmentPreview;
  bool _sending = false;
  bool _markedRead = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Marks the thread read once, after the first frame.
  ///
  /// Previously this fired from `initState` via `ref.read`, which ran before
  /// the widget was mounted and threw when the user was signed out.
  void _markReadOnce() {
    if (_markedRead || !ref.read(signedInProvider)) return;
    _markedRead = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref
            .read(messagesRepositoryProvider)
            .markRead(widget.conversationId);
        if (mounted) ref.invalidate(unreadNotificationsProvider);
      } on AppFailure {
        // Read receipts are not worth interrupting the user for.
      }
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 72,
      maxWidth: 1600,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _attachment = picked;
      _attachmentPreview = bytes;
    });
  }

  void _clearAttachment() {
    setState(() {
      _attachment = null;
      _attachmentPreview = null;
    });
  }

  Future<void> _send(ConversationModel conversation) async {
    final text = _messageController.text;
    if (text.trim().isEmpty && _attachment == null) return;

    setState(() => _sending = true);
    try {
      await ref
          .read(messagesRepositoryProvider)
          .sendMessage(
            conversation: conversation,
            body: text,
            image: _attachment,
          );
      if (!mounted) return;
      // Cleared only after the send succeeds, so a failure does not discard
      // what the user typed.
      _messageController.clear();
      _clearAttachment();
      ref.invalidate(conversationsProvider);
      _scrollToBottom();
    } on AppFailure catch (failure) {
      if (!mounted) return;
      showFailureSnackBar(context, failure, onRetry: () => _send(conversation));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(signedInProvider)) {
      return const AppScaffold(
        title: 'نامە',
        child: GuestModeView(
          title: 'نامەکان لە دۆخی میواندا داخراون',
          message:
              'دەتوانیت بابەتە گشتییەکان ببینیت، بەڵام گفتوگۆ پێویستی بە ناسنامەی پشتڕاستکراو هەیە.',
          icon: Icons.chat_bubble_outline_rounded,
        ),
      );
    }

    _markReadOnce();
    final conversation = ref.watch(conversationProvider(widget.conversationId));

    return conversation.when(
      loading: () =>
          const AppScaffold(title: 'نامە', child: LoadingSkeleton(count: 4)),
      error: (error, _) => AppScaffold(
        title: 'نامە',
        child: ErrorView.failure(
          AppFailure.from(error),
          onRetry: () =>
              ref.invalidate(conversationProvider(widget.conversationId)),
        ),
      ),
      data: (value) => Scaffold(
        appBar: AppBar(title: const Text('نامە')),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _MessageList(
                  conversationId: widget.conversationId,
                  scrollController: _scrollController,
                ),
              ),
              if (_attachmentPreview case final bytes?)
                _AttachmentPreview(bytes: bytes, onRemove: _clearAttachment),
              _Composer(
                controller: _messageController,
                sending: _sending,
                onPickImage: _pickImage,
                onSend: () => _send(value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageList extends ConsumerWidget {
  const _MessageList({
    required this.conversationId,
    required this.scrollController,
  });

  final String conversationId;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(conversationMessagesProvider(conversationId));
    final myId = ref
        .watch(currentProfileProvider)
        .maybeWhen(data: (profile) => profile?.id ?? '', orElse: () => '');

    return messages.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: LoadingSkeleton(count: 4),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: ErrorView.failure(
          AppFailure.from(error),
          onRetry: () =>
              ref.invalidate(conversationMessagesProvider(conversationId)),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            title: 'گفتوگۆ دەستپێبکە',
            message: 'زانیارییەکان بە ڕوونی بنووسە و بەڵگە داوابکە.',
            icon: Icons.chat_rounded,
          );
        }
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) => MessageBubble(
            message: items[index],
            mine: items[index].senderId == myId,
          ),
        );
      },
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.bytes, required this.onRemove});

  final Uint8List bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              bytes,
              width: 84,
              height: 84,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text('وێنەی بەڵگە ئامادەیە')),
          IconButton(
            tooltip: Ku.delete,
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onPickImage,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onPickImage;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton.filledTonal(
            tooltip: 'وێنە',
            onPressed: sending ? null : onPickImage,
            icon: const Icon(Icons.image_rounded),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(hintText: 'نامە بنووسە'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'ناردن',
            onPressed: sending ? null : onSend,
            icon: sending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
