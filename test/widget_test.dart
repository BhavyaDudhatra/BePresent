import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:be_present/main.dart';
import 'package:be_present/core/theme/app_theme.dart';

void main() {
  testWidgets('App builds and shows splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BePresentApp()));

    expect(find.text('Be Present'), findsWidgets);
  });

  test('Theme colors are defined', () {
    expect(AppTheme.presentColor, isNotNull);
    expect(AppTheme.absentColor, isNotNull);
    expect(AppTheme.lateColor, isNotNull);
  });
}