import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';

/// Ссылка на точку на карте.
Uri mapUri(double lat, double lng) =>
    Uri.parse('https://www.google.com/maps?q=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}');

/// Блок «Определить моё местоположение» на оформлении заказа.
/// Необязательный: по нажатию берёт координаты по GPS и отдаёт их через
/// [onChanged]; кнопка «×» убирает их.
class LocationPickerCard extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final void Function(double? latitude, double? longitude) onChanged;

  const LocationPickerCard({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onChanged,
  });

  @override
  State<LocationPickerCard> createState() => _LocationPickerCardState();
}

class _LocationPickerCardState extends State<LocationPickerCard> {
  bool _busy = false;
  String? _error;

  bool get _hasLocation => widget.latitude != null && widget.longitude != null;

  Future<void> _detect() async {
    final locale = context.read<LocaleProvider>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _error = locale.t('location_service_off'));
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _error = locale.t('location_denied'));
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      HapticFeedback.lightImpact();
      widget.onChanged(pos.latitude, pos.longitude);
    } catch (_) {
      if (mounted) setState(() => _error = locale.t('location_failed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final done = _hasLocation;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: done ? AppColors.accent.withValues(alpha: 0.08) : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: done ? AppColors.accent.withValues(alpha: 0.4) : AppColors.subtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: done ? HugeIcons.strokeRoundedCheckmarkCircle02 : HugeIcons.strokeRoundedGps01,
                color: done ? const Color(0xFF2E7D32) : AppColors.accent,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  done ? locale.t('location_added') : locale.t('location_title'),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    color: AppColors.headingText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (done)
                IconButton(
                  tooltip: locale.t('location_remove'),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => widget.onChanged(null, null),
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: AppColors.bodyText, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _error ?? locale.t('location_hint'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 12.5,
              height: 1.3,
              color: _error != null ? AppColors.danger : AppColors.bodyText,
              fontWeight: _error != null ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _detect,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(color: AppColors.accent.withValues(alpha: 0.6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: _busy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const HugeIcon(icon: HugeIcons.strokeRoundedLocation01, size: 18),
                  label: Text(
                    _busy
                        ? locale.t('location_detecting')
                        : done
                            ? locale.t('location_refresh')
                            : locale.t('location_detect'),
                    style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (done) ...[
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () => launchUrl(mapUri(widget.latitude!, widget.longitude!),
                      mode: LaunchMode.externalApplication),
                  child: Text(locale.t('open_on_map'),
                      style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
