import 'package:flutter/material.dart';
import 'package:sakani/core/config/theme.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(gradient: AppGradients.background(context)),
      child: Stack(
        children: [
          // Top glow sphere
          Positioned(
            top: -90,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.accentColor.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Bottom subtle sphere
          Positioned(
            bottom: -80,
            left: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.accentColor.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}
