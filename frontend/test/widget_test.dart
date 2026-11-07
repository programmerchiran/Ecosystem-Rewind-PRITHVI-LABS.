import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/main.dart';
import 'package:frontend/core/config/app_config.dart';

void main() {
  testWidgets('Ecosystem Rewind App loads landing page smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: EcosystemRewindApp()));
    await tester.pumpAndSettle();

    // Verify brand and title exist on initial load
    expect(find.text(AppConfig.appName), findsWidgets);
    expect(find.text(AppConfig.brandName), findsWidgets);
  });
}
