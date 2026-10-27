import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LiquidGlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<IconData> icons;
  final List<String> labels;

  const LiquidGlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.icons,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xFF131722).withOpacity(0.88),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(icons.length, (index) {
                  final bool isSelected = index == currentIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeInOutCubic,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSelected ? 12 : 8,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryTeal.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          border: isSelected
                              ? Border.all(
                                  color: AppTheme.primaryTeal.withOpacity(0.35),
                                  width: 1,
                                )
                              : Border.all(color: Colors.transparent, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScale(
                              scale: isSelected ? 1.05 : 0.95,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                icons[index],
                                size: 21,
                                color: isSelected
                                    ? AppTheme.primaryTeal
                                    : AppTheme.darkTextMuted.withOpacity(0.8),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  labels[index],
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryTeal,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}