import 'package:flutter/material.dart';

class Responsive {
  final BuildContext context;
  Responsive(this.context);

  static Responsive of(BuildContext context) => Responsive(context);

  double get width => MediaQuery.of(context).size.width;
  double get height => MediaQuery.of(context).size.height;

  // Check if screen is small (vertical height < 700)
  bool get isSmallScreen => height < 700;

  // Check if screen is wide
  bool get isWideScreen => width > 600;

  // Scale value based on screen width (standard mobile width baseline: 375)
  double w(double size) {
    double scale = width / 375;
    if (scale > 1.2) scale = 1.2; // Limit scaling
    return scale * size;
  }

  // Scale value based on screen height (standard mobile height baseline: 812)
  double h(double size) {
    double scale = height / 812;
    if (scale > 1.2) scale = 1.2; // Limit scaling
    return scale * size;
  }

  // Font scale baseline
  double sp(double size) {
    // Limit scaling for very large or very small screens to maintain readability
    double scale = width / 375;
    if (scale > 1.2) scale = 1.2;
    if (scale < 0.8) scale = 0.8;
    return size * scale;
  }

  // Adaptive Padding
  EdgeInsets get screenPadding => EdgeInsets.all(w(16));
  EdgeInsets get cardPadding => EdgeInsets.all(w(20));
}

extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive.of(this);
}
