import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class OrbWidget extends StatefulWidget {
  final double size;
  final bool isLive;
  final bool isSpeaking;
  final VoidCallback? onTap;
  final Widget? icon;

  const OrbWidget({
    super.key,
    this.size = 150,
    this.isLive = false,
    this.isSpeaking = false,
    this.onTap,
    this.icon,
  });

  @override
  State<OrbWidget> createState() => _OrbWidgetState();
}

class _OrbWidgetState extends State<OrbWidget>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant OrbWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking != oldWidget.isSpeaking) {
      _pulseController.duration = widget.isSpeaking
          ? const Duration(milliseconds: 800)
          : const Duration(milliseconds: 2400);
      if (_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaleAnim = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size * 1.8,
        height: widget.size * 1.8,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ripple 1
            if (widget.isLive || widget.isSpeaking)
              AnimatedBuilder(
                animation: _rippleController,
                builder: (context, child) {
                  final progress = _rippleController.value;
                  final rScale = 1.0 + progress * 0.9;
                  final rOpacity = (1.0 - progress).clamp(0.0, 0.7);
                  return Transform.scale(
                    scale: rScale,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.darkAccent.withOpacity(rOpacity),
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Ripple 2 (Offset by 0.5)
            if (widget.isLive || widget.isSpeaking)
              AnimatedBuilder(
                animation: _rippleController,
                builder: (context, child) {
                  final progress = (_rippleController.value + 0.5) % 1.0;
                  final rScale = 1.0 + progress * 0.9;
                  final rOpacity = (1.0 - progress).clamp(0.0, 0.7);
                  return Transform.scale(
                    scale: rScale,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.darkAccent.withOpacity(rOpacity),
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Core Orb with Glowing Radial Gradients
            AnimatedBuilder(
              animation: scaleAnim,
              builder: (context, child) {
                final curScale = (widget.isLive || widget.isSpeaking)
                    ? scaleAnim.value
                    : 1.0;
                return Transform.scale(
                  scale: curScale,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(0.0, 0.2),
                        radius: 0.85,
                        colors: [
                          AppColors.darkAccent,
                          Color(0xFF88D93A),
                          AppColors.darkBlob2,
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkAccent.withOpacity(0.55),
                          blurRadius: 50,
                          spreadRadius: 2,
                          offset: const Offset(0, 16),
                        ),
                        const BoxShadow(
                          color: Colors.white38,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: widget.icon ??
                          Icon(
                            widget.isLive ? Icons.mic : Icons.mic_none,
                            size: widget.size * 0.32,
                            color: AppColors.darkAccentInk,
                          ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
