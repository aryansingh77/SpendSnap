import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendsnap/core/widgets/amount_display.dart';
import 'package:spendsnap/core/widgets/category_badge.dart';
import 'package:spendsnap/core/widgets/empty_state.dart';
import 'package:spendsnap/core/widgets/glow_button.dart';
import 'package:spendsnap/core/widgets/health_score_dial.dart';
import 'package:spendsnap/core/theme/app_theme.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: child),
    );

void main() {
  group('AmountDisplay', () {
    testWidgets('shows + prefix for income', (tester) async {
      await tester.pumpWidget(wrap(
        const AmountDisplay(amount: 5000, isExpense: false),
      ));
      expect(find.textContaining('+'), findsOneWidget);
    });

    testWidgets('shows - prefix for expense', (tester) async {
      await tester.pumpWidget(wrap(
        const AmountDisplay(amount: 3000, isExpense: true),
      ));
      expect(find.textContaining('-'), findsOneWidget);
    });

    testWidgets('hides sign when showSign is false', (tester) async {
      await tester.pumpWidget(wrap(
        const AmountDisplay(amount: 1000, isExpense: true, showSign: false),
      ));
      expect(find.textContaining('-'), findsNothing);
      expect(find.textContaining('+'), findsNothing);
    });
  });

  group('CategoryBadge', () {
    testWidgets('renders category label text', (tester) async {
      await tester.pumpWidget(wrap(
        const CategoryBadge(category: 'Food & Dining'),
      ));
      expect(find.text('Food & Dining'), findsOneWidget);
    });

    testWidgets('compact mode renders label', (tester) async {
      await tester.pumpWidget(wrap(
        const CategoryBadge(category: 'Transport', compact: true),
      ));
      expect(find.text('Transport'), findsOneWidget);
    });
  });

  group('GlowButton', () {
    testWidgets('displays label text', (tester) async {
      await tester.pumpWidget(wrap(
        GlowButton(label: 'Save', onPressed: () {}),
      ));
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(wrap(
        GlowButton(label: 'Save', onPressed: () {}, isLoading: true),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('onPressed fires on tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        GlowButton(label: 'Go', onPressed: () => tapped = true),
      ));
      await tester.tap(find.byType(GlowButton));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('EmptyState', () {
    testWidgets('displays title and subtitle', (tester) async {
      await tester.pumpWidget(wrap(
        const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No transactions',
          subtitle: 'Add your first one',
        ),
      ));
      expect(find.text('No transactions'), findsOneWidget);
      expect(find.text('Add your first one'), findsOneWidget);
    });

    testWidgets('action button fires callback', (tester) async {
      var pressed = false;
      await tester.pumpWidget(wrap(
        EmptyState(
          icon: Icons.flag_outlined,
          title: 'No goals',
          subtitle: 'Create a goal',
          action: () => pressed = true,
          actionLabel: 'Create Goal',
        ),
      ));
      await tester.tap(find.text('Create Goal'));
      await tester.pump();
      expect(pressed, isTrue);
    });
  });

  group('HealthScoreDial', () {
    testWidgets('renders without overflow at score 0', (tester) async {
      await tester.pumpWidget(wrap(const HealthScoreDial(score: 0)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow at score 100', (tester) async {
      await tester.pumpWidget(wrap(const HealthScoreDial(score: 100)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows score value after animation settles', (tester) async {
      await tester.pumpWidget(wrap(const HealthScoreDial(score: 75)));
      await tester.pumpAndSettle();
      expect(find.text('75'), findsOneWidget);
    });
  });
}
