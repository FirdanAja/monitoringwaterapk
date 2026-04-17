import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/responsive_helper.dart';
import '../models/sensor_data.dart';

class StatusBadge extends StatelessWidget {
  final WaterQualityStatus status;
  final bool large;

  const StatusBadge({super.key, required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final fontSize = large ? context.responsive.sp(13) : context.responsive.sp(11);
    final vPad = large ? context.responsive.h(6) : context.responsive.h(4);
    final hPad = large ? context.responsive.w(14) : context.responsive.w(10);

    return Container(
      padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case WaterQualityStatus.drinkable:
        return AppColors.good;
      case WaterQualityStatus.usable:
        return AppColors.warning;
      case WaterQualityStatus.notDrinkable:
        return AppColors.danger;
      case WaterQualityStatus.unknown:
        return AppColors.textMuted;
    }
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final Color? borderColor;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.borderColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.cardGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.accent.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AnimatedSensorValue extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;
  final double minValue;
  final double maxValue;
  final double currentValue;
  final String safeRange;

  const AnimatedSensorValue({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
    required this.minValue,
    required this.maxValue,
    required this.currentValue,
    required this.safeRange,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ((currentValue - minValue) / (maxValue - minValue)).clamp(
      0.0,
      1.0,
    );

    return GlassCard(
      padding: EdgeInsets.all(context.responsive.w(20)),
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  AwesomeWaterLogo(
                    size: context.responsive.w(36),
                    colors: [color.withValues(alpha: 0.8), color],
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: context.responsive.sp(13),
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                safeRange,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: context.responsive.sp(10),
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: context.responsive.sp(32),
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: EdgeInsets.only(bottom: context.responsive.h(6)),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: context.responsive.sp(14),
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.5), color],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                          color: color.withValues(alpha: 0.4), blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class QualityGauge extends StatelessWidget {
  final double score;
  final WaterQualityStatus status;

  const QualityGauge({super.key, required this.score, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final size = context.responsive.w(110); // Reduced from 140 to 110 to fit better
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: context.responsive.w(10),
                  backgroundColor: AppColors.bgSurface,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    score.toStringAsFixed(0),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: context.responsive.sp(28), // Scaled down slightly
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    '/100',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: context.responsive.sp(10),
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getColor() {
    switch (status) {
      case WaterQualityStatus.drinkable:
        return AppColors.good;
      case WaterQualityStatus.usable:
        return AppColors.warning;
      case WaterQualityStatus.notDrinkable:
        return AppColors.danger;
      case WaterQualityStatus.unknown:
        return AppColors.textMuted;
    }
  }
}

class ConnectionStatusChip extends StatelessWidget {
  final String status;
  final bool connected;

  const ConnectionStatusChip({
    super.key,
    required this.status,
    required this.connected,
  });

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppColors.good : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class AwesomeWaterLogo extends StatelessWidget {
  final double size;
  final List<Color>? colors;

  const AwesomeWaterLogo({
    super.key,
    this.size = 24,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors ?? [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: (colors?.last ?? const Color(0xFF0072FF)).withValues(alpha: 0.4),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.15),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ripple effect
          Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
          ),
          // Main Icon
          Icon(
            Icons.water_drop_rounded,
            color: Colors.white,
            size: size * 0.6,
          ),
          // Subtle highlight
          Positioned(
            top: size * 0.15,
            right: size * 0.15,
            child: Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
