import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';

/// Root tabs use this signal to load fresh data after a connection returns.
final ValueNotifier<int> connectionRestoredTick = ValueNotifier(0);

enum _ConnectionIssue { none, offline, serviceUnavailable }

class ConnectionGate extends StatefulWidget {
  const ConnectionGate({super.key, required this.child});

  final Widget child;

  @override
  State<ConnectionGate> createState() => _ConnectionGateState();
}

class _ConnectionGateState extends State<ConnectionGate> with WidgetsBindingObserver {
  final _connectivity = Connectivity();
  final _probe = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    responseType: ResponseType.plain,
    validateStatus: (_) => true,
  ));

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _changeDebounce;
  _ConnectionIssue _issue = _ConnectionIssue.none;
  bool _checking = false;
  int _checkId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = _connectivity.onConnectivityChanged.listen((_) {
      // iOS can briefly report no network while changing between Wi-Fi and data.
      _changeDebounce?.cancel();
      _changeDebounce = Timer(const Duration(milliseconds: 400), _check);
    });
    _check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final checkId = ++_checkId;
    if (_issue != _ConnectionIssue.none && mounted) {
      setState(() => _checking = true);
    }

    try {
      final networks = await _connectivity.checkConnectivity();
      if (!mounted || checkId != _checkId) return;
      if (networks.isEmpty || networks.every((network) => network == ConnectivityResult.none)) {
        setState(() {
          _issue = _ConnectionIssue.offline;
          _checking = false;
        });
        return;
      }

      // A Wi-Fi connection may have no Internet access. Verify the app's API.
      final response = await _probe.get<String>(
        '${ApiConfig.baseUrl}/all-categories/',
      );
      if (!mounted || checkId != _checkId) return;
      final status = response.statusCode;
      if (status == null || status < 200 || status >= 400) {
        setState(() {
          _issue = _ConnectionIssue.serviceUnavailable;
          _checking = false;
        });
        return;
      }
      final restored = _issue != _ConnectionIssue.none;
      setState(() {
        _issue = _ConnectionIssue.none;
        _checking = false;
      });
      if (restored) connectionRestoredTick.value++;
    } catch (_) {
      if (!mounted || checkId != _checkId) return;
      setState(() {
        _issue = _ConnectionIssue.serviceUnavailable;
        _checking = false;
      });
    }
  }

  @override
  void dispose() {
    ++_checkId;
    _changeDebounce?.cancel();
    _subscription?.cancel();
    _probe.close(force: true);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final showIssue = _issue != _ConnectionIssue.none;

    return Stack(
      children: [
        TickerMode(
          enabled: !showIssue,
          child: IgnorePointer(ignoring: showIssue, child: widget.child),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !showIssue,
            child: AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: showIssue
                  ? _ConnectionPage(
                      key: ValueKey(_issue),
                      issue: _issue,
                      checking: _checking,
                      onRetry: _checking ? null : _check,
                    )
                  : const SizedBox.expand(key: ValueKey('connected')),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConnectionPage extends StatelessWidget {
  const _ConnectionPage({
    super.key,
    required this.issue,
    required this.checking,
    required this.onRetry,
  });

  final _ConnectionIssue issue;
  final bool checking;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final isOffline = issue == _ConnectionIssue.offline;
    final title = locale.t(isOffline ? 'offline_title' : 'service_unavailable_title');
    final description = locale.t(isOffline ? 'offline_body' : 'service_unavailable_body');
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final softAccent = AppColors.accent.withValues(alpha: AppColors.isDark ? 0.16 : 0.08);

    return Material(
      color: AppColors.scaffoldBackground,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, reduceMotion ? 0 : (1 - value) * 10),
                        child: child,
                      ),
                    ),
                    child: Container(
                      width: 176,
                      height: 176,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: softAccent,
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 118,
                        height: 118,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gradientEnd.withValues(alpha: 0.09),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: HugeIcon(
                          icon: isOffline ? HugeIcons.strokeRoundedWifiOff01 : HugeIcons.strokeRoundedCloudAlert,
                          size: 58,
                          color: AppColors.accent,
                          strokeWidth: 1.7,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.headingText,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.bodyText,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.65),
                        disabledForegroundColor: Colors.white,
                      ),
                      icon: checking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const HugeIcon(
                              icon: HugeIcons.strokeRoundedRefresh,
                              size: 21,
                              color: Colors.white,
                            ),
                      label: Text(locale.t(checking ? 'checking_connection' : 'retry_connection')),
                    ),
                  ),
                  if (isOffline) ...[
                    const SizedBox(height: 16),
                    Text(
                      locale.t('reconnect_hint'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.bodyText, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
