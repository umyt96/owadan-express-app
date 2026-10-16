import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/favorite_service.dart';
import '../utils/auth_guard.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/guest_login_button.dart';
import '../widgets/product_card.dart';
import '../widgets/illustrated_empty_state.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _favoriteService = FavoriteService();
  List<ItemSummary>? _items;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    favoritesVersion.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    favoritesVersion.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  /// Товар добавили/убрали в избранное на другом экране — обновляем список.
  void _onFavoritesChanged() {
    if (mounted &&
        context.read<AuthProvider>().status == AuthStatus.authenticated) {
      _reload();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _favoriteService.getFavorites();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    final ok = await ensureLoggedIn(context);
    if (ok && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>();

    if (auth.status != AuthStatus.authenticated) {
      return Scaffold(
        appBar: GradientAppBar(title: Text(locale.t('nav_favorites'))),
        body: IllustratedEmptyState(
          image: EmptyIllustrations.favorites,
          title: locale.t('nav_favorites'),
          description: locale.t('favorites_login_hint'),
          actionButton: GuestLoginButton(
            label: locale.t('login_button'),
            onPressed: _login,
          ),
        ),
      );
    }

    if (_items == null && !_loading && _error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
    }

    final items = _items ?? [];
    return Scaffold(
      appBar: GradientAppBar(title: Text(locale.t('nav_favorites'))),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: _buildBody(locale, items),
      ),
    );
  }

  Widget _buildBody(LocaleProvider locale, List<ItemSummary> items) {
    if (_items == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items == null && _error != null) {
      return ListView(children: [
        const SizedBox(height: 120),
        Center(child: Text('${locale.t('error')}: $_error')),
      ]);
    }
    if (items.isEmpty) {
      return IllustratedEmptyState(
        image: EmptyIllustrations.favorites,
        title: locale.t('favorites_empty'),
        description: locale.t('empty_favorites_body'),
      );
    }
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 28),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.62,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              // Убрать из избранного можно сердечком на самой карточке: после
              // этого список обновляется сам (favoritesVersion).
              return ProductCard(item: item.copyWithFavorite(true));
            },
          ),
        ),
      ],
    );
  }
}
