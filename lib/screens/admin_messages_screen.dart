import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../providers/locale_provider.dart';
import '../services/admin_chat_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_app_bar.dart';
import 'product_detail_screen.dart';

/// Раздел "Сообщения клиентов" (модель SendAdmin на сайте) — только для
/// суперпользователя: читать все сообщения, отвечать, писать одному клиенту
/// или всем сразу. Список сам обновляется каждые 10 секунд.
class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    AdminChatService().markAllRead();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _compose() async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ComposeSheet(),
    );
    if (sent == true && mounted) {
      final locale = context.read<LocaleProvider>();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locale.t('message_sent'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: GradientAppBar(
        title: Text(locale.t('client_messages')),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: locale.t('all_messages')),
            Tab(text: locale.t('unanswered')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gradientEnd,
        foregroundColor: Colors.white,
        onPressed: _compose,
        icon: const HugeIcon(icon: HugeIcons.strokeRoundedEdit02),
        label: Text(locale.t('write_message')),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _MessagesList(unansweredOnly: false),
          _MessagesList(unansweredOnly: true),
        ],
      ),
    );
  }
}

class _MessagesList extends StatefulWidget {
  final bool unansweredOnly;

  const _MessagesList({required this.unansweredOnly});

  @override
  State<_MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends State<_MessagesList> with AutomaticKeepAliveClientMixin {
  final _service = AdminChatService();
  final List<ChatMessage> _items = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  Timer? _poll;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    // Тихо проверяем новые сообщения, пока экран открыт.
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _refreshFirstPage());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _items.clear();
      }
    });
    try {
      final result = await _service.getMessages(page: _page, unansweredOnly: widget.unansweredOnly);
      if (!mounted) return;
      setState(() {
        _items.addAll(result.items);
        _hasMore = result.hasMore;
        _page++;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Обновляет только первую страницу (новые сообщения сверху), не сбрасывая
  /// уже подгруженный список и позицию прокрутки.
  Future<void> _refreshFirstPage() async {
    if (_loading) return;
    try {
      final result = await _service.getMessages(page: 1, unansweredOnly: widget.unansweredOnly);
      if (!mounted) return;
      setState(() {
        final fresh = {for (final m in result.items) m.id: m};
        for (var i = 0; i < _items.length; i++) {
          final updated = fresh.remove(_items[i].id);
          if (updated != null) _items[i] = updated;
        }
        _items.insertAll(0, fresh.values);
        if (widget.unansweredOnly) {
          _items.removeWhere((m) => m.answer != null);
        }
      });
    } catch (_) {}
  }

  Future<void> _reply(ChatMessage msg) async {
    final locale = context.read<LocaleProvider>();
    final controller = TextEditingController(text: msg.answer ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${locale.t('reply_to')} ${msg.username ?? ''}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isFromAdmin)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.subtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(msg.message, style: const TextStyle(fontSize: 13)),
              ),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(hintText: locale.t('type_message_hint')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(locale.t('cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(locale.t('send')),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;
    try {
      final updated = await _service.reply(msg.id, text);
      if (!mounted) return;
      setState(() {
        final i = _items.indexWhere((m) => m.id == msg.id);
        if (widget.unansweredOnly) {
          if (i != -1) _items.removeAt(i);
        } else if (i != -1) {
          _items[i] = updated;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    final local = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final locale = context.watch<LocaleProvider>();

    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty && _error != null) {
      return Center(child: Text('${locale.t('error')}: $_error'));
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: _items.isEmpty
          ? ListView(children: [
              const SizedBox(height: 120),
              Center(child: Text(locale.t('nothing_found'))),
            ])
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: _items.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _items.length) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _load());
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final m = _items[index];
                return _MessageCard(
                  message: m,
                  date: _formatDate(m.createdDate),
                  language: locale.language,
                  onReply: () => _reply(m),
                );
              },
            ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final ChatMessage message;
  final String date;
  final String language;
  final VoidCallback onReply;

  const _MessageCard({
    required this.message,
    required this.date,
    required this.language,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final m = message;
    final unanswered = m.answer == null && !m.isFromAdmin;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: unanswered ? const BorderSide(color: AppColors.accent, width: 1.4) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                  child: Text(
                    (m.username ?? '?').isNotEmpty ? m.username![0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(m.username ?? '—', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (unanswered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(locale.t('new_badge'), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(width: 6),
                Text(date, style: TextStyle(fontSize: 11, color: AppColors.bodyText)),
              ],
            ),
            if (m.product != null) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: m.product!.slug)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: m.product!.image != null ? Image.network(m.product!.image!, fit: BoxFit.cover) : Container(color: AppColors.subtle),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        m.product!.titleFor(language),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!m.isFromAdmin) ...[
              const SizedBox(height: 8),
              Text(m.message),
            ],
            if (m.answer != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(locale.t('administrator_label'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent)),
                    const SizedBox(height: 2),
                    Text(m.answer!),
                  ],
                ),
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onReply,
                icon: HugeIcon(icon: m.answer == null ? HugeIcons.strokeRoundedReply : HugeIcons.strokeRoundedEdit02, size: 18),
                label: Text(m.answer == null ? locale.t('reply') : locale.t('edit_reply')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Нижняя панель "Написать": одному клиенту (с поиском) или всем сразу.
class _ComposeSheet extends StatefulWidget {
  const _ComposeSheet();

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  final _service = AdminChatService();
  final _searchController = TextEditingController();
  final _messageController = TextEditingController();
  bool _toAll = false;
  ChatUser? _recipient;
  List<ChatUser> _results = [];
  bool _searching = false;
  bool _sending = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (value.trim().isEmpty) {
        setState(() => _results = []);
        return;
      }
      setState(() => _searching = true);
      try {
        final users = await _service.searchUsers(value.trim());
        if (mounted) setState(() => _results = users);
      } catch (_) {
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  Future<void> _send() async {
    final locale = context.read<LocaleProvider>();
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    if (!_toAll && _recipient == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locale.t('choose_recipient'))));
      return;
    }
    if (_toAll) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(locale.t('send_to_all')),
          content: Text(locale.t('send_to_all_confirm')),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(locale.t('cancel'))),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(locale.t('send'))),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _sending = true);
    try {
      await _service.send(text, userId: _toAll ? null : _recipient!.id, toAll: _toAll);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locale.t('write_message'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, icon: const HugeIcon(icon: HugeIcons.strokeRoundedUser), label: Text(locale.t('one_client'))),
                ButtonSegment(value: true, icon: const HugeIcon(icon: HugeIcons.strokeRoundedUserGroup), label: Text(locale.t('all_clients'))),
              ],
              selected: {_toAll},
              onSelectionChanged: (v) => setState(() => _toAll = v.first),
            ),
            const SizedBox(height: 12),
            if (!_toAll) ...[
              if (_recipient != null)
                Chip(
                  avatar: const HugeIcon(icon: HugeIcons.strokeRoundedUser, size: 18),
                  label: Text(_recipient!.label),
                  onDeleted: () => setState(() => _recipient = null),
                )
              else ...[
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    labelText: locale.t('search_client'),
                    prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedSearch01),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : null,
                  ),
                ),
                if (_results.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView(
                      shrinkWrap: true,
                      children: _results
                          .map((u) => ListTile(
                                dense: true,
                                leading: const HugeIcon(icon: HugeIcons.strokeRoundedUser),
                                title: Text(u.label),
                                subtitle: u.email.isNotEmpty ? Text(u.email) : null,
                                onTap: () => setState(() {
                                  _recipient = u;
                                  _results = [];
                                  _searchController.clear();
                                }),
                              ))
                          .toList(),
                    ),
                  ),
              ],
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _messageController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(labelText: locale.t('message')),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _send,
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedSend),
                label: Text(_sending ? locale.t('sending') : locale.t('send')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
