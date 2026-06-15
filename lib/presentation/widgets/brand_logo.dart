import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Renders the Nkap brand mark (the "circle of trust" logo).
///
/// Drop the supplied logo file at `assets/images/nkap_logo.png` and it is
/// picked up automatically. Until then, this falls back to a placeholder icon
/// so the UI keeps working.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 100,
    this.onLight = false,
  });

  /// Logical width/height of the logo square.
  final double size;

  /// When shown on a light background, the placeholder uses the brand color
  /// instead of white.
  final bool onLight;

  static const String assetPath = 'assets/images/nkap_logo.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _Placeholder(
        size: size,
        onLight: onLight,
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.size, required this.onLight});

  final double size;
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final color = onLight ? AppColors.primary : AppColors.white;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: (onLight ? AppColors.primary : AppColors.white)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(Icons.groups_rounded, size: size * 0.56, color: color),
    );
  }
}
