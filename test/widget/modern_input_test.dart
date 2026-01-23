import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classic_drive/widgets/modern_input.dart';
import 'package:classic_drive/theme/app_colors.dart';

void main() {
  group('ModernSearchField', () {
    testWidgets('should render with hint text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernSearchField(
              hintText: 'Pesquisar veículos...',
            ),
          ),
        ),
      );

      expect(find.text('Pesquisar veículos...'), findsOneWidget);
    });

    testWidgets('should have search icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernSearchField(
              hintText: 'Buscar',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('should accept text input', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernSearchField(
              hintText: 'Pesquisar',
              controller: controller,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Mercedes');
      expect(controller.text, 'Mercedes');
    });

    testWidgets('should trigger onChanged callback', (tester) async {
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernSearchField(
              hintText: 'Teste',
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Porsche');
      expect(changedValue, 'Porsche');
    });

    testWidgets('should work in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: ModernSearchField(
              hintText: 'Dark Mode Search',
            ),
          ),
        ),
      );

      expect(find.byType(ModernSearchField), findsOneWidget);
    });
  });
}
