import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/checkout_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/illustrated_empty_state.dart';
import 'product_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _checkoutService = CheckoutService();
  final List<AppOrder> _orders = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage(reset: true);
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
      final result = await _checkoutService.getOrderHistory(page: _page);
      setState(() {
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

  Future<void> _reload() => _loadPage(reset: true);

  @override
  Widget build(BuildContext context) {
    final username = context.watch<AuthProvider>().currentUser?.username ?? '';
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: GradientAppBar(title: Text(locale.t('order_history'))),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: _buildBody(locale, username),
      ),
    );
  }

  Widget _buildBody(LocaleProvider locale, String username) {
    if (_orders.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_orders.isEmpty && _error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(child: Text('${locale.t('error')}: $_error')),
        ],
      );
    }
    if (_orders.isEmpty && !_hasMore) {
      return IllustratedEmptyState(
        image: EmptyIllustrations.orders,
        title: locale.t('no_orders_yet'),
        description: locale.t('empty_orders_body'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _orders.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _loadPage());
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _OrderReceiptCard(
            order: _orders[index],
            number: index + 1,
            username: username,
          ),
        );
      },
    );
  }
}

class _OrderReceiptCard extends StatelessWidget {
  final AppOrder order;
  final int number;
  final String username;

  const _OrderReceiptCard({
    required this.order,
    required this.number,
    required this.username,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}-${two(date.month)}-${date.year} '
        '${two(date.hour)}:${two(date.minute)}:${two(date.second)}';
  }

  Future<void> _copyRefCode(BuildContext context, String refCode, LocaleProvider locale) async {
    await Clipboard.setData(ClipboardData(text: refCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(locale.t('code_copied'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final address = order.shippingAddress;
    final locale = context.watch<LocaleProvider>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // "Спасибо за ваш заказ, ..."
          Container(
            color: AppColors.subtle,
            padding: const EdgeInsets.all(12),
            child: Text.rich(
              TextSpan(
                style: TextStyle(color: AppColors.bodyText),
                children: [
                  TextSpan(text: locale.t('thank_you_for_order')),
                  TextSpan(
                    text: username,
                    style: const TextStyle(color: AppColors.accent),
                  ),
                  const TextSpan(text: '!'),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Номер + "Квитанция" + код заказа
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.gradientEnd,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$number',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(locale.t('receipt'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    InkWell(
                      onTap: () => _copyRefCode(context, order.refCode, locale),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${locale.t('order_ref_code')} : ${order.refCode}',
                              style: const TextStyle(color: AppColors.accent, fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            const HugeIcon(icon: HugeIcons.strokeRoundedCopy01, size: 14, color: AppColors.accent),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (address != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${address.country} : ${address.streetAddress}'
                          '${address.apartmentAddress?.isNotEmpty == true ? ', ${address.apartmentAddress}' : ''}',
                          style: TextStyle(color: AppColors.headingText),
                        ),
                      ),
                      Text(address.phone, style: TextStyle(color: AppColors.headingText)),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                // Товары в заказе
                ...order.items.map((cartItem) => InkWell(
                    onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(slug: cartItem.item.slug),
                          ),
                        ),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: cartItem.item.image != null
                                  ? Image.network(
                                      cartItem.item.image!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppColors.subtle,
                                        child: const HugeIcon(icon: HugeIcons.strokeRoundedImageNotFound01, size: 18),
                                      ),
                                    )
                                  : Container(color: AppColors.subtle),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: Text(
                              cartItem.item.titleFor(locale.language),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: AppColors.headingText),
                            ),
                          ),
                          if (cartItem.selectColor != null)
                            Expanded(
                              child: Text(
                                cartItem.selectColor!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.bodyText),
                              ),
                            ),
                          if (cartItem.selectSize != null)
                            Expanded(
                              child: Text(
                                cartItem.selectSize!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.bodyText),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              '${locale.t('qty_short')}: ${cartItem.quantity}',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.bodyText, fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${cartItem.totalPrice ?? '-'} ТМТ',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ))),
                const Divider(height: 24),
                _StatusTracker(status: order.status),
                const SizedBox(height: 12),
                Text(
                  '${locale.t('order_date')} : ${_formatDate(order.orderedDate)}',
                  style: TextStyle(color: AppColors.bodyText, fontSize: 13),
                ),
                if (order.costOfDelivery != null && order.costOfDelivery! > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${locale.t('delivery_cost')} +${order.costOfDelivery} ТМТ',
                      style: TextStyle(color: AppColors.bodyText, fontSize: 13),
                    ),
                  ),
                if (order.avans != null && order.avans! > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${locale.t('avans')}: ${order.avans} ТМТ',
                      style: TextStyle(color: AppColors.bodyText, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          // Итого
          Container(
            width: double.infinity,
            color: const Color(0xFF8C6E8A),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(color: Colors.white),
                children: [
                  TextSpan(text: '${locale.t('total')}:  '),
                  TextSpan(
                    text: '${order.total ?? '-'} ТМТ',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// Полоска отслеживания заказа: В ожидании → В пути → Доставлено.
class _StatusTracker extends StatelessWidget {
  final String status;

  const _StatusTracker({required this.status});

  double get _fraction {
    switch (status) {
      case 'pending':
        return 1 / 3;
      case 'being_delivered':
        return 2 / 3;
      case 'received':
        return 1.0;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    if (status == 'cancelled' || status == 'refunded') {
      return Row(
        children: [
          Text(locale.t('track_order'), style: TextStyle(color: AppColors.bodyText, fontSize: 12)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status == 'cancelled' ? locale.t('status_cancelled') : locale.t('refund_arranged'),
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(locale.t('track_order'), style: TextStyle(color: AppColors.bodyText, fontSize: 12)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(height: 6, color: Colors.grey.shade300),
              FractionallySizedBox(
                widthFactor: _fraction,
                child: Container(height: 6, color: AppColors.accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(locale.t('status_pending'), style: TextStyle(fontSize: 11, color: AppColors.bodyText)),
            Text(locale.t('status_being_delivered'), style: TextStyle(fontSize: 11, color: AppColors.bodyText)),
            Text(locale.t('status_received'), style: TextStyle(fontSize: 11, color: AppColors.bodyText)),
          ],
        ),
      ],
    );
  }
}
