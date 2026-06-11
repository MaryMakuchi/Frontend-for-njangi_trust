import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class QuickActionChip extends StatefulWidget {
  const QuickActionChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  State<QuickActionChip> createState() => _QuickActionChipState();
}

class _QuickActionChipState extends State<QuickActionChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final chipColor = widget.color ?? AppColors.primary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: _isHovered ? 0.18 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: chipColor.withValues(alpha: _isHovered ? 0.5 : 0.2),
              width: _isHovered ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: chipColor),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: chipColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
