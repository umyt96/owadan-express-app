import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../providers/locale_provider.dart';
import '../services/message_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/illustrated_empty_state.dart';
import '../widgets/skeleton.dart';
import 'product_detail_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _messageService = MessageService();
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage>? _messages;
  String? _error;
  bool _sending = false;

  /// Текст, который отправляется прямо сейчас: показываем его в чате сразу,
  /// чуть приглушённым, пока сервер не подтвердит.
  String? _pendingText;
  int _lastCount = 0;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _load(initial: true);
    // Пока экран открыт — тихо проверяем новые сообщения каждые 5 секунд,
    // чтобы ответ администратора появлялся сам, без ручного обновления.
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool initial = false}) async {
    try {
      final messages = await _messageService.getMessages();
      await _messageService.markAllAsSeen(messages);
      if (!mounted) return;
      final grew = messages.length != _lastCount;
      setState(() {
        _messages = messages;
        _error = null;
        _lastCount = messages.length;
      });
      // Чат всегда открывается на последнем сообщении и сам прокручивается,
      // когда приходит новое.
      if (grew) _scrollToBottom(animated: !initial);
    } catch (e) {
      if (!mounted) return;
      // Молча пропускаем ошибку фонового опроса — не хотим прерывать
      // человека, пока он печатает, назойливым сообщением об ошибке каждые
      // 5 секунд. Ошибку показываем только при самой первой загрузке.
      if (initial) setState(() => _error = e.toString());
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (animated) {
        _scroll.animateTo(end, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
      } else {
        _scroll.jumpTo(end);
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _pendingText = text;
    });
    _controller.clear();
    _scrollToBottom();
    try {
      await _messageService.sendMessage(text);
      await _load();
    } catch (e) {
      if (!mounted) return;
      // Не потеряли текст: возвращаем его в поле, чтобы отправить ещё раз.
      _controller.text = text;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _pendingText = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: GradientAppBar(
        title: Text(locale.t('messages')),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody(locale)),
          _Composer(
            controller: _controller,
            hint: locale.t('type_message_hint'),
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(LocaleProvider locale) {
    final messages = _messages;
    if (messages == null) {
      if (_error != null) {
        return Center(child: Text('${locale.t('error')}: $_error'));
      }
      return const _ChatSkeleton();
    }
    if (messages.isEmpty && _pendingText == null) {
      return IllustratedEmptyState(
        image: EmptyIllustrations.guest,
        title: locale.t('messages'),
        description: locale.t('chat_empty_hint'),
      );
    }

    final pending = _pendingText;
    final count = messages.length + (pending != null ? 1 : 0);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView.builder(
        controller: _scroll,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        itemCount: count,
        itemBuilder: (context, index) {
          // Последний элемент — ещё не подтверждённое сообщение.
          if (index >= messages.length) {
            return _MessageBlock(
              animate: true,
              children: [
                _Bubble(text: pending!, isMine: true, pending: true),
              ],
            );
          }
          final m = messages[index];
          final previous = index > 0 ? messages[index - 1] : null;
          final showDate = m.createdDate != null &&
              (previous?.createdDate == null || !_sameDay(previous!.createdDate!, m.createdDate!));

          return Column(
            children: [
              if (showDate) _DateChip(label: _dayLabel(locale, m.createdDate!)),
              _MessageBlock(
                // Появление анимируем только у свежих сообщений внизу, иначе
                // при прокрутке вверх-вниз пузыри "мигали" бы заново.
                animate: index >= messages.length - 3,
                children: [
                  // Товар, о котором вопрос — фото + название, как на сайте.
                  if (m.product != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _ProductChip(product: m.product!, language: locale.language),
                    ),
                  // Сообщение, начатое администратором, не имеет вопроса клиента.
                  if (!m.isFromAdmin)
                    _Bubble(
                      text: m.message,
                      isMine: true,
                      time: m.createdDate == null ? null : _time(m.createdDate!),
                    ),
                  if (m.answer != null) ...[
                    const SizedBox(height: 6),
                    _Bubble(
                      text: m.answer!,
                      isMine: false,
                      label: locale.t('administrator_label'),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) {
    final x = a.toLocal();
    final y = b.toLocal();
    return x.year == y.year && x.month == y.month && x.day == y.day;
  }

  static String _time(DateTime d) {
    final l = d.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  static String _dayLabel(LocaleProvider locale, DateTime d) {
    final now = DateTime.now();
    if (_sameDay(d, now)) return locale.t('chat_today');
    if (_sameDay(d, now.subtract(const Duration(days: 1)))) return locale.t('chat_yesterday');
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}.${l.month.toString().padLeft(2, '0')}.${l.year}';
  }
}

/// Один обмен репликами; свежие блоки мягко въезжают снизу.
class _MessageBlock extends StatelessWidget {
  final bool animate;
  final List<Widget> children;

  const _MessageBlock({required this.animate, required this.children});

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
    if (!animate || MediaQuery.disableAnimationsOf(context)) return content;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
      ),
      child: content,
    );
  }
}

/// Разделитель дней: "Сегодня", "Вчера" или дата.
class _DateChip extends StatelessWidget {
  final String label;

  const _DateChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.subtle,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(fontFamily: 'Gilroy', color: AppColors.bodyText, fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

/// Мини-карточка товара над сообщением — фото + название, нажатие ведёт на
/// страницу товара. Так понятно, к какому товару относится вопрос (как на
/// сайте), даже если открыть чат спустя долгое время.
class _ProductChip extends StatelessWidget {
  final MessageProduct product;
  final String language;

  const _ProductChip({required this.product, required this.language});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: AppColors.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.subtle),
        ),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: product.slug)),
          ),
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding: const EdgeInsets.all(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: product.image != null
                        ? Image.network(
                            product.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => ColoredBox(color: AppColors.subtle),
                          )
                        : ColoredBox(color: AppColors.subtle),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    product.titleFor(language),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      color: AppColors.headingText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 16, color: AppColors.bodyText),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Пузырь сообщения. Свои — сплошным акцентным цветом справа, ответ
/// администратора — на светлой плитке слева с кружком-аватаром. Угол у
/// "хвостика" острее остальных.
class _Bubble extends StatelessWidget {
  final String text;
  final bool isMine;
  final String? label;
  final String? time;
  final bool pending;

  const _Bubble({
    required this.text,
    required this.isMine,
    this.label,
    this.time,
    this.pending = false,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.74;
    const big = Radius.circular(18);
    const tail = Radius.circular(5);

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: BoxDecoration(
        color: isMine ? AppColors.accent : AppColors.card,
        borderRadius: BorderRadius.only(
          topLeft: big,
          topRight: big,
          bottomLeft: isMine ? big : tail,
          bottomRight: isMine ? tail : big,
        ),
        border: isMine ? null : Border.all(color: AppColors.subtle),
        boxShadow: [
          BoxShadow(
            color: (isMine ? AppColors.accent : AppColors.gradientEnd).withOpacity(isMine ? 0.20 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: const TextStyle(fontFamily: 'Gilroy', color: AppColors.accent, fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Gilroy',
              color: isMine ? Colors.white : AppColors.headingText,
              fontSize: 15,
              height: 1.3,
            ),
          ),
          if (time != null || pending) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pending)
                    const HugeIcon(icon: HugeIcons.strokeRoundedClock01, size: 12, color: Colors.white70)
                  else
                    Text(
                      time!,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        color: isMine ? Colors.white.withOpacity(0.8) : AppColors.bodyText,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    final row = Row(
      mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMine) ...[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.14), shape: BoxShape.circle),
            child: const Center(
              child: HugeIcon(icon: HugeIcons.strokeRoundedCustomerSupport, size: 16, color: AppColors.accent),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(child: bubble),
      ],
    );
    return pending ? Opacity(opacity: 0.7, child: row) : row;
  }
}

/// Поле ввода внизу: округлая капсула (до четырёх строк) и круглая кнопка
/// отправки. Кнопка серая, пока поле пусто; при отправке — индикатор.
class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool sending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.hint,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    final active = hasText && !sending;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.subtle)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.subtle,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    cursorColor: AppColors.accent,
                    style: TextStyle(fontFamily: 'Gilroy', color: AppColors.headingText, fontSize: 15.5),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(fontFamily: 'Gilroy', color: AppColors.bodyText, fontSize: 15.5),
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedScale(
                scale: active ? 1 : 0.92,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: active || sending ? AppColors.accent : AppColors.subtle,
                    shape: BoxShape.circle,
                    boxShadow: active
                        ? [BoxShadow(color: AppColors.accent.withOpacity(0.30), blurRadius: 12, offset: const Offset(0, 4))]
                        : const [],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: active ? onSend : null,
                      child: Center(
                        child: sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                              )
                            : HugeIcon(
                                icon: HugeIcons.strokeRoundedSent,
                                size: 22,
                                color: active ? Colors.white : AppColors.bodyText,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Заглушка загрузки чата: пузыри слева и справа разной ширины.
class _ChatSkeleton extends StatelessWidget {
  const _ChatSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bubble(double width, bool mine) => Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: SkeletonBox(width: width, height: 52, radius: 18),
        );
    return SkeletonPulse(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        children: [
          bubble(210, true),
          const SizedBox(height: 12),
          bubble(250, false),
          const SizedBox(height: 12),
          bubble(150, true),
          const SizedBox(height: 12),
          bubble(230, false),
        ],
      ),
    );
  }
}
