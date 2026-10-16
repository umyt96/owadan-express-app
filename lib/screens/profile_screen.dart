import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../services/checkout_service.dart';
import '../services/catalog_service.dart' show PaginatedResult;
import '../models/order.dart';
import '../theme/app_theme.dart';
import '../theme/theme_reveal.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/guest_login_button.dart';
import '../widgets/language_dialog.dart';
import '../widgets/app_bottom_nav.dart' show currentTabIndex;
import 'about_screen.dart';
import 'admin_catalog_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_refunds_screen.dart';
import 'admin_messages_screen.dart';
import 'admin_reviews_screen.dart';
import 'manage_products_screen.dart';
import '../services/admin_chat_service.dart';
import 'change_password_screen.dart';
import 'contact_us_screen.dart';
import 'edit_profile_screen.dart';
import 'how_to_order_screen.dart';
import 'login_screen.dart';
import 'messages_screen.dart';
import '../services/message_service.dart';
import 'orders_screen.dart';
import 'return_item_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final locale = context.read<LocaleProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale.t('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(locale.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(locale.t('logout')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final cart = context.read<CartProvider>();
    await context.read<AuthProvider>().logout();
    cart.clearLocal();
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final locale = context.read<LocaleProvider>();
    final picked = await showLanguageDialog(
      context,
      title: locale.t('language'),
      current: locale.language,
    );
    if (picked != null) await locale.setLanguage(picked);
  }

  void _open(BuildContext context, Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>();
    final isGuest = auth.status != AuthStatus.authenticated;
    final user = auth.currentUser;

    // "Товары" — персонал (is_staff) и суперпользователь; остальное
    // управление — только суперпользователь. Обычные пользователи не видят
    // не просто контент, а сам раздел.
    final canManageProducts = user?.canManageProducts == true;
    final isSuperuser = user?.isSuperuser == true;

    return Scaffold(
      appBar: GradientAppBar(title: Text(locale.t('nav_profile'))),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 28),
        children: [
          if (isGuest) _GuestHeader(locale: locale) else _UserHeader(auth: auth),
          const SizedBox(height: 22),
          if (!isGuest)
            _MenuGroup(
              title: locale.t('section_account'),
              children: [
                _MenuItem(
                  icon: HugeIcons.strokeRoundedEdit02,
                  label: locale.t('edit_profile'),
                  onTap: () => _open(context, const EditProfileScreen()),
                ),
                _MenuItem(
                  icon: HugeIcons.strokeRoundedReceiptText,
                  label: locale.t('order_history'),
                  onTap: () => _open(context, const OrdersScreen()),
                ),
                const _MessagesMenuItem(),
                _MenuItem(
                  icon: HugeIcons.strokeRoundedReturnRequest,
                  label: locale.t('return_item'),
                  onTap: () => _open(context, const ReturnItemScreen()),
                ),
                _MenuItem(
                  icon: HugeIcons.strokeRoundedSquareLock01,
                  label: locale.t('change_password'),
                  onTap: () => _open(context, const ChangePasswordScreen()),
                ),
              ],
            ),
          if (!isGuest && (canManageProducts || isSuperuser))
            _MenuGroup(
              title: locale.t('section_admin'),
              children: [
                if (canManageProducts)
                  _MenuItem(
                    icon: HugeIcons.strokeRoundedPackage01,
                    label: locale.t('manage_products'),
                    onTap: () => _open(context, const ManageProductsScreen()),
                  ),
                if (isSuperuser) ...[
                  _MenuItem(
                    icon: HugeIcons.strokeRoundedShieldUser,
                    label: locale.t('admin_orders'),
                    onTap: () => _open(context, const AdminOrdersScreen()),
                  ),
                  _MenuItem(
                    icon: HugeIcons.strokeRoundedReturnRequest,
                    label: locale.t('refunds'),
                    onTap: () => _open(context, const AdminRefundsScreen()),
                  ),
                  const _AdminMessagesMenuItem(),
                  _MenuItem(
                    icon: HugeIcons.strokeRoundedStar,
                    label: locale.t('admin_reviews'),
                    onTap: () => _open(context, const AdminReviewsScreen()),
                  ),
                  // Справочники сайта — только суперпользователь
                  // (купоны, контакты, категории, подкатегории, бренды, валюта).
                  for (final s in const [
                    ('coupons', 'coupons', HugeIcons.strokeRoundedSaleTag01),
                    ('contacts', 'contacts_admin', HugeIcons.strokeRoundedContactBook),
                    ('categories', 'categories_admin', HugeIcons.strokeRoundedGridView),
                    ('subcategories', 'subcategories_admin', HugeIcons.strokeRoundedHierarchySquare01),
                    ('brands', 'brands_admin', HugeIcons.strokeRoundedTag01),
                    ('currency', 'currency_admin', HugeIcons.strokeRoundedMoneyExchange01),
                  ])
                    _MenuItem(
                      icon: s.$3,
                      label: locale.t(s.$2),
                      onTap: () => _open(
                        context,
                        AdminCatalogScreen(section: s.$1, titleKey: s.$2, icon: s.$3),
                      ),
                    ),
                ],
              ],
            ),
          _MenuGroup(
            title: locale.t('section_help'),
            children: [
              _MenuItem(
                icon: HugeIcons.strokeRoundedCustomerSupport,
                label: locale.t('contact_us'),
                onTap: () => _open(context, const ContactUsScreen()),
              ),
              _MenuItem(
                icon: HugeIcons.strokeRoundedInformationCircle,
                label: locale.t('about_us'),
                onTap: () => _open(context, const AboutScreen()),
              ),
              _MenuItem(
                icon: HugeIcons.strokeRoundedShoppingBag01,
                label: locale.t('how_to_order'),
                onTap: () => _open(context, const HowToOrderScreen()),
              ),
            ],
          ),
          _MenuGroup(
            title: locale.t('section_preferences'),
            children: [
              _MenuItem(
                icon: HugeIcons.strokeRoundedLanguageCircle,
                label: locale.t('language'),
                trailing: LanguageFlag(code: locale.language),
                onTap: () => _pickLanguage(context),
              ),
              const _DarkModeItem(),
            ],
          ),
          if (!isGuest)
            _LogoutButton(
              label: locale.t('logout'),
              onTap: () => _logout(context),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Шапка профиля
// ---------------------------------------------------------------------------

/// Плоская карточка шапки: тот же фон и скругление, что у групп меню.
class _SummaryCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.subtle),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              leading,
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.headingText, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.bodyText, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestHeader extends StatelessWidget {
  final LocaleProvider locale;

  const _GuestHeader({required this.locale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: AppColors.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.subtle),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: HugeIcon(icon: HugeIcons.strokeRoundedUser, color: AppColors.accent, size: 26),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locale.t('guest_title'),
                          style: TextStyle(fontFamily: 'Gilroy', color: AppColors.headingText, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          locale.t('guest_profile_hint'),
                          style: TextStyle(fontFamily: 'Gilroy', color: AppColors.bodyText, fontSize: 13, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              GuestLoginButton(
                label: locale.t('login_button'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Две карточки сверху: кто вошёл (→ редактирование профиля) и ярлык
/// на историю заказов со счётчиком.
class _UserHeader extends StatelessWidget {
  final AuthProvider auth;

  const _UserHeader({required this.auth});

  /// "Иван Петров" -> "ИП"; пусто, если взять буквы не из чего.
  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.take(2).map((w) => String.fromCharCode(w.runes.first).toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final user = auth.currentUser;
    final fullName = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
    final name = fullName.isNotEmpty ? fullName : (user?.username ?? '');
    final email = user?.email.trim() ?? '';
    final initials = _initials(name);

    void editProfile() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // IntrinsicHeight: обе карточки равны по высоте более высокой.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _SummaryCard(
                    onTap: editProfile,
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: initials.isEmpty
                            ? const HugeIcon(icon: HugeIcons.strokeRoundedUser, color: AppColors.accent, size: 22)
                            : Text(
                                initials,
                                style: TextStyle(color: AppColors.brand, fontSize: 17, fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                    title: name,
                    subtitle: email.isNotEmpty ? email : locale.t('edit_profile'),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: _OrdersSummaryCard()),
              ],
            ),
          ),
          // Без email невозможно восстановить пароль — предупреждаем и по
          // нажатию сразу ведём в "Редактировать профиль".
          if (user != null && email.isEmpty) ...[
            const SizedBox(height: 12),
            Material(
              color: AppColors.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: editProfile,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedInformationCircle, color: AppColors.danger, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          locale.t('no_email_warning'),
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const HugeIcon(icon: HugeIcons.strokeRoundedChevronRight, color: AppColors.danger, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Карточка "История заказов" со счётчиком — перезапрашивает число заказов
/// заново КАЖДЫЙ раз, когда вкладка "Профиль" становится активной (а не только
/// один раз при первом открытии приложения). Без этого после удаления/
/// оформления заказа на другом экране счётчик остался бы "старым", пока не
/// изменится что-то другое (вход/язык), заставляющее ProfileScreen
/// перестроиться.
class _OrdersSummaryCard extends StatefulWidget {
  const _OrdersSummaryCard();

  @override
  State<_OrdersSummaryCard> createState() => _OrdersSummaryCardState();
}

class _OrdersSummaryCardState extends State<_OrdersSummaryCard> {
  final _checkoutService = CheckoutService();
  late Future<PaginatedResult<AppOrder>> _future;

  static const _profileTabIndex = 4;

  @override
  void initState() {
    super.initState();
    _future = _checkoutService.getOrderHistory();
    currentTabIndex.addListener(_onTabChanged);
    ordersChangedTick.addListener(_refresh);
  }

  @override
  void dispose() {
    currentTabIndex.removeListener(_onTabChanged);
    ordersChangedTick.removeListener(_refresh);
    super.dispose();
  }

  void _onTabChanged() {
    if (currentTabIndex.value == _profileTabIndex && mounted) {
      _refresh();
    }
  }

  void _refresh() {
    if (!mounted) return;
    final future = _checkoutService.getOrderHistory();
    setState(() {
      _future = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return FutureBuilder<PaginatedResult<AppOrder>>(
      future: _future,
      builder: (context, snapshot) {
        final count = snapshot.data?.count;
        return _SummaryCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OrdersScreen()),
          ),
          leading: SizedBox(
            // Той же высоты, что аватар рядом, чтобы заголовки совпали.
            height: 44,
            child: Align(
              alignment: Alignment.centerLeft,
              child: HugeIcon(icon: HugeIcons.strokeRoundedPackageDelivered, color: AppColors.brand, size: 32),
            ),
          ),
          title: locale.t('order_history'),
          subtitle: count == null ? '' : '${locale.t('orders_total')}: $count',
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Группы меню
// ---------------------------------------------------------------------------

/// Карточка-секция: заголовок + строки меню, разделённые тонкой линией.
class _MenuGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _MenuGroup({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Divider(
          height: 1,
          thickness: 1,
          indent: 66,
          endIndent: 16,
          color: AppColors.subtle,
        ));
      }
      rows.add(children[i]);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 8),
              child: Text(
                title!,
                style: TextStyle(
                  color: AppColors.bodyText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gradientEnd.withValues(alpha: 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Material(
              color: AppColors.card,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppColors.subtle),
              ),
              child: Column(children: rows),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final List<List<dynamic>> icon;

  const _IconTile({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Center(child: HugeIcon(icon: icon, color: AppColors.brand, size: 21)),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;
  final int badgeCount;

  /// Replaces the chevron: a flag, a switch, a value.
  final Widget? trailing;

  const _MenuItem({required this.icon, required this.label, required this.onTap, this.badgeCount = 0, this.trailing});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _IconTile(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: AppColors.headingText, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            if (badgeCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(11)),
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                alignment: Alignment.center,
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
            ],
            trailing ?? HugeIcon(icon: HugeIcons.strokeRoundedChevronRight, color: AppColors.bodyText.withValues(alpha: 0.7), size: 18),
          ],
        ),
      ),
    );
  }
}

/// Ночной режим: строка с переключателем. Смена темы идёт через
/// [ThemeReveal] — старый экран уезжает, открывая новую тему.
class _DarkModeItem extends StatelessWidget {
  const _DarkModeItem();

  void _set(BuildContext context, bool on) {
    final theme = context.read<ThemeProvider>();
    if (theme.isDark == on) return;
    void change() => theme.setMode(on ? ThemeMode.dark : ThemeMode.light);
    final reveal = ThemeReveal.maybeOf(context);
    if (reveal == null) {
      change();
    } else {
      unawaited(reveal.run(
        change,
        direction: on ? ThemeRevealDirection.leftToRight : ThemeRevealDirection.rightToLeft,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final theme = context.watch<ThemeProvider>();
    return _MenuItem(
      icon: theme.isDark ? HugeIcons.strokeRoundedMoon02 : HugeIcons.strokeRoundedSun01,
      label: locale.t('dark_mode'),
      onTap: () => _set(context, !theme.isDark),
      trailing: CupertinoSwitch(
        value: theme.isDark,
        activeTrackColor: AppColors.accent,
        onChanged: (on) => _set(context, on),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LogoutButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: AppColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const HugeIcon(icon: HugeIcons.strokeRoundedLogout01, color: AppColors.danger, size: 20),
                const SizedBox(width: 10),
                Text(label, style: const TextStyle(color: AppColors.danger, fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Пункт меню "Сообщение" с бейджем непрочитанных — пересчитывает счётчик
/// при каждом возврате на вкладку "Профиль" И сразу, как только сообщения
/// отмечены прочитанными (см. messagesSeenTick в message_service.dart),
/// даже если возврат был обычной кнопкой "назад", а не переключением
/// вкладки.
class _MessagesMenuItem extends StatefulWidget {
  const _MessagesMenuItem();

  @override
  State<_MessagesMenuItem> createState() => _MessagesMenuItemState();
}

class _MessagesMenuItemState extends State<_MessagesMenuItem> {
  final _messageService = MessageService();
  late Future<int> _future;

  static const _profileTabIndex = 4;

  @override
  void initState() {
    super.initState();
    _future = _messageService.getUnreadCount();
    currentTabIndex.addListener(_onTabChanged);
    messagesSeenTick.addListener(_refresh);
  }

  @override
  void dispose() {
    currentTabIndex.removeListener(_onTabChanged);
    messagesSeenTick.removeListener(_refresh);
    super.dispose();
  }

  void _onTabChanged() {
    if (currentTabIndex.value == _profileTabIndex && mounted) {
      _refresh();
    }
  }

  void _refresh() {
    if (!mounted) return;
    final future = _messageService.getUnreadCount();
    setState(() {
      _future = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return FutureBuilder<int>(
      future: _future,
      builder: (context, snapshot) => _MenuItem(
        icon: HugeIcons.strokeRoundedMail01,
        label: locale.t('messages'),
        badgeCount: snapshot.data ?? 0,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MessagesScreen()),
        ),
      ),
    );
  }
}

/// "Сообщения клиентов" (только суперпользователь) — с бейджем числа
/// непрочитанных сообщений от клиентов. Обновляется при возврате на вкладку
/// "Профиль" и сразу после прочтения/ответа.
class _AdminMessagesMenuItem extends StatefulWidget {
  const _AdminMessagesMenuItem();

  @override
  State<_AdminMessagesMenuItem> createState() => _AdminMessagesMenuItemState();
}

class _AdminMessagesMenuItemState extends State<_AdminMessagesMenuItem> {
  final _service = AdminChatService();
  late Future<int> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.unreadCount();
    currentTabIndex.addListener(_onTabChanged);
    adminMessagesTick.addListener(_refresh);
  }

  @override
  void dispose() {
    currentTabIndex.removeListener(_onTabChanged);
    adminMessagesTick.removeListener(_refresh);
    super.dispose();
  }

  void _onTabChanged() {
    if (currentTabIndex.value == 4) _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    final future = _service.unreadCount();
    setState(() {
      _future = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return FutureBuilder<int>(
      future: _future,
      builder: (context, snapshot) => _MenuItem(
        icon: HugeIcons.strokeRoundedChatting01,
        label: locale.t('client_messages'),
        badgeCount: snapshot.data ?? 0,
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminMessagesScreen()),
          );
          _refresh();
        },
      ),
    );
  }
}
