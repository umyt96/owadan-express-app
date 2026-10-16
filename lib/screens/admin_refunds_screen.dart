import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/refund_request.dart';
import '../providers/locale_provider.dart';
import '../services/checkout_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_app_bar.dart';

/// Раздел "Возвраты" — как страница /orders/refund/ на сайте. Доступен
/// только суперпользователю (пункт меню скрыт для обычных пользователей,
/// см. ProfileScreen).
class AdminRefundsScreen extends StatefulWidget {
  const AdminRefundsScreen({super.key});

  @override
  State<AdminRefundsScreen> createState() => _AdminRefundsScreenState();
}

class _AdminRefundsScreenState extends State<AdminRefundsScreen> {
  final _checkoutService = CheckoutService();

  final List<RefundRequest> _refunds = [];
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
        _refunds.clear();
      }
    });
    try {
      final result = await _checkoutService.getAllRefunds(page: _page);
      setState(() {
        _refunds.addAll(result.results);
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

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}-${two(date.month)}-${date.year}';
  }

  Future<void> _toggleAccepted(RefundRequest refund, bool value) async {
    final locale = context.read<LocaleProvider>();
    try {
      await _checkoutService.setRefundAccepted(refundId: refund.id, accepted: value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.t('status_updated'))),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: GradientAppBar(title: Text(locale.t('refunds'))),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: _buildBody(locale),
      ),
    );
  }

  Widget _buildBody(LocaleProvider locale) {
    if (_refunds.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_refunds.isEmpty && _error != null) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('${locale.t('error')}: $_error', textAlign: TextAlign.center),
          ),
        ],
      );
    }
    if (_refunds.isEmpty && !_hasMore) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(child: Text(locale.t('nothing_found'))),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _refunds.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _refunds.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _loadPage());
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final locale = context.watch<LocaleProvider>();
        final refund = _refunds[index];
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
                                '${locale.t('order_ref_code')}: ${refund.orderRefCode}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(_formatDate(refund.createdDate),
                                style: TextStyle(fontSize: 12, color: AppColors.bodyText)),
                          ],
                        ),
                        if (refund.username != null)
                          Text('${locale.t('customer')}: ${refund.username}',
                              style: TextStyle(color: AppColors.bodyText)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.subtle,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(refund.reason),
                        ),
                        if (refund.orderItems.isNotEmpty) ...[
                          const Divider(height: 20),
                          ...refund.orderItems.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: item.item.image != null
                                            ? Image.network(
                                                item.item.image!,
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
                                        item.item.titleFor(locale.language),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    if (item.selectColor != null)
                                      Expanded(
                                        child: Text(item.selectColor!,
                                            textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                                      ),
                                    if (item.selectSize != null)
                                      Expanded(
                                        child: Text(item.selectSize!,
                                            textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                                      ),
                                    Expanded(
                                      child: Text(
                                        '${locale.t('qty_short')}: ${item.quantity}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 12, color: AppColors.bodyText),
                                      ),
                                    ),
                                    Text(
                                      '${item.totalPrice ?? '-'} ТМТ',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(locale.t('refund_reimbursed'), style: const TextStyle(fontWeight: FontWeight.w600)),
                            Switch(
                              value: refund.accepted,
                              onChanged: (value) => _toggleAccepted(refund, value),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
  }
}
