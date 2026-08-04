import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _contentController;
  late AnimationController _fillController;
  late AnimationController _glowController;
  late AnimationController _bubbleController;
  late AnimationController _shimmerController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleFade;
  late Animation<double> _fillHeight;
  late Animation<double> _glowPulse;
  late Animation<double> _shimmer;

  final List<_Bubble> _bubbles = [];
  final List<_Bubble> _atmoBubbles = [];
  final math.Random _random = math.Random(12);

  @override
  void initState() {
    super.initState();
    _generateBubbles();
    _initAnimations();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _contentController.forward();
        _fillController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  void _initAnimations() {
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _bubbleController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    _fillController = AnimationController(
      duration: const Duration(milliseconds: 3200),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    _fillHeight = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeInOutCubic),
    );

    _glowPulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _shimmer = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  void _generateBubbles() {
    for (int i = 0; i < 35; i++) {
      _bubbles.add(_Bubble(
        x: _random.nextDouble(),
        startY: 0.65 + _random.nextDouble() * 0.35,
        radius: _random.nextDouble() * 10 + 3,
        speed: _random.nextDouble() * 0.20 + 0.06,
        opacity: _random.nextDouble() * 0.55 + 0.25,
        phase: _random.nextDouble(),
        wobble: _random.nextDouble() * 0.04 + 0.01,
      ));
    }
    for (int i = 0; i < 20; i++) {
      _atmoBubbles.add(_Bubble(
        x: _random.nextDouble(),
        startY: 0.2 + _random.nextDouble() * 0.8,
        radius: _random.nextDouble() * 4 + 1,
        speed: _random.nextDouble() * 0.12 + 0.04,
        opacity: _random.nextDouble() * 0.25 + 0.08,
        phase: _random.nextDouble(),
        wobble: _random.nextDouble() * 0.02 + 0.005,
      ));
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _contentController.dispose();
    _fillController.dispose();
    _glowController.dispose();
    _bubbleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF030912),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF030912),
                  Color(0xFF051525),
                  Color(0xFF071E38),
                ],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _glowPulse,
            builder: (_, __) => Positioned(
              top: -screenH * 0.1,
              left: screenW * 0.15,
              right: screenW * 0.15,
              height: screenH * 0.55,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00BCD4)
                          .withValues(alpha: 0.12 * _glowPulse.value),
                      blurRadius: 180,
                      spreadRadius: 60,
                    ),
                  ],
                ),
              ),
            ),
          ),

          RepaintBoundary(
            child: CustomPaint(painter: _StarsPainter()),
          ),

          AnimatedBuilder(
            animation: Listenable.merge([_waveController, _fillController]),
            builder: (_, __) => CustomPaint(
              painter: _WaterFillPainter(
                waveProgress: _waveController.value,
                fillProgress: _fillHeight.value,
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _bubbleController,
            builder: (_, __) => CustomPaint(
              painter: _BubblePainter(
                bubbles: _bubbles,
                atmoBubbles: _atmoBubbles,
                progress: _bubbleController.value,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                SizedBox(height: screenH * 0.10),

                AnimatedBuilder(
                  animation: _glowPulse,
                  builder: (_, __) => FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(
                                      alpha: 0.35 * _glowPulse.value),
                                  blurRadius: 80,
                                  spreadRadius: 20,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF0D47A1).withValues(
                                      alpha: 0.45 * _glowPulse.value),
                                  blurRadius: 50,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          ),
                          Image.asset(
                            'assets/icons/logo.png',
                            width: 150,
                            height: 150,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.water_drop_rounded,
                              color: Color(0xFF00E5FF),
                              size: 100,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: screenH * 0.04),

                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleFade,
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _shimmer,
                          builder: (_, child) => ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: const [
                                Color(0xFF4FC3F7),
                                Color(0xFFE0F7FA),
                                Color(0xFF00E5FF),
                                Color(0xFFFFFFFF),
                                Color(0xFF00BCD4),
                              ],
                              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                              begin: Alignment(_shimmer.value - 1, 0),
                              end: Alignment(_shimmer.value + 1, 0),
                            ).createShader(bounds),
                            child: const Text(
                              'TirtaSmart',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 4,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 50,
                              height: 1,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0xFF00E5FF),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF00E5FF),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF00E5FF),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 50,
                              height: 1,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF00E5FF),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                FadeTransition(
                  opacity: _subtitleFade,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 9),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0x2200E5FF),
                              Color(0x110D47A1),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFF00BCD4).withValues(alpha: 0.45),
                            width: 1.2,
                          ),
                        ),
                        child: const Text(
                          'Digitalisasi Air untuk Masa Depan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB3E5FC),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'MONITORING KUALITAS AIR PDAM',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF80B8D4),
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                FadeTransition(
                  opacity: _subtitleFade,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 50),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 160,
                          child: Stack(
                            children: [
                              Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color: const Color(0xFF0D2035),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _shimmerController,
                                builder: (_, __) => FractionallySizedBox(
                                  widthFactor:
                                      ((_shimmerController.value * 1.2)
                                              .clamp(0.0, 1.0)),
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF0D47A1),
                                          Color(0xFF00E5FF),
                                        ],
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0xFF00E5FF),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        const Text(
                          'Menginisialisasi sistem...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF7BBDD8),
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 28),

                        const Text(
                          'v1.0.0  •  firdanfauzan_',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF243040),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _Bubble {
  final double x;
  final double startY;
  final double radius;
  final double speed;
  final double opacity;
  final double phase;
  final double wobble;

  const _Bubble({
    required this.x,
    required this.startY,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.phase,
    this.wobble = 0.02,
  });
}

class _StarsPainter extends CustomPainter {
  static final List<Offset> _positions = [];
  static final List<double> _sizes = [];
  static bool _ready = false;

  _StarsPainter() {
    if (!_ready) {
      final r = math.Random(99);
      for (int i = 0; i < 70; i++) {
        _positions.add(Offset(r.nextDouble(), r.nextDouble()));
        _sizes.add(r.nextDouble() * 1.4 + 0.4);
      }
      _ready = true;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (int i = 0; i < _positions.length; i++) {
      final p = _positions[i];
      if (p.dy > 0.55) continue;
      paint.color =
          Colors.white.withValues(alpha: 0.12 + _sizes[i] * 0.12);
      canvas.drawCircle(
        Offset(p.dx * size.width, p.dy * size.height),
        _sizes[i],
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter _) => false;
}

class _WaterFillPainter extends CustomPainter {
  final double waveProgress;
  final double fillProgress;

  const _WaterFillPainter({
    required this.waveProgress,
    required this.fillProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxFill = size.height * 0.30;
    final fill = maxFill * fillProgress;
    final baseY = size.height - fill;

    _wave(canvas, size, baseY + 10,
        h: 20, freq: 1.2, spd: waveProgress,
        color: const Color(0xFF020C1A).withValues(alpha: 0.95));

    _wave(canvas, size, baseY + 2,
        h: 15, freq: 0.85, spd: waveProgress * 0.75 + 0.25,
        color: const Color(0xFF051830).withValues(alpha: 0.92));

    _wave(canvas, size, baseY - 6,
        h: 11, freq: 1.55, spd: waveProgress * 1.3,
        color: const Color(0xFF083060).withValues(alpha: 0.88));

    _wave(canvas, size, baseY - 12,
        h: 8, freq: 2.0, spd: waveProgress * 0.6 + 0.4,
        color: const Color(0xFF0A4080).withValues(alpha: 0.75));
  }

  void _wave(Canvas canvas, Size size, double yBase,
      {required double h,
      required double freq,
      required double spd,
      required Color color}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()..moveTo(0, yBase);
    for (double x = 0; x <= size.width; x++) {
      final angle =
          (x / size.width) * 2 * math.pi * freq + spd * 2 * math.pi;
      path.lineTo(x, yBase + math.sin(angle) * h);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WaterFillPainter old) =>
      old.waveProgress != waveProgress || old.fillProgress != fillProgress;
}

class _BubblePainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final List<_Bubble> atmoBubbles;
  final double progress;

  const _BubblePainter({
    required this.bubbles,
    required this.atmoBubbles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawWaterBubbles(canvas, size);
    _drawAtmoBubbles(canvas, size);
  }

  void _drawWaterBubbles(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final glow = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final highlight = Paint()..style = PaintingStyle.fill;

    for (final b in bubbles) {
      final rawY = (b.startY - progress * b.speed * 2.0 + b.phase) % 1.0;
      if (rawY < 0.68) continue;

      final wobbleX = math.sin(
              (progress * 2 * math.pi * 3) + b.phase * 2 * math.pi) *
          b.wobble *
          size.width;
      final px = (b.x * size.width + wobbleX).clamp(b.radius, size.width - b.radius);
      final py = rawY * size.height;

      final fadeIn  = ((rawY - 0.68) / 0.07).clamp(0.0, 1.0);
      final fadeOut = (1.0 - ((rawY - 0.92) / 0.08).clamp(0.0, 1.0));
      final alpha   = fadeIn * fadeOut * b.opacity;
      if (alpha <= 0) continue;

      glow.color = const Color(0xFF00E5FF).withValues(alpha: (alpha * 0.25).clamp(0, 1));
      canvas.drawCircle(Offset(px, py), b.radius * 1.6, glow);

      stroke.color = const Color(0xFF80DEEA).withValues(alpha: (alpha * 0.75).clamp(0, 1));
      canvas.drawCircle(Offset(px, py), b.radius, stroke);

      highlight.color = const Color(0xFF00BCD4).withValues(alpha: (alpha * 0.08).clamp(0, 1));
      canvas.drawCircle(Offset(px, py), b.radius, highlight);

      highlight.color = Colors.white.withValues(alpha: (alpha * 0.6).clamp(0, 1));
      canvas.drawCircle(
        Offset(px - b.radius * 0.30, py - b.radius * 0.30),
        b.radius * 0.25,
        highlight,
      );

      highlight.color = Colors.white.withValues(alpha: (alpha * 0.20).clamp(0, 1));
      canvas.drawCircle(
        Offset(px + b.radius * 0.35, py + b.radius * 0.25),
        b.radius * 0.12,
        highlight,
      );
    }
  }

  void _drawAtmoBubbles(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final highlight = Paint()..style = PaintingStyle.fill;

    for (final b in atmoBubbles) {
      final rawY = (b.startY - progress * b.speed * 1.2 + b.phase) % 1.0;

      final wobbleX = math.sin(
              (progress * 2 * math.pi * 2) + b.phase * 2 * math.pi) *
          b.wobble *
          size.width;
      final px = (b.x * size.width + wobbleX).clamp(b.radius, size.width - b.radius);
      final py = rawY * size.height;

      final fadeEdge = (rawY < 0.1
              ? rawY / 0.1
              : rawY > 0.9
                  ? (1.0 - rawY) / 0.1
                  : 1.0)
          .clamp(0.0, 1.0);
      final alpha = fadeEdge * b.opacity;
      if (alpha <= 0) continue;

      stroke.color = const Color(0xFF4DD0E1).withValues(alpha: (alpha * 0.55).clamp(0, 1));
      canvas.drawCircle(Offset(px, py), b.radius, stroke);

      highlight.color = Colors.white.withValues(alpha: (alpha * 0.35).clamp(0, 1));
      canvas.drawCircle(
        Offset(px - b.radius * 0.28, py - b.radius * 0.28),
        b.radius * 0.28,
        highlight,
      );
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.progress != progress;
}
