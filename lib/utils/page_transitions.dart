import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PageTransitions {
  // Transição slide da direita (para detalhes)
  static Page<T> slideFromRight<T extends Object?>(
    Widget child,
    GoRouterState state,
  ) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  // Transição slide de baixo (para formulários)
  static Page<T> slideFromBottom<T extends Object?>(
    Widget child,
    GoRouterState state,
  ) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  // Transição fade (para navegação suave)
  static Page<T> fadeTransition<T extends Object?>(
    Widget child,
    GoRouterState state,
  ) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  // Transição scale (para adicionar itens)
  static Page<T> scaleTransition<T extends Object?>(
    Widget child,
    GoRouterState state,
  ) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.elasticOut;
        var tween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return ScaleTransition(
          scale: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  // Navegação helpers para usar com GoRouter
  static void navigateWithSlide(BuildContext context, String path) {
    context.push(path);
  }

  static void navigateWithFade(BuildContext context, String path) {
    context.push(path);
  }

  static void navigateWithScale(BuildContext context, String path) {
    context.push(path);
  }

  // Para usar no GoRouter configuration
  static Page<T> getTransitionPage<T extends Object?>(
    Widget child,
    GoRouterState state, {
    String transitionType = 'slide',
  }) {
    switch (transitionType) {
      case 'fade':
        return fadeTransition(child, state);
      case 'scale':
        return scaleTransition(child, state);
      case 'bottom':
        return slideFromBottom(child, state);
      case 'slide':
      default:
        return slideFromRight(child, state);
    }
  }
}
