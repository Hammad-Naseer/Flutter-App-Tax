// ─────────────────────────────────────────────────────────────────────────────
// lib/core/widgets/app_loader.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class AppLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLoader({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Colors.green,
        ),
      ),
    );
  }
}

