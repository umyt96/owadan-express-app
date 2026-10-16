import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/order.dart';
import '../models/order_stats.dart';
import '../providers/locale_provider.dart';
import '../services/checkout_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_app_bar.dart';
import 'product_detail_screen.dart';

/// Раздел "Заказы" — список ВСЕХ заказов всех пользователей, как в
/// ордер-панели на сайте. Доступен только суперпользователю (пункт меню в
/// ProfileScreen скрыт для обычных пользователей).
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final _checkoutService = CheckoutService();
  late Future<OrderStats> _statsFuture;

  final List<AppOrder> _orders = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  /// Фильтр по клиенту: null — заказы всех клиентов.
  OrderCustomer? _customer;
  int? _filteredCount; // сколько заказов у выбранного клиента

  @override
  void initState() {
    super.initState();
    _statsFuture = _checkoutService.getOrderStats();
    _loadPage(reset: true);
    // Пришёл push о новом заказе (или заказ изменён на другом экране) —
    // обновляем список и статистику, не дожидаясь ручного обновления.
    ordersChangedTick.addListener(_onOrdersChanged);
  }

  @override
  void dispose() {
    ordersChangedTick.removeListener(_onOrdersChanged);
    super.dispose();
  }

  void _onOrdersChanged() {
    if (mounted && !_isLoading) _reload();
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _orders.clear();
      }
    });
    try {
      final result = await _checkoutService.getAllOrders(page: _page, userId: _customer?.id);
      setState(() {
        _filteredCount = result.count;
        _orders.addAll(result.results);
        _hasMore = result.next != null;
        _page++;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickCustomer() async {
    final picked = await showModalBottomSheet<OrderCustomer>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CustomerPickerSheet(),
    );
    if (picked == null || !mounted) return;
    setState(() => _customer = picked);
    _loadPage(reset: true);
  }

  void _clearCustomer() {
    setState(() => _customer = null);
    _loadPage(reset: true);
  }

  Future<void> _reload() async {
    final future = _checkoutService.getOrderStats();
    setState(() {
      _statsFuture = future;
    });
    await _loadPage(reset: true);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: GradientAppBar(title: Text(locale.t('all_orders'))),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: FutureBuilder<OrderStats>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  final stats = snapshot.data;
                  if (stats == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      height: 88,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _StatCard(label: locale.t('stat_today'), value: stats.today),
                          _StatCard(label: locale.t('stat_last_week'), value: stats.lastWeek),
                          _StatCard(label: locale.t('stat_this_month'), value: stats.thisMonth),
                          _StatCard(label: locale.t('stat_this_year'), value: stats.thisYear),
                          _StatCard(label: locale.t('stat_total'), value: stats.total),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickCustomer,
                        icon: const HugeIcon(icon: HugeIcons.strokeRoundedUserSearch01, size: 20),
                        label: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${locale.t('customer')}: ${_customer?.label ?? locale.t('all_messages')}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    if (_customer != null)
                      IconButton(
                        tooltip: locale.t('reset'),
                        icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01),
                        onPressed: _clearCustomer,
                      ),
                  ],
                ),
              ),
            ),
            if (_customer != null && _filteredCount != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    '${locale.t('found_count')}: $_filteredCount',
                    style: TextStyle(color: AppColors.bodyText, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            if (_orders.isEmpty && _isLoading) const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            if (_orders.isEmpty && _error != null)
              SliverFillRemaining(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(child: Text('${locale.t('error')}: $_error')),
                ),
              ),
            if (_orders.isEmpty && !_isLoading && _error == null) SliverFillRemaining(child: Center(child: Text(locale.t('no_orders_yet')))),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _orders.length) {
                      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPage());
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _AdminOrderCard(order: _orders[index], onChanged: _reload);
                  },
                  childCount: _orders.length + (_hasMore ? 1 : 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        gradient: AppColors.softGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.2),
          ),
          const SizedBox(height: 4),
          Text('$value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}

class _AdminOrderCard extends StatefulWidget {
  final AppOrder order;
  final VoidCallback onChanged;

  const _AdminOrderCard({required this.order, required this.onChanged});

  @override
  State<_AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends State<_AdminOrderCard> {
  final _checkoutService = CheckoutService();
  bool _busy = false;

  String _statusLabel(LocaleProvider locale, String status) {
    switch (status) {
      case 'pending':
        return locale.t('status_pending');
      case 'being_delivered':
        return locale.t('status_being_delivered');
      case 'received':
        return locale.t('status_received');
      case 'cancel':
      case 'cancelled':
        return locale.t('status_cancelled');
      case 'refunded':
        return locale.t('refund_arranged');
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'received':
        return AppColors.success;
      case 'cancel':
      case 'cancelled':
      case 'refunded':
        return AppColors.danger;
      case 'being_delivered':
        return AppColors.gold;
      default:
        return AppColors.bodyText;
    }
  }

  Future<void> _openEditDialog() async {
    final locale = context.read<LocaleProvider>();
    final order = widget.order;
    bool pending = order.pending ?? (order.status == 'pending');
    bool beingDelivered = order.beingDelivered ?? (order.status == 'being_delivered');
    bool received = order.received ?? (order.status == 'received');
    bool refundGranted = order.refundGranted ?? (order.status == 'refunded');
    bool cancel = order.cancel ?? (order.status == 'cancelled');
    final avansController = TextEditingController(text: order.avans?.toString() ?? '');
    final deliveryController = TextEditingController(text: order.costOfDelivery?.toString() ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(locale.t('edit_order_status_title')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: avansController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: '${locale.t('avans')} (00.00) TMT'),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: pending,
                  title: Text(locale.t('status_pending')),
                  onChanged: (v) => setDialogState(() => pending = v ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: beingDelivered,
                  title: Text(locale.t('status_being_delivered')),
                  onChanged: (v) => setDialogState(() => beingDelivered = v ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: received,
                  title: Text(locale.t('status_received')),
                  onChanged: (v) => setDialogState(() => received = v ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: refundGranted,
                  title: Text(locale.t('refund_reimbursed')),
                  onChanged: (v) => setDialogState(() => refundGranted = v ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: cancel,
                  title: Text(locale.t('cancel_order')),
                  onChanged: (v) => setDialogState(() => cancel = v ?? false),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: deliveryController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: '${locale.t('delivery_cost')} (00.00) TMT'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(locale.t('cancel'))),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(locale.t('edit'))),
          ],
        ),
      ),
    );

    if (saved != true) return;
    setState(() => _busy = true);
    try {
      await _checkoutService.updateOrder(
        orderId: order.id,
        pending: pending,
        beingDelivered: beingDelivered,
        received: received,
        refundGranted: refundGranted,
        cancel: cancel,
        avans: num.tryParse(avansController.text.trim()),
        costOfDelivery: num.tryParse(deliveryController.text.trim()),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.t('status_updated'))),
      );
      widget.onChanged();
      ordersChangedTick.value++;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final locale = context.read<LocaleProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale.t('delete_order')),
        content: Text(locale.t('delete_order_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(locale.t('cancel'))),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(locale.t('delete'), style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await _checkoutService.deleteOrderAsAdmin(widget.order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.t('order_deleted'))),
      );
      widget.onChanged();
      ordersChangedTick.value++;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _busy = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}-${two(date.month)}-${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final order = widget.order;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${locale.t('order_ref_code')}: ${order.refCode}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(locale, order.status),
                    style: TextStyle(color: _statusColor(order.status), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (order.username != null) Text('${locale.t('customer')}: ${order.username}', style: TextStyle(color: AppColors.bodyText)),
            Text(_formatDate(order.orderedDate), style: TextStyle(color: AppColors.bodyText, fontSize: 12)),
            if (order.shippingAddress != null) ...[
              const SizedBox(height: 6),
              Text(
                '${order.shippingAddress!.country}, ${order.shippingAddress!.streetAddress}'
                '${order.shippingAddress!.apartmentAddress?.isNotEmpty == true ? ', ${order.shippingAddress!.apartmentAddress}' : ''}',
                style: TextStyle(color: AppColors.headingText, fontSize: 13),
              ),
              Text(order.shippingAddress!.phone, style: TextStyle(color: AppColors.headingText, fontSize: 13)),
              // Клиент указал местоположение по GPS — открыть точку на карте.
              if (order.shippingAddress!.mapUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: InkWell(
                    onTap: () => launchUrl(Uri.parse(order.shippingAddress!.mapUrl), mode: LaunchMode.externalApplication),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(icon: HugeIcons.strokeRoundedMapPin, size: 16, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(locale.t('open_on_map'), style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
            ],
            if ((order.avans != null && order.avans! > 0) || (order.costOfDelivery != null && order.costOfDelivery! > 0)) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                children: [
                  if (order.avans != null && order.avans! > 0) Text('${locale.t('avans')}: ${order.avans} ТМТ', style: TextStyle(fontSize: 12, color: AppColors.bodyText)),
                  if (order.costOfDelivery != null && order.costOfDelivery! > 0)
                    Text('${locale.t('delivery_cost')}: ${order.costOfDelivery} ТМТ', style: TextStyle(fontSize: 12, color: AppColors.bodyText)),
                ],
              ),
            ],
            const Divider(height: 20),
            // Товары в заказе — фото, название, цвет, размер, количество, цена.
            // Нажатие на товар открывает его страницу.
            ...order.items.map((cartItem) => InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: cartItem.item.slug)),
                    ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: cartItem.item.image != null
                              ? Image.network(
                                  cartItem.item.image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: AppColors.subtle),
                                )
                              : Container(color: AppColors.subtle),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Text(
                          cartItem.item.titleFor(locale.language),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (cartItem.selectColor != null)
                        Expanded(
                          child: Text(cartItem.selectColor!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                        ),
                      if (cartItem.selectSize != null)
                        Expanded(
                          child: Text(cartItem.selectSize!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                        ),
                      Expanded(
                        child: Text(
                          '${locale.t('qty_short')}: ${cartItem.quantity}',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.bodyText),
                        ),
                      ),
                      Text(
                        '${cartItem.totalPrice ?? '-'} ТМТ',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ))),
            const Divider(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${locale.t('total')}: ${order.total ?? '-'} ТМТ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 20),
            if (_busy)
              const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openEditDialog,
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedEdit02, size: 18),
                      label: Text(locale.t('edit_order_status_title')),
                    ),
                  ),
                  IconButton(
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02, color: AppColors.danger),
                    onPressed: _delete,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Выбор клиента для фильтра: только клиенты с оформленными заказами,
