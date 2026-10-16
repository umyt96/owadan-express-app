import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../models/manage_models.dart';
import '../providers/locale_provider.dart';
import '../services/manage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_app_bar.dart';
import 'product_editor_screen.dart';

/// Раздел "Товары" — для персонала: список всех товаров (включая
/// неопубликованные), поиск, добавление и изменение.
class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final _service = ManageService();
  final _search = TextEditingController();
  Timer? _debounce;

  final List<ManageItem> _items = [];
  int _page = 1;
  int _count = 0;
  // Фильтр как на сайте: Все / Скрытые / Нет на складе (количество 0).
  String _filter = 'all';
  Map<String, int> _counts = {};
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
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
      final r = await _service.getItems(page: _page, search: _search.text.trim(), filter: _filter);
      if (!mounted) return;
      setState(() {
        _items.addAll(r.items);
        _hasMore = r.hasMore;
        _count = r.count;
        if (r.counts.isNotEmpty) _counts = r.counts;
        _page++;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open({int? id}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProductEditorScreen(itemId: id)),
    );
    if (changed == true) _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: GradientAppBar(title: Text(locale.t('manage_products'))),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gradientEnd,
        foregroundColor: Colors.white,
        onPressed: () => _open(),
        icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
        label: Text(locale.t('add_product')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _search,
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 450), () => _load(reset: true));
              },
              decoration: InputDecoration(
                hintText: locale.t('search_product_hint'),
                prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedSearch01),
                isDense: true,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                for (final f in const [
                  ('all', 'filter_all'),
                  ('hidden', 'filter_hidden'),
                  ('out', 'filter_out_of_stock'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_counts[f.$1] != null ? '${locale.t(f.$2)} ${_counts[f.$1]}' : locale.t(f.$2)),
                      selected: _filter == f.$1,
                      selectedColor: AppColors.brand,
                      labelStyle: TextStyle(color: _filter == f.$1 ? Colors.white : null),
                      showCheckmark: false,
                      onSelected: (_) {
                        if (_filter == f.$1) return;
                        setState(() => _filter = f.$1);
                        _load(reset: true);
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (_count > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${locale.t('found_count')}: $_count', style: TextStyle(color: AppColors.bodyText, fontSize: 12)),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(reset: true),
              child: _buildList(locale),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(LocaleProvider locale) {
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty && _error != null) {
      return ListView(children: [
        const SizedBox(height: 100),
        Center(child: Text('${locale.t('error')}: $_error')),
      ]);
    }
    if (_items.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 100),
        Center(child: Text(locale.t('nothing_found'))),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
      itemCount: _items.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (i >= _items.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _load());
          return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
        }
        final it = _items[i];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            onTap: () => _open(id: it.id),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: it.image != null
                          ? Image.network(it.image!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.subtle))
                          : Container(
                              color: AppColors.subtle,
                              child: const HugeIcon(icon: HugeIcons.strokeRoundedImageNotFound01),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.titleFor(locale.language), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('ID ${it.id} · ${it.categoryTitle}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: AppColors.bodyText)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('${_fmt(it.price)} CNY', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brand)),
                            if (it.priceTmt != null) Text('  ≈ ${it.priceTmt} TMT', style: TextStyle(fontSize: 12, color: AppColors.bodyText)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _Badge(
                        text: it.isPublished ? locale.t('published') : locale.t('not_published'),
                        color: it.isPublished ? AppColors.success : AppColors.bodyText,
                      ),
                      const SizedBox(height: 6),
                      Text('${locale.t('qty_short')}: ${it.quantity}', style: TextStyle(fontSize: 11, color: AppColors.bodyText)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
