import 'package:flutter/material.dart';

class Responsive {
  final BuildContext context;
  Responsive(this.context);

  static Responsive of(BuildContext context) => Responsive(context);

  double get width => MediaQuery.of(context).size.width;
  double get height => MediaQuery.of(context).size.height;

  bool get isSmallScreen => height < 700;

  bool get isWideScreen => width > 600;

  double w(double size) {
    double scale = width / 375;
    if (scale > 1.2) scale = 1.2;
    return scale * size;
  }

  double h(double size) {
    double scale = height / 812;
    if (scale > 1.2) scale = 1.2;
    return scale * size;
  }

  double sp(double size) {
    double scale = width / 375;
    if (scale > 1.2) scale = 1.2;
    if (scale < 0.8) scale = 0.8;
    return size * scale;
  }

  EdgeInsets get screenPadding => EdgeInsets.all(w(16));
  EdgeInsets get cardPadding => EdgeInsets.all(w(20));
}

extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive.of(this);
}
