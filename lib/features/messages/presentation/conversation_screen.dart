import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/providers.dart';
import '../../../shared/models/message_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  late Future<ConversationModel> _conversation;
  final _message = TextEditingController();
  XFile? _image;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    if (_canUseAccount()) {
      _conversation = ref
          .read(messagesRepositoryProvider)
          .conversationById(widget.conversationId);
      ref.read(messagesRepositoryProvider).markRead(widget.conversationId);
    } else {
      _conversation = Future.error(const FormatException('guest mode'));
    }
  }

  bool _canUseAccount() {
    if (!ref.read(supabaseConfiguredProvider)) return false;
    return ref.read(supabaseClientProvider).auth.currentUser != null;
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 72,
      maxWidth: 1600,
    );
    if (picked != null) setState(() => _image = picked);
  }

  Future<void> _send(ConversationModel conversation) async {
    setState(() => _sending = true);
    try {
      await ref
          .read(messagesRepositoryProvider)
          .sendMessage(
            conversation: conversation,
            body: _message.text,
            image: _image,
          );
      _message.clear();
      setState(() => _image = null);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ناردنی نامە سەرکەوتوو نەبوو')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(signedInProvider);
    if (!signedIn) {
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

    final profile = ref.watch(currentProfileProvider);
    return FutureBuilder<ConversationModel>(
      future: _conversation,
      builder: (context, conversationSnapshot) {
        if (!conversationSnapshot.hasData) {
          return const AppScaffold(
            title: 'نامە',
            child: LoadingSkeleton(count: 4),
          );
        }
        final conversation = conversationSnapshot.data!;
        return Scaffold(
          appBar: AppBar(title: const Text('نامە')),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<MessageModel>>(
                    stream: ref
                        .read(messagesRepositoryProvider)
                        .streamMessages(widget.conversationId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: LoadingSkeleton(count: 4),
                        );
                      }
                      final messages = snapshot.data!;
                      if (messages.isEmpty) {
                        return const EmptyState(
                          title: 'گفتوگۆ دەستپێبکە',
                          message:
                              'زانیارییەکان بە ڕوونی بنووسە و بەڵگە داوابکە.',
                          icon: Icons.chat_rounded,
                        );
                      }
                      final myId = profile.maybeWhen(
                        data: (value) => value?.id ?? '',
                        orElse: () => '',
                      );
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return MessageBubble(
                            message: message,
                            mine: message.senderId == myId,
                          );
                        },
                      );
                    },
                  ),
                ),
                if (_image != null)
                  FutureBuilder<Uint8List>(
                    future: _image!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      return Container(
                        height: 84,
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(
                                snapshot.data!,
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(child: Text('وێنەی بەڵگە ئامادەیە')),
                            IconButton(
                              onPressed: () => setState(() => _image = null),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'وێنە',
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image_rounded),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _message,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'نامە بنووسە',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'ناردن',
                        onPressed: _sending ? null : () => _send(conversation),
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
