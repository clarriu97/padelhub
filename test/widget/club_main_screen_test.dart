import 'package:flutter_test/flutter_test.dart';
import 'package:padelhub/screens/home/club_main_screen.dart';

void main() {
  group('ClubMainScreen Widget Tests', () {
    testWidgets('widget can be instantiated', (WidgetTester tester) async {
      // Just verify the widget can be created without crashing
      const widget = ClubMainScreen();
      expect(widget, isNotNull);
    });
  });
}
