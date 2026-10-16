import 'package:flutter/material.dart';

/// Слой, который поднимается поверх страницы, пока идёт поиск: верхний край
/// ползёт от низа страницы до панели, когда [open] становится true, и опускается
/// обратно, когда false. [child] всё время выложен на полную высоту и лишь
/// "открывается", поэтому список не сплющивается, пока панель растёт.
class SearchResultsLayer extends StatelessWidget {
  const SearchResultsLayer({super.key, required this.open, required this.child});

  static const duration = Duration(milliseconds: 420);

  final bool open;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final animation = MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;

    return TweenAnimationBuilder<double>(
      tween: Tween(end: open ? 1 : 0),
      duration: animation,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        // Полностью внизу: рисовать нечего, касаний и загрузки данных нет.
        if (value == 0) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;

            return ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: height * value,
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minHeight: height,
                    maxHeight: height,
                    child: DecoratedBox(
                      // Углы прямые: панель — это страница, а не карточка.
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 16,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SizedBox(height: height, child: child),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
