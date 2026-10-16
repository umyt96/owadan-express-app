import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../models/admin_review.dart';
import '../providers/locale_provider.dart';
import '../services/admin_review_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_app_bar.dart';
import 'product_detail_screen.dart';

/// Раздел "Отзывы" (на сайте — "Рейтинг" в админке) — только суперпользователь:
/// все отзывы по всем товарам, фильтр по оценке, поиск, скрытие и удаление.
class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  final _service = AdminReviewService();
  final _searchController = TextEditingController();
  Timer? _debounce;

  final List<AdminReview> _items = [];
  ReviewStats? _stats;
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  /// null — все; 1..5 — по оценке; 0 — только скрытые.
  int? _filter;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    _service.getStats().then((s) {
      if (mounted) setState(() => _stats = s);
    });
    await _load(reset: true);
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
      final result = await _service.getReviews(
        page: _page,
        rating: (_filter != null && _filter! > 0) ? _filter : null,
        hiddenOnly: _filter == 0,
        search: _searchController.text.trim(),
      );
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

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 450), () => _load(reset: true));
  }

  void _setFilter(int? value) {
    setState(() => _filter = value);
    _load(reset: true);
  }

  Future<void> _toggleVisible(AdminReview review) async {
    final newValue = !review.visible;
    final i = _items.indexWhere((r) => r.id == review.id);
    if (i == -1) return;
    setState(() =>
        _items[i] = review.copyWith(visible: newValue)); // сразу в интерфейсе
    try {
      await _service.setVisible(review.id, newValue);
      _service.getStats().then((s) {
        if (mounted) setState(() => _stats = s);
      });
      if (_filter == 0 && newValue && mounted) {
        setState(() => _items.removeWhere((r) => r.id == review.id));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _items[i] = review); // откат
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _delete(AdminReview review) async {
    final locale = context.read<LocaleProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale.t('delete_review')),
        content: Text(locale.t('delete_review_confirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(locale.t('cancel'))),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(locale.t('delete'),
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.delete(review.id);
      if (!mounted) return;
      setState(() => _items.removeWhere((r) => r.id == review.id));
      _service.getStats().then((s) {
        if (mounted) setState(() => _stats = s);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(locale.t('review_deleted'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _openImage(String url) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              maxScale: 4,
              child: Center(child: Image.network(url, fit: BoxFit.contain)),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: GradientAppBar(title: Text(locale.t('admin_reviews'))),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(locale)),
            if (_items.isEmpty && _loading)
              const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
            else if (_items.isEmpty && _error != null)
              SliverFillRemaining(
                  child: Center(child: Text('${locale.t('error')}: $_error')))
            else if (_items.isEmpty)
              SliverFillRemaining(
                  child: Center(child: Text(locale.t('nothing_found'))))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= _items.length) {
                        WidgetsBinding.instance
                            .addPostFrameCallback((_) => _load());
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final r = _items[index];
                      return _ReviewCard(
                        review: r,
                        language: locale.language,
                        onToggleVisible: () => _toggleVisible(r),
                        onDelete: () => _delete(r),
                        onOpenImage: _openImage,
                      );
                    },
                    childCount: _items.length + (_hasMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(LocaleProvider locale) {
    final stats = _stats;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stats != null)
            Row(
              children: [
                _StatBox(
                    label: locale.t('stat_total'), value: '${stats.total}'),
                const SizedBox(width: 8),
                _StatBox(
                  label: locale.t('average_rating'),
                  value: stats.average != null ? '★ ${stats.average}' : '—',
                ),
                const SizedBox(width: 8),
                _StatBox(
                    label: locale.t('hidden_reviews'),
                    value: '${stats.hidden}'),
              ],
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: locale.t('search_reviews_hint'),
              prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedSearch01),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(locale.t('all_messages'), null),
                for (var star = 5; star >= 1; star--)
                  _filterChip('$star ★', star),
                _filterChip(locale.t('hidden_reviews'), 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int? value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : AppColors.headingText)),
        selected: selected,
        onSelected: (_) => _setFilter(value),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          gradient: AppColors.softGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17)),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final AdminReview review;
  final String language;
  final VoidCallback onToggleVisible;
  final VoidCallback onDelete;
  final void Function(String url) onOpenImage;

  const _ReviewCard({
    required this.review,
    required this.language,
    required this.onToggleVisible,
    required this.onDelete,
    required this.onOpenImage,
  });

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}.${two(l.month)}.${l.year} ${two(l.hour)}:${two(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final r = review;
    return Opacity(
      // Скрытый отзыв — полупрозрачный, чтобы сразу было видно его статус.
      opacity: r.visible ? 1 : 0.6,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (r.product != null)
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailScreen(slug: r.product!.slug)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: r.product!.image != null
                              ? Image.network(r.product!.image!,
                                  fit: BoxFit.cover)
                              : Container(color: AppColors.subtle),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.product!.titleFor(language),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const HugeIcon(
                          icon: HugeIcons.strokeRoundedChevronRight,
                          size: 18,
                          color: AppColors.accent),
                    ],
                  ),
                ),
              const Divider(height: 18),
              Row(
                children: [
                  const HugeIcon(icon: HugeIcons.strokeRoundedUser, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(r.username,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Text(_formatDate(r.createdDate),
                      style:
                          TextStyle(fontSize: 11, color: AppColors.bodyText)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(
                  5,
                  (i) => HugeIcon(
                    icon: i < r.rating.round()
                        ? HugeIcons.strokeRoundedStar
                        : HugeIcons.strokeRoundedStar,
                    size: 18,
                    color: Colors.amber,
                  ),
                ),
              ),
              if (r.review.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(r.review),
              ],
              if (r.images.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: r.images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => GestureDetector(
                      onTap: () => onOpenImage(r.images[i]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(r.images[i],
                            width: 64, height: 64, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ],
              const Divider(height: 18),
              Row(
                children: [
                  HugeIcon(
                      icon: r.visible
                          ? HugeIcons.strokeRoundedEye
                          : HugeIcons.strokeRoundedEyeOff,
                      size: 18,
                      color: AppColors.bodyText),
                  const SizedBox(width: 6),
                  Text(
                    r.visible
                        ? locale.t('review_visible')
                        : locale.t('review_hidden'),
                    style: TextStyle(fontSize: 13, color: AppColors.bodyText),
                  ),
                  Switch(value: r.visible, onChanged: (_) => onToggleVisible()),
                  const Spacer(),
                  IconButton(
                    tooltip: locale.t('delete_review'),
                    icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        color: AppColors.danger),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
