import 'package:acad_mate/core/assets.dart';
import 'package:acad_mate/core/config/app_config.dart';
import 'package:acad_mate/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    required this.size,
    this.heroTag,
    this.elevation = 26,
    this.imageUrl,
  });

  final double size;
  final Object? heroTag;
  final double elevation;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final Widget logo = Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: <Color>[
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.secondary.withValues(alpha: 0.12),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: elevation,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl == null || imageUrl!.trim().isEmpty
            ? Image.asset(AppAssets.logo, fit: BoxFit.cover)
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                frameBuilder:
                    (
                      BuildContext context,
                      Widget child,
                      int? frame,
                      bool wasSynchronouslyLoaded,
                    ) {
                      if (wasSynchronouslyLoaded || frame != null) {
                        return child;
                      }
                      return Image.asset(AppAssets.logo, fit: BoxFit.cover);
                    },
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return Image.asset(AppAssets.logo, fit: BoxFit.cover);
                    },
              ),
      ),
    );

    if (heroTag == null) {
      return logo;
    }

    return Hero(tag: heroTag!, child: logo);
  }
}

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.fontSize = 34,
    this.textAlign = TextAlign.center,
  });

  final double fontSize;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          colors: <Color>[AppColors.primary, AppColors.secondary],
        ).createShader(bounds);
      },
      child: Text(
        AppConfig.appName,
        textAlign: textAlign,
        style: TextStyle(
          fontFamily: 'Sora',
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: -1.2,
          height: 1,
        ),
      ),
    );
  }
}

class BrandIntro extends StatelessWidget {
  const BrandIntro({
    super.key,
    required this.logoSize,
    this.subtitle = AppConfig.tagline,
    this.heroTag,
  });

  final double logoSize;
  final String subtitle;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        BrandLogo(size: logoSize, heroTag: heroTag),
        const SizedBox(height: 18),
        const BrandWordmark(),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
