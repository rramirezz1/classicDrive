import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classic_drive/widgets/modern_navigation.dart';
import 'package:classic_drive/theme/app_colors.dart';

void main() {
  group('ModernBottomNav', () {
    testWidgets('should render all nav items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: ModernBottomNav(
              currentIndex: 0,
              onTap: (_) {},
              items: const [
                ModernNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Home',
                ),
                ModernNavItem(
                  icon: Icons.search_outlined,
                  selectedIcon: Icons.search_rounded,
                  label: 'Pesquisar',
                ),
                ModernNavItem(
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person_rounded,
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Pesquisar'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    });

    testWidgets('should highlight selected item', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: ModernBottomNav(
              currentIndex: 1,
              onTap: (_) {},
              items: const [
                ModernNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Home',
                ),
                ModernNavItem(
                  icon: Icons.search_outlined,
                  selectedIcon: Icons.search_rounded,
                  label: 'Pesquisar',
                ),
              ],
            ),
          ),
        ),
      );

      // O item "Pesquisar" deve estar selecionado (índice 1)
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('should call onTap when item is tapped', (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: ModernBottomNav(
              currentIndex: 0,
              onTap: (index) => tappedIndex = index,
              items: const [
                ModernNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Home',
                ),
                ModernNavItem(
                  icon: Icons.search_outlined,
                  selectedIcon: Icons.search_rounded,
                  label: 'Pesquisar',
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pesquisar'));
      await tester.pump();

      expect(tappedIndex, 1);
    });

    testWidgets('should work in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            bottomNavigationBar: ModernBottomNav(
              currentIndex: 0,
              onTap: (_) {},
              items: const [
                ModernNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Home',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ModernBottomNav), findsOneWidget);
    });
  });

  group('ModernNavItem', () {
    test('should create with required properties', () {
      const item = ModernNavItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: 'Home',
      );

      expect(item.label, 'Home');
      expect(item.icon, Icons.home_outlined);
      expect(item.selectedIcon, Icons.home_rounded);
    });
  });
}
