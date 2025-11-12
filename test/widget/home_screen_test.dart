import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padelhub/colors.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets('should verify AppColors are properly defined',
        (WidgetTester tester) async {
      // Test that colors are defined
      expect(AppColors.primary, isNotNull);
      expect(AppColors.secondary, isNotNull);
      expect(AppColors.textPrimary, isNotNull);
      expect(AppColors.background, isNotNull);
    });

    testWidgets('should verify color values match design',
        (WidgetTester tester) async {
      // Verify specific color values
      expect(AppColors.turquoise, const Color(0xFF00C5C8));
      expect(AppColors.limeGreen, const Color(0xFF7DFF00));
      expect(AppColors.darkGray, const Color(0xFF333333));
      expect(AppColors.pureWhite, const Color(0xFFFFFFFF));
      expect(AppColors.lightGray, const Color(0xFFF2F2F2));
    });
  });
}

