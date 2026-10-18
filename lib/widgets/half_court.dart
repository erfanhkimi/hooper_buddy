import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/shot.dart';

class HalfCourtWidget extends StatelessWidget {
  final List<Shot> shots;
  final Offset? selectedPosition;
  final Function(double x, double y)? onCourtTapped;
  final bool showHeatmap;

  const HalfCourtWidget({
    super.key,
    required this.shots,
    this.selectedPosition,
    this.onCourtTapped,
    this.showHeatmap = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) {
                    if (onCourtTapped == null) return;

                    final double x =
                        details.localPosition.dx / constraints.maxWidth;
                    final double y =
                        details.localPosition.dy / constraints.maxHeight;

                    onCourtTapped!(x, y);
                  },
                  child: Stack(
                    children: [
                      // 1. Hardwood Court Background
                      const Positioned.fill(
                        child: CustomPaint(
                          painter: NativeWoodCourtPainter(),
                        ),
                      ),

                      // 2. Zone Heatmap Overlay
                      if (showHeatmap && shots.isNotEmpty)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: ZoneHeatmapPainter(shots: shots),
                          ),
                        ),

                      // 3. Court Lines & Deep 3 Arc Overlay
                      const Positioned.fill(
                        child: CustomPaint(
                          painter: CourtLinesPainter(),
                        ),
                      ),

                      // 4. Shot Dots
                      Positioned.fill(
                        child: CustomPaint(
                          painter: ShotDotsPainter(shots: shots),
                        ),
                      ),

                      // 5. Selected Spot Indicator
                      if (selectedPosition != null)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: SelectedPositionPainter(
                              selectedPosition: selectedPosition,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class NativeWoodCourtPainter extends CustomPainter {
  const NativeWoodCourtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final bgPaint = Paint()..color = const Color(0xFFE2BE8A);
    final keyPaint = Paint()..color = const Color(0xFFD3A86E);

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final double keyWidth = w * 0.32;
    final double keyHeight = h * 0.38;
    final double keyLeft = (w - keyWidth) / 2;
    canvas.drawRect(Rect.fromLTWH(keyLeft, 0, keyWidth, keyHeight), keyPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CourtLinesPainter extends CustomPainter {
  const CourtLinesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final whiteLinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final zoneDividerPaint = Paint()
      ..color = Colors.white.withOpacity(0.90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final deep3LinePaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double keyWidth = w * 0.32;
    final double keyHeight = h * 0.38;
    final double keyLeft = (w - keyWidth) / 2;

    // Key & Outer Boundary Lines
    canvas.drawRect(Rect.fromLTWH(keyLeft, 0, keyWidth, keyHeight), whiteLinePaint);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), whiteLinePaint);

    // Free-Throw Circle
    canvas.drawCircle(Offset(w * 0.5, keyHeight), w * 0.12, whiteLinePaint);

    // 3-Point & Deep 3 Arc Angles
    final Offset hoopCenter = Offset(w * 0.5, h * 0.105);
    final double r3pt = w * 0.464;
    final double rDeep3 = w * 0.58;
    final Rect threePtRect = Rect.fromCircle(center: hoopCenter, radius: r3pt);
    final Rect deep3PtRect = Rect.fromCircle(center: hoopCenter, radius: rDeep3);

    const double angleCornerLeft = 2.7551;
    const double angleCornerRight = 0.3865;
    const double angleMidLeft = 2.0977;
    const double angleMidRight = 1.0439;
    const double angleWingLeft3 = 1.8942;
    const double angleWingRight3 = 1.2474;

    const double angleDeepCornerLeft = 2.6101;
    const double angleDeepCornerRight = 0.5315;

    // Standard 3-Point Line
    final Path threePointPath = Path();
    threePointPath.moveTo(w * 0.07, 0);
    threePointPath.lineTo(w * 0.07, h * 0.28);
    threePointPath.addArc(threePtRect, angleCornerLeft, angleCornerRight - angleCornerLeft);
    threePointPath.lineTo(w * 0.93, 0);
    canvas.drawPath(threePointPath, whiteLinePaint);

    // Deep 3-Point Line Arc
    final Path deepThreePtPath = Path();
    deepThreePtPath.addArc(deep3PtRect, angleDeepCornerLeft, angleDeepCornerRight - angleDeepCornerLeft);
    canvas.drawPath(deepThreePtPath, deep3LinePaint);

    // Restricted Area Arc
    canvas.drawArc(
      Rect.fromCircle(center: hoopCenter, radius: w * 0.08),
      0,
      math.pi,
      false,
      whiteLinePaint,
    );

    // Backboard & Hoop Rim
    canvas.drawLine(
      Offset(w * 0.44, h * 0.08),
      Offset(w * 0.56, h * 0.08),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 4.0,
    );
    canvas.drawCircle(
      hoopCenter,
      w * 0.025,
      Paint()
        ..color = Colors.orange.shade900
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // Zone Division Lines
    canvas.drawLine(Offset(0, h * 0.28), Offset(w * 0.07, h * 0.28), zoneDividerPaint);
    canvas.drawLine(Offset(w, h * 0.28), Offset(w * 0.93, h * 0.28), zoneDividerPaint);

    canvas.drawLine(Offset(w * 0.07, h * 0.28), Offset(w * 0.34, h * 0.28), zoneDividerPaint);
    canvas.drawLine(Offset(w * 0.93, h * 0.28), Offset(w * 0.66, h * 0.28), zoneDividerPaint);

    final Offset ptMidLeft = Offset(
      hoopCenter.dx + r3pt * math.cos(angleMidLeft),
      hoopCenter.dy + r3pt * math.sin(angleMidLeft),
    );
    final Offset ptMidRight = Offset(
      hoopCenter.dx + r3pt * math.cos(angleMidRight),
      hoopCenter.dy + r3pt * math.sin(angleMidRight),
    );

    canvas.drawLine(Offset(w * 0.34, h * 0.38), ptMidLeft, zoneDividerPaint);
    canvas.drawLine(Offset(w * 0.66, h * 0.38), ptMidRight, zoneDividerPaint);

    final Offset ptWingLeft3 = Offset(
      hoopCenter.dx + r3pt * math.cos(angleWingLeft3),
      hoopCenter.dy + r3pt * math.sin(angleWingLeft3),
    );
    final Offset ptWingRight3 = Offset(
      hoopCenter.dx + r3pt * math.cos(angleWingRight3),
      hoopCenter.dy + r3pt * math.sin(angleWingRight3),
    );

    canvas.drawLine(ptWingLeft3, Offset(w * 0.20, h), zoneDividerPaint);
    canvas.drawLine(ptWingRight3, Offset(w * 0.80, h), zoneDividerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ZoneHeatmapPainter extends CustomPainter {
  final List<Shot> shots;

  ZoneHeatmapPainter({required this.shots});

  Color _getZoneColor(String zoneName) {
    final zoneShots = shots.where((s) => s.zoneName == zoneName);
    if (zoneShots.isEmpty) return Colors.transparent;

    final made = zoneShots.where((s) => s.isMade).length;
    final double pct = made / zoneShots.length;

    if (pct >= 0.50) {
      return Colors.green.withOpacity(0.45);
    } else if (pct >= 0.35) {
      return Colors.amber.withOpacity(0.45);
    } else {
      return Colors.red.withOpacity(0.45);
    }
  }

  Paint? _getPaint(String zoneName) {
    final color = _getZoneColor(zoneName);
    if (color == Colors.transparent) return null;
    return Paint()..color = color..style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Offset hoopCenter = Offset(w * 0.5, h * 0.105);
    final double r3pt = w * 0.464;
    final double rDeep3 = w * 0.58;

    final Rect threePtRect = Rect.fromCircle(center: hoopCenter, radius: r3pt);
    final Rect deep3PtRect = Rect.fromCircle(center: hoopCenter, radius: rDeep3);

    const double angleCornerLeft = 2.7551;
    const double angleCornerRight = 0.3865;
    const double angleMidLeft = 2.0977;
    const double angleMidRight = 1.0439;
    const double angleWingLeft3 = 1.8942;
    const double angleWingRight3 = 1.2474;

    const double angleDeepCornerLeft = 2.6101;
    const double angleDeepCornerRight = 0.5315;

    final Offset ptMidLeft = Offset(
      hoopCenter.dx + r3pt * math.cos(angleMidLeft),
      hoopCenter.dy + r3pt * math.sin(angleMidLeft),
    );
    final Offset ptMidRight = Offset(
      hoopCenter.dx + r3pt * math.cos(angleMidRight),
      hoopCenter.dy + r3pt * math.sin(angleMidRight),
    );

    final Offset ptDeepWingLeft = Offset(
      hoopCenter.dx + rDeep3 * math.cos(angleWingLeft3),
      hoopCenter.dy + rDeep3 * math.sin(angleWingLeft3),
    );
    final Offset ptDeepWingRight = Offset(
      hoopCenter.dx + rDeep3 * math.cos(angleWingRight3),
      hoopCenter.dy + rDeep3 * math.sin(angleWingRight3),
    );

    // 1. Restricted Area
    final pRA = _getPaint('Restricted Area');
    if (pRA != null) {
      final path = Path()
        ..addArc(
          Rect.fromCircle(center: hoopCenter, radius: w * 0.08),
          0,
          math.pi,
        );
      canvas.drawPath(path, pRA);
    }

    // 2. In The Paint
    final pPaint = _getPaint('In The Paint');
    if (pPaint != null) {
      canvas.drawRect(Rect.fromLTWH(w * 0.34, 0, w * 0.32, h * 0.38), pPaint);
    }

    // 3. Corner 3s
    final pLC3 = _getPaint('Left Corner 3');
    if (pLC3 != null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.07, h * 0.28), pLC3);
    }

    final pRC3 = _getPaint('Right Corner 3');
    if (pRC3 != null) {
      canvas.drawRect(Rect.fromLTWH(w * 0.93, 0, w * 0.07, h * 0.28), pRC3);
    }

    // 4. Baseline Mid-Ranges
    final pLBM = _getPaint('Left Baseline Mid-Range');
    if (pLBM != null) {
      canvas.drawRect(Rect.fromLTWH(w * 0.07, 0, w * 0.27, h * 0.28), pLBM);
    }

    final pRBM = _getPaint('Right Baseline Mid-Range');
    if (pRBM != null) {
      canvas.drawRect(Rect.fromLTWH(w * 0.66, 0, w * 0.27, h * 0.28), pRBM);
    }

    // 5. Left Wing Mid-Range
    final pLWM = _getPaint('Left Wing Mid-Range');
    if (pLWM != null) {
      final path = Path()
        ..moveTo(w * 0.07, h * 0.28)
        ..lineTo(w * 0.34, h * 0.28)
        ..lineTo(w * 0.34, h * 0.38)
        ..lineTo(ptMidLeft.dx, ptMidLeft.dy)
        ..arcTo(threePtRect, angleMidLeft, angleCornerLeft - angleMidLeft, false)
        ..close();
      canvas.drawPath(path, pLWM);
    }

    // 6. Right Wing Mid-Range
    final pRWM = _getPaint('Right Wing Mid-Range');
    if (pRWM != null) {
      final path = Path()
        ..moveTo(w * 0.93, h * 0.28)
        ..lineTo(w * 0.66, h * 0.28)
        ..lineTo(w * 0.66, h * 0.38)
        ..lineTo(ptMidRight.dx, ptMidRight.dy)
        ..arcTo(threePtRect, angleMidRight, angleCornerRight - angleMidRight, false)
        ..close();
      canvas.drawPath(path, pRWM);
    }

    // 7. Center Mid-Range
    final pCMR = _getPaint('Center Mid-Range');
    if (pCMR != null) {
      final path = Path()
        ..moveTo(w * 0.34, h * 0.38)
        ..lineTo(w * 0.66, h * 0.38)
        ..lineTo(ptMidRight.dx, ptMidRight.dy)
        ..arcTo(threePtRect, angleMidRight, angleMidLeft - angleMidRight, false)
        ..close();
      canvas.drawPath(path, pCMR);
    }

    // 8. Standard Left Wing 3 (Bounded between standard 3PT and Deep 3 arcs)
    final pLW3 = _getPaint('Left Wing 3');
    if (pLW3 != null) {
      final path = Path()
        ..moveTo(0, h * 0.28)
        ..lineTo(w * 0.07, h * 0.28)
        ..arcTo(threePtRect, angleCornerLeft, angleWingLeft3 - angleCornerLeft, false)
        ..lineTo(ptDeepWingLeft.dx, ptDeepWingLeft.dy)
        ..arcTo(deep3PtRect, angleWingLeft3, angleDeepCornerLeft - angleWingLeft3, false)
        ..lineTo(0, h * 0.3989)
        ..close();
      canvas.drawPath(path, pLW3);
    }

    // 9. Standard Center 3
    final pC3 = _getPaint('Center 3');
    if (pC3 != null) {
      final path = Path()
        ..moveTo(
          hoopCenter.dx + r3pt * math.cos(angleWingLeft3),
          hoopCenter.dy + r3pt * math.sin(angleWingLeft3),
        )
        ..arcTo(threePtRect, angleWingLeft3, angleWingRight3 - angleWingLeft3, false)
        ..lineTo(ptDeepWingRight.dx, ptDeepWingRight.dy)
        ..arcTo(deep3PtRect, angleWingRight3, angleWingLeft3 - angleWingRight3, false)
        ..close();
      canvas.drawPath(path, pC3);
    }

    // 10. Standard Right Wing 3
    final pRW3 = _getPaint('Right Wing 3');
    if (pRW3 != null) {
      final path = Path()
        ..moveTo(w, h * 0.28)
        ..lineTo(w * 0.93, h * 0.28)
        ..arcTo(threePtRect, angleCornerRight, angleWingRight3 - angleCornerRight, false)
        ..lineTo(ptDeepWingRight.dx, ptDeepWingRight.dy)
        ..arcTo(deep3PtRect, angleWingRight3, angleDeepCornerRight - angleWingRight3, false)
        ..lineTo(w, h * 0.3989)
        ..close();
      canvas.drawPath(path, pRW3);
    }

    // 11. Left Wing Deep 3
    final pLWD3 = _getPaint('Left Wing Deep 3');
    if (pLWD3 != null) {
      final path = Path()
        ..moveTo(0, h * 0.3989)
        ..arcTo(deep3PtRect, angleDeepCornerLeft, angleWingLeft3 - angleDeepCornerLeft, false)
        ..lineTo(w * 0.20, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(path, pLWD3);
    }

    // 12. Center Deep 3
    final pCD3 = _getPaint('Center Deep 3');
    if (pCD3 != null) {
      final path = Path()
        ..moveTo(ptDeepWingLeft.dx, ptDeepWingLeft.dy)
        ..arcTo(deep3PtRect, angleWingLeft3, angleWingRight3 - angleWingLeft3, false)
        ..lineTo(w * 0.80, h)
        ..lineTo(w * 0.20, h)
        ..close();
      canvas.drawPath(path, pCD3);
    }

    // 13. Right Wing Deep 3
    final pRWD3 = _getPaint('Right Wing Deep 3');
    if (pRWD3 != null) {
      final path = Path()
        ..moveTo(w, h * 0.3989)
        ..arcTo(deep3PtRect, angleDeepCornerRight, angleWingRight3 - angleDeepCornerRight, false)
        ..lineTo(w * 0.80, h)
        ..lineTo(w, h)
        ..close();
      canvas.drawPath(path, pRWD3);
    }
  }

  @override
  bool shouldRepaint(covariant ZoneHeatmapPainter oldDelegate) => true;
}

class ShotDotsPainter extends CustomPainter {
  final List<Shot> shots;

  ShotDotsPainter({required this.shots});

  @override
  void paint(Canvas canvas, Size size) {
    for (var shot in shots) {
      final Offset offset = Offset(shot.x * size.width, shot.y * size.height);

      final Paint fillPaint = Paint()
        ..color = shot.isMade
            ? const Color(0xFF2E7D32)
            : const Color(0xFFC62828)
        ..style = PaintingStyle.fill;

      final Paint outlinePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(
          offset + const Offset(1, 1), 7.0, Paint()..color = Colors.black45);
      canvas.drawCircle(offset, 7.0, fillPaint);
      canvas.drawCircle(offset, 7.0, outlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant ShotDotsPainter oldDelegate) => true;
}

class SelectedPositionPainter extends CustomPainter {
  final Offset? selectedPosition;

  SelectedPositionPainter({this.selectedPosition});

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedPosition == null) return;

    final Offset pos = Offset(
      selectedPosition!.dx * size.width,
      selectedPosition!.dy * size.height,
    );

    final Paint haloPaint = Paint()
      ..color = Colors.amber.shade700.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final Paint dotPaint = Paint()
      ..color = Colors.amber.shade900
      ..style = PaintingStyle.fill;

    final Paint strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(pos, 14.0, haloPaint);
    canvas.drawCircle(pos, 8.0, dotPaint);
    canvas.drawCircle(pos, 8.0, strokePaint);
  }

  @override
  bool shouldRepaint(covariant SelectedPositionPainter oldDelegate) =>
      oldDelegate.selectedPosition != selectedPosition;
}