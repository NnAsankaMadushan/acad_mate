import 'package:acad_mate/core/widgets/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows brand wordmark', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: BrandWordmark(),
          ),
        ),
      ),
    );

    expect(find.text('AcadMate'), findsOneWidget);
  });
}
