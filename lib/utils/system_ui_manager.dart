import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Keeps the Android status bar visible while hiding the system navigation bar.
class SystemUiManager with WidgetsBindingObserver {
  SystemUiManager({this.hideDelay = const Duration(seconds: 3)});

  static const _channel = MethodChannel('owadan_express/system_ui');
  final Duration hideDelay;
  Timer? _hideTimer;

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    await _hideNavigationBar();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_hideNavigationBar()),
    );
  }

  Future<void> _hideNavigationBar() =>
      _channel.invokeMethod<void>('hideNavigationBar');

  @override
  void didChangeMetrics() {
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view == null) return;

    // A swipe can reveal Android's navigation bar while the app is open.
    if (view.viewPadding.bottom == 0) {
      _hideTimer?.cancel();
      _hideTimer = null;
    } else if (!(_hideTimer?.isActive ?? false)) {
      _hideTimer = Timer(hideDelay, () => unawaited(_hideNavigationBar()));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_hideNavigationBar());
    }
  }
}