/// с поиском по имени, логину, email и телефону.
class _CustomerPickerSheet extends StatefulWidget {
  const _CustomerPickerSheet();

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final _service = CheckoutService();
  final _controller = TextEditingController();
  Timer? _debounce;
  List<OrderCustomer>? _customers;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    try {
      final list = await _service.getOrderCustomers(search: query.trim());
      if (mounted) {
        setState(() {
          _customers = list;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}.${two(l.month)}.${l.year}';
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final customers = _customers;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _controller,
                  autofocus: false,
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    hintText: locale.t('search_client'),
                    prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedSearch01),
                    isDense: true,
                  ),
                ),
              ),
              Expanded(
                child: customers == null
                    ? Center(
                        child: _error != null ? Text('${locale.t('error')}: $_error') : const CircularProgressIndicator(),
                      )
                    : customers.isEmpty
                        ? Center(child: Text(locale.t('nothing_found')))
                        : ListView.separated(
                            itemCount: customers.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final c = customers[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                                  child: Text(
                                    c.username.isNotEmpty ? c.username[0].toUpperCase() : '?',
                                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(c.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                  [
                                    if (c.email.isNotEmpty) c.email,
                                    if (c.lastOrder != null) '${locale.t('last_order')}: ${_formatDate(c.lastOrder)}',
                                  ].join(' · '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.softGradient,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${c.ordersCount}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                onTap: () => Navigator.of(context).pop(c),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
