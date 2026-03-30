import 'package:flutter/material.dart';

class GradientCard extends StatelessWidget {
  final Color gradientStart;
  final Color gradientEnd;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  const GradientCard({
    super.key,
    required this.gradientStart,
    required this.gradientEnd,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gradientStart, gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
