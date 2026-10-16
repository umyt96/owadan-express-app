import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:owadan_express_app/widgets/gradient_app_bar.dart';

void main() {
  testWidgets('drawer button uses HugeIcons and opens the drawer',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          drawer: Drawer(child: Text('Drawer content')),
          appBar: GradientAppBar(title: Text('Home')),
          body: Text('Page content'),
        ),
      ),
    );

    expect(
        find.byWidgetPredicate((widget) =>
            widget is HugeIcon && widget.icon == HugeIcons.strokeRoundedMenu01),
        findsOneWidget);
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.text('Drawer content'), findsOneWidget);
  });

  testWidgets('back button uses HugeIcons and pops the route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: const GradientAppBar(title: Text('Home')),
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(
                    appBar: GradientAppBar(title: Text('Details')),
                  ),
                ),
              ),
              child: const Text('Open details'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    expect(
        find.byWidgetPredicate((widget) =>
            widget is HugeIcon &&
            widget.icon == HugeIcons.strokeRoundedArrowLeft01),
        findsOneWidget);
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.text('Open details'), findsOneWidget);
  });
}
