import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import '../../data/models/social.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../state/app_data_controller.dart';
import '../timeline/user_timeline_screen.dart';

/// Messenger — port of components/social/MessengerScreen.tsx.
/// Conversations/messages are client-owned lists (`PUT /sync/conversations`
/// and `/sync/messages`), exactly like the web.
class MessengerScreen extends ConsumerStatefulWidget {
  const MessengerScreen({super.key, this.initialFriend});
  final FriendUser? initialFriend;

  @override
  ConsumerState<MessengerScreen> createState() => _MessengerScreenState();
}

class _MessengerScreenState extends ConsumerState<MessengerScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    final f = widget.initialFriend;
    if (f != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final convs = ref.read(dataProvider).conversations;
        final existing = convs.where((c) => c.participant.id == f.id).firstOrNull;
        _openChat(existing ??
            Conversation(
              id: 'conv-${DateTime.now().millisecondsSinceEpoch}',
              participant: f,
              lastMessage: 'কথোপকথন শুরু হয়েছে',
              lastTimestamp: 'এইমাত্র',
              isRequest: false,
            ));
      });
    }
  }

  void _openChat(Conversation c) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChatScreen(conversation: c)));
  }

  @override
  Widget build(BuildContext context) {
    final convs = ref.watch(dataProvider.select((d) => d.conversations));
    final list = convs.where((c) => c.participant.name.toLowerCase().contains(_query.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('মেসেঞ্জার')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.search, size: 18), hintText: 'চ্যাট খুঁজুন...'),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.maroon,
            onRefresh: () => ref.read(appDataProvider.notifier).refresh(),
            child: list.isEmpty
                ? ListView(children: const [EmptyState(icon: LucideIcons.messageCircle, title: 'কোনো কথোপকথন নেই')])
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const Divider(indent: 76),
                    itemBuilder: (_, i) {
                      final c = list[i];
                      return ListTile(
                        onTap: () => _openChat(c),
                        leading: CountBadge(count: c.unreadCount, child: AppAvatar(c.participant.avatar, size: 48)),
                        title: Row(children: [
                          Expanded(
                            child: Text(c.participant.name,
                                style: ts(13.5, weight: c.unreadCount > 0 ? bold : semi), overflow: TextOverflow.ellipsis),
                          ),
                          Text(c.lastTimestamp, style: ts(10, color: AppColors.grey500)),
                        ]),
                        subtitle: Text(c.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ts(12, color: c.unreadCount > 0 ? AppColors.ink : AppColors.grey500)),
                      );
                    },
                  ),
          ),
        ),
      ]),
    );
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversation});
  final Conversation conversation;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Timer? _reply;

  Conversation get _conv => widget.conversation;

  @override
  void initState() {
    super.initState();
    // Mobile: opening a chat marks it read (web never resets unreadCount).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final convs = ref.read(dataProvider).conversations;
      if (convs.any((c) => c.id == _conv.id && c.unreadCount > 0)) {
        ref.read(appDataProvider.notifier).setConversations([
          for (final c in convs) c.id == _conv.id ? c.copyWith(unreadCount: 0) : c,
        ]);
      }
      _toBottom();
    });
  }

  @override
  void dispose() {
    _reply?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(_scroll.position.maxScrollExtent + 80, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final d = ref.read(dataProvider);
    final data = ref.read(appDataProvider.notifier);
    final msg = Message(
      id: 'm-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _conv.id,
      senderId: 'me',
      text: text,
      timestamp: 'এইমাত্র',
      status: 'sent',
    );
    data.setMessages([...d.messages, msg]);
    final exists = d.conversations.any((c) => c.id == _conv.id);
    data.setConversations([
      for (final c in d.conversations) c.id == _conv.id ? c.copyWith(lastMessage: text, lastTimestamp: 'এইমাত্র') : c,
      if (!exists) _conv.copyWith(lastMessage: text, lastTimestamp: 'এইমাত্র'),
    ]);
    _input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _toBottom());

    // Simulated automated reply demo (same text as the web).
    _reply?.cancel();
    _reply = Timer(const Duration(seconds: 2), () {
      final current = ref.read(dataProvider).messages;
      data.setMessages([
        ...current,
        Message(
          id: 'm-reply-${DateTime.now().millisecondsSinceEpoch}',
          conversationId: _conv.id,
          senderId: _conv.participant.id,
          text: 'ধন্যবাদ আপু! মেসেজটি পেয়েছি। (ডেমো অটো-রিপ্লাই)',
          timestamp: 'এইমাত্র',
          status: 'delivered',
        ),
      ]);
      if (mounted) WidgetsBinding.instance.addPostFrameCallback((_) => _toBottom());
    });
  }

  @override
  Widget build(BuildContext context) {
    final msgs = ref.watch(dataProvider.select((d) => d.messages.where((m) => m.conversationId == _conv.id).toList()));
    final p = _conv.participant;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () => context.push(Routes.timeline, extra: TimelineTarget.other(friend: p)),
          child: Row(children: [
            AppAvatar(p.avatar, size: 36, ring: false),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: ts(14, weight: bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                Text('সক্রিয় (ডেমো) • প্রোফাইল দেখুন', style: ts(10, color: AppColors.sand)),
              ]),
            ),
          ]),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(14),
            itemCount: msgs.length,
            itemBuilder: (_, i) {
              final m = msgs[i];
              return Align(
                alignment: m.isMine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: m.isMine ? AppColors.maroon : Colors.white,
                    border: m.isMine ? null : Border.all(color: AppColors.sand),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(m.isMine ? 16 : 4),
                      bottomRight: Radius.circular(m.isMine ? 4 : 16),
                    ),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    if (m.mediaUrl != null) ...[NetImage(m.mediaUrl, radius: 10, height: 160), const SizedBox(height: 6)],
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(m.text, style: ts(13, color: m.isMine ? Colors.white : AppColors.ink, height: 1.4)),
                    ),
                    const SizedBox(height: 3),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(toBnDigits(m.timestamp), style: ts(9.5, color: m.isMine ? AppColors.sand : AppColors.grey400)),
                      if (m.isMine) ...[
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.checkCheck, size: 12, color: AppColors.sand),
                      ],
                    ]),
                  ]),
                ),
              );
            },
          ),
        ),
        const Divider(),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 5000,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(hintText: 'মেসেজ লিখুন...', counterText: ''),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: AppColors.maroon),
                onPressed: _send,
                icon: const Icon(LucideIcons.send, size: 18, color: Colors.white),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
