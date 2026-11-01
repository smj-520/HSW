import 'package:flutter/material.dart';

/// Horizontal padding from viewport width (phone / tablet / desktop).
double responsivePagePaddingX(double width) {
  if (width >= 700) return (width * 0.03).clamp(16.0, 32.0);
  if (width >= 400) return 16;
  return 12;
}

/// Max width for full content pages (home, lists, reports). ~94% on tablets.
double responsiveContentMaxWidth(double width) {
  if (width >= 700) return width * 0.94;
  return width;
}

/// Max width for auth-style forms so lines stay readable but use tablet space.
double responsiveFormMaxWidth(double width) {
  if (width >= 1100) return (width * 0.58).clamp(640.0, 900.0);
  if (width >= 700) return width * 0.78;
  if (width >= 600) return width * 0.88;
  return width;
}

/// Scrollable column that vertically centers content when shorter than the viewport.
class ResponsiveScrollableCenter extends StatelessWidget {
  const ResponsiveScrollableCenter({
    super.key,
    required this.child,
    this.physics,
  });

  final Widget child;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final padX = responsivePagePaddingX(w);
        final maxForm = responsiveFormMaxWidth(w).clamp(280.0, w - padX * 2);

        final minScrollH = h.isFinite && h > 0
            ? h.clamp(200.0, double.infinity)
            : 400.0;

        return SingleChildScrollView(
          physics: physics ?? const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: padX, vertical: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minScrollH),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxForm),
                  child: SizedBox(width: double.infinity, child: child),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Centers page content and caps width at [responsiveContentMaxWidth].
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: responsiveContentMaxWidth(w)),
        child: child,
      ),
    );
  }
}
