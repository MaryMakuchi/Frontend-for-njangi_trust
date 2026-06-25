import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomButton extends StatefulWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.gradient,
    this.backgroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Gradient? gradient;
  final Color? backgroundColor;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isHovered = false;

  bool get _isEnabled => !widget.isLoading && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final hoverActive = _isHovered && _isEnabled;

    return MouseRegion(
      cursor: _isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: hoverActive
            ? (Matrix4.identity()..scale(1.02))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: hoverActive
              ? [
                  BoxShadow(
                    color: (widget.backgroundColor ?? AppColors.primary)
                        .withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: _buildButton(context, hoverActive),
      ),
    );
  }

  Widget _buildButton(BuildContext context, bool hoverActive) {
    if (widget.isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: hoverActive
                ? AppColors.primary.withValues(alpha: 0.06)
                : null,
            side: BorderSide(
              color: hoverActive ? AppColors.primary : AppColors.border,
              width: hoverActive ? 1.5 : 1,
            ),
          ),
          child: _buildChild(context, isOutlined: true),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: widget.gradient ?? AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          color: widget.gradient == null
              ? (widget.backgroundColor ?? AppColors.primary)
              : null,
        ),
        child: ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            overlayColor: AppColors.white.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _buildChild(context),
        ),
      ),
    );
  }

  Widget _buildChild(BuildContext context, {bool isOutlined = false}) {
    if (widget.isLoading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: isOutlined ? AppColors.primary : AppColors.white,
        ),
      );
    }
    if (widget.icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 20),
          const SizedBox(width: 8),
          Text(widget.label),
        ],
      );
    }
    return Text(widget.label);
  }
}
