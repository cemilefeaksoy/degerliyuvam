import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/message.dart';
import '../../core/state/app_scope.dart';
import '../../shared/ui.dart';
import '../auth/login_screen.dart';
import 'conversation_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  Future<List<ConversationItem>>? _inboxFuture;
  int? _loadedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = AppScope.of(context).currentUser?.id;
    if (_loadedUserId == userId) return;
    _loadedUserId = userId;
    _inboxFuture = userId == null ? null : AppScope.of(context).api.inbox();
  }

  Future<void> _refresh() async {
    final controller = AppScope.of(context);
    if (controller.currentUser == null) return;
    final future = controller.api.inbox();
    setState(() => _inboxFuture = future);
    try {
      await future;
    } catch (_) {
      // FutureBuilder displays the retry state.
    }
    await controller.refreshSession();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    if (controller.currentUser == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 42),
                const SizedBox(height: 10),
                Text(
                  'Mesaj kutusunu görmek için giriş yapın',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('Giriş Yap'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FutureBuilder<List<ConversationItem>>(
      future: _inboxFuture,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <ConversationItem>[];
        return RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Mesajlar',
                    subtitle: 'Son konuşmalarınız ve okunmamış mesajlarınız.',
                    trailing: IconButton(
                      tooltip: 'Yenile',
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ),
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  items.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 42, color: Color(0xFFD6B367)),
                          const SizedBox(height: 12),
                          const Text(
                            'Mesajlar yüklenemedi',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFA9B3C8)),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: _refresh,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Tekrar Dene'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Henüz bir konuşmanız yok.')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final initial = item.partnerName.isNotEmpty
                          ? item.partnerName.substring(0, 1).toUpperCase()
                          : '?';
                      return GestureDetector(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ConversationScreen(
                                partnerId: item.partnerUserId,
                                partnerName: item.partnerName,
                              ),
                            ),
                          );
                          if (mounted) await _refresh();
                        },
                        child: GlassPanel(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFD6B367)
                                    .withValues(alpha: 0.18),
                                child: Text(initial,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.partnerName,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        Text(
                                          DateFormat('dd MMM HH:mm', 'tr')
                                              .format(
                                                  item.lastMessageAt.toLocal()),
                                          style: const TextStyle(
                                              color: Color(0xFFA9B3C8),
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.partnerRole,
                                      style: const TextStyle(
                                          color: Color(0xFFA9B3C8),
                                          fontSize: 12),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.lastFromMe
                                          ? 'Siz: ${item.lastMessage}'
                                          : item.lastMessage,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(height: 1.35),
                                    ),
                                  ],
                                ),
                              ),
                              if (item.unreadCount > 0) ...[
                                const SizedBox(width: 8),
                                Badge(label: Text('${item.unreadCount}')),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
