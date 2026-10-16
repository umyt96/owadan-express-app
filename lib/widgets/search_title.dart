import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/app_theme.dart';

/// Заголовок панели на экране категории: название, которое уступает место
/// полю поиска, "вырастающему" из кнопки поиска справа налево.
///
/// Поле всегда выложено на полную ширину, растёт только обрезка — поэтому
/// текст не перестраивается, пока капсула раскрывается.
class SearchTitle extends StatelessWidget {
  const SearchTitle({
    super.key,
    required this.title,
    required this.open,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
    required this.onSubmitted,
  });

  static const duration = Duration(milliseconds: 340);
  static const height = 44.0;

  /// Зазор между капсулой и кнопкой закрытия справа.
  static const gap = 12.0;

  final String title;
  final bool open;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final animation = reduceMotion ? Duration.zero : duration;

    return LayoutBuilder(
      builder: (context, constraints) {
        final full = (constraints.maxWidth - gap).clamp(0.0, double.infinity);

        return Stack(
          alignment: Alignment.centerRight,
          children: [
            Center(
              child: AnimatedOpacity(
                opacity: open ? 0 : 1,
                duration: const Duration(milliseconds: 180),
                child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            ExcludeFocus(
              excluding: !open,
              child: IgnorePointer(
                ignoring: !open,
                // Закрытая капсула нулевой ширины; затухание не даёт её краю
                // торчать.
                child: Padding(
                  padding: const EdgeInsets.only(right: gap),
                  child: AnimatedOpacity(
                    opacity: open ? 1 : 0,
                    duration: const Duration(milliseconds: 120),
                    child: AnimatedContainer(
                      duration: animation,
                      curve: Curves.easeOutCubic,
                      width: open ? full : 0,
                      height: height,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: OverflowBox(
                        alignment: Alignment.centerRight,
                        minWidth: full,
                        maxWidth: full,
                        child: SearchField(
                          controller: controller,
                          focusNode: focusNode,
                          hint: hint,
                          onChanged: onChanged,
                          onSubmitted: onSubmitted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Содержимое капсулы поиска: плитка с лупой, поле ввода и кнопка очистки,
/// которая появляется, когда есть что очищать.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.autofocus = false,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
    required this.onSubmitted,
  });

  final bool autofocus;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 6),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              size: 18,
              color: AppColors.accent,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            textInputAction: TextInputAction.search,
            cursorColor: AppColors.accent,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              color: Color(0xFF2B2630),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontFamily: 'Gilroy',
                color: Color(0xFF8E8794),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              filled: false,
              isCollapsed: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        // Кнопка очистки появляется, когда есть что очищать.
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: value.text.isEmpty
                ? const SizedBox(width: 14, key: ValueKey('none'))
                : GestureDetector(
                    key: const ValueKey('clear'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      controller.clear();
                      onChanged('');
                      onSubmitted('');
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFC9C4CE),
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox.square(
                          dimension: 20,
                          child: Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedCancel01,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
