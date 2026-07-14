import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 140);
  static const standard = Duration(milliseconds: 240);
  static const expressive = Duration(milliseconds: 420);
  static const stagger = Duration(milliseconds: 46);

  static const emphasized = Cubic(0.2, 0.8, 0.2, 1);
  static const exit = Cubic(0.4, 0, 1, 1);
}

class PageMotion extends StatelessWidget {
  const PageMotion({required this.child, required this.motionKey, super.key});

  final Widget child;
  final Object motionKey;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : AppMotion.expressive,
      reverseDuration: reduceMotion ? Duration.zero : AppMotion.standard,
      switchInCurve: AppMotion.emphasized,
      switchOutCurve: AppMotion.exit,
      transitionBuilder: (child, animation) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.12, 1, curve: AppMotion.emphasized),
        );
        final slide =
            Tween<Offset>(
              begin: const Offset(0.025, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: AppMotion.emphasized),
            );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(key: ValueKey(motionKey), child: child),
    );
  }
}

class HoverLift extends StatefulWidget {
  const HoverLift({
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    super.key,
  });

  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedScale(
        duration: reduceMotion ? Duration.zero : AppMotion.standard,
        curve: AppMotion.emphasized,
        scale: hovered ? 1.012 : 1,
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : AppMotion.standard,
          curve: AppMotion.emphasized,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.13),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : const [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class PulsingStatusDot extends StatefulWidget {
  const PulsingStatusDot({required this.color, super.key});

  final Color color;

  @override
  State<PulsingStatusDot> createState() => _PulsingStatusDotState();
}

class _PulsingStatusDotState extends State<PulsingStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return _dot();
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = Curves.easeOut.transform(controller.value);
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: 1 + (value * 1.4),
              child: Opacity(opacity: 1 - value, child: _dot(alpha: 0.3)),
            ),
            child!,
          ],
        );
      },
      child: _dot(),
    );
  }

  Widget _dot({double alpha = 1}) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: widget.color.withValues(alpha: alpha),
      shape: BoxShape.circle,
    ),
  );
}
