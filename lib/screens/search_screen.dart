import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';
import 'product_list_screen.dart';
import '../widgets/bar_button.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/search_title.dart';
import '../widgets/illustrated_empty_state.dart';
import '../services/analytics_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    AnalyticsService.instance.event('search', data: {'query': query});
    final locale = context.read<LocaleProvider>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductListScreen(
          title: '${locale.t('search_results')}: $query',
          search: query,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: GradientAppBar(
        // Поле — белая капсула на всю ширину между "назад" и кнопкой поиска.
        titleSpacing: 0,
        title: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
                offset: Offset(24 * (1 - t), 0), child: child),
          ),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: SearchField(
              autofocus: true,
              controller: _controller,
              focusNode: _focus,
              hint: locale.t('search_hint'),
              onChanged: (_) {},
              onSubmitted: (_) => _submit(),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 12),
            child: BarButton(
              tooltip: locale.t('search'),
              icon: HugeIcons.strokeRoundedArrowRight01,
              onTap: _submit,
            ),
          ),
        ],
      ),
      body: IllustratedEmptyState(
        image: EmptyIllustrations.catalog,
        title: locale.t('search_hint'),
        description: locale.t('search_prompt'),
      ),
    );
  }
}
