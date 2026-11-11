import 'package:flutter/material.dart';

/// Screen-size helpers shared with the customer app layout language.
class AppResponsive {
  AppResponsive._(this.context)
    : size = MediaQuery.sizeOf(context),
      viewPadding = MediaQuery.viewPaddingOf(context);

  factory AppResponsive.of(BuildContext context) => AppResponsive._(context);

  final BuildContext context;
  final Size size;
  final EdgeInsets viewPadding;

  double get width => size.width;
  double get height => size.height;

  bool get isCompactWidth => width < 360;
  bool get isShortHeight => height < 700;
  bool get isTablet => width >= 600;

  double get contentMaxWidth {
    if (width >= 900) return 560;
    if (isTablet) return 520;
    return width;
  }

  double get horizontalPadding {
    if (isCompactWidth) return 16;
    if (isTablet) return 32;
    return 24;
  }

  double get fieldGap => isShortHeight ? 12.0 : 16.0;

  double space(double compact, double regular) {
    return isShortHeight || isCompactWidth ? compact : regular;
  }

  double logoWidth({
    double fraction = 0.5,
    double min = 140,
    double max = 240,
  }) {
    return (width * fraction).clamp(min, max);
  }
}

/// Centers children in a phone-friendly max width on larger screens.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? responsive.contentMaxWidth,
        ),
        child: padding == null
            ? child
            : Padding(padding: padding!, child: child),
      ),
    );
  }
}
