import 'package:acad_mate/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class GradientBackdrop extends StatelessWidget {
  const GradientBackdrop({
    super.key,
    required this.child,
    this.showWarmGlow = true,
  });

  final Widget child;
  final bool showWarmGlow;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? <Color>[
                      AppColors.backgroundDark,
                      const Color(0xFF091126),
                      const Color(0xFF111A2C),
                    ]
                  : <Color>[
                      const Color(0xFFF8FAFF),
                      const Color(0xFFF2F5FF),
                      AppColors.background,
                    ],
            ),
          ),
        ),
        Positioned(
          top: -70,
          left: -40,
          child: _GlowBlob(
            size: 210,
            colors: <Color>[
              AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.16),
              Colors.transparent,
            ],
          ),
        ),
        Positioned(
          top: 120,
          right: -50,
          child: _GlowBlob(
            size: 190,
            colors: <Color>[
              AppColors.secondary.withValues(alpha: isDark ? 0.16 : 0.15),
              Colors.transparent,
            ],
          ),
        ),
        if (showWarmGlow)
          Positioned(
            bottom: -45,
            left: 20,
            child: _GlowBlob(
              size: 230,
              colors: <Color>[
                AppColors.accent.withValues(alpha: isDark ? 0.12 : 0.18),
                Colors.transparent,
              ],
            ),
          ),
        SafeArea(child: child),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

