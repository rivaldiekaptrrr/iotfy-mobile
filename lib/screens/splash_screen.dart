import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/storage_providers.dart';
import 'dashboard_screen.dart';
import 'broker_list_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Main animations
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loadingController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  
  // Animation values
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotation;
  late Animation<double> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _loadingOpacity;
  late Animation<double> _pulse;
  
  // Loading state
  String _loadingText = 'Initializing...';
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimationSequence();
  }

  void _initAnimations() {
    // Logo animation controller (1.5s)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Text animation controller (1s, delayed)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Loading animation controller (continuous)
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Particle animation (continuous)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Pulse animation for glow effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Logo animations
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _logoRotation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Title animations
    _titleSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    _loadingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: Curves.easeIn,
      ),
    );

    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startAnimationSequence() async {
    // Start logo animation immediately
    _logoController.forward();

    // Start text animation after logo starts
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      _textController.forward();
    }

    // Start loading indicator
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      _loadingController.forward();
    }

    // Start initialization
    await _initialize();
  }

  Future<void> _initialize() async {
    // Step 1: Loading configurations
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _loadingText = 'Loading configurations...');
    }

    // Step 2: Checking brokers
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _loadingText = 'Checking MQTT brokers...');
    }

    // Step 3: Preparing dashboard
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _loadingText = 'Preparing dashboard...');
    }

    // Step 4: Final preparation
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() => _loadingText = 'Almost ready...');
    }

    // Navigate
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted && !_isNavigating) {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    _isNavigating = true;
    final currentDashboard = ref.read(currentDashboardIdProvider);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            currentDashboard != null
                ? const DashboardScreen()
                : const BrokerListScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          _buildGradientBackground(isDark),
          
          // Floating particles
          _buildParticles(isDark),
          
          // Glowing orbs
          _buildGlowingOrbs(isDark),
          
          // Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  
                  // Animated Logo
                  _buildAnimatedLogo(isDark),
                  
                  const SizedBox(height: 32),
                  
                  // Animated Title
                  _buildAnimatedTitle(),
                  
                  const SizedBox(height: 8),
                  
                  // Animated Subtitle
                  _buildAnimatedSubtitle(),
                  
                  const Spacer(flex: 2),
                  
                  // Loading section
                  _buildLoadingSection(isDark),
                  
                  const SizedBox(height: 48),
                  
                  // Version text
                  _buildVersionText(),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientBackground(bool isDark) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        // Subtle gradient shift animation
        final offset = math.sin(_particleController.value * math.pi * 2) * 0.1;
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.5 + offset, -1.0),
              end: Alignment(0.5 - offset, 1.0),
              colors: isDark
                  ? [
                      const Color(0xFF0A0E21),
                      const Color(0xFF0F172A),
                      const Color(0xFF1E1B4B),
                      const Color(0xFF0F172A),
                    ]
                  : [
                      const Color(0xFFF0F9FF),
                      const Color(0xFFE0F2FE),
                      const Color(0xFFEDE9FE),
                      const Color(0xFFF0F9FF),
                    ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticles(bool isDark) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            animation: _particleController.value,
            isDark: isDark,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildGlowingOrbs(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          children: [
            // Top-right orb
            Positioned(
              top: -100,
              right: -50,
              child: Transform.scale(
                scale: _pulse.value,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (isDark ? const Color(0xFF3B82F6) : const Color(0xFF60A5FA))
                            .withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom-left orb
            Positioned(
              bottom: -150,
              left: -100,
              child: Transform.scale(
                scale: 2.0 - _pulse.value,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (isDark ? const Color(0xFF8B5CF6) : const Color(0xFFA78BFA))
                            .withOpacity(0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedLogo(bool isDark) {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value * _pulse.value,
          child: Transform.rotate(
            angle: _logoRotation.value,
            child: Opacity(
              opacity: _logoOpacity.value,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF3B82F6),
                      const Color(0xFF2563EB),
                      const Color(0xFF7C3AED),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.3),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Inner glow
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    // Icon
                    const Icon(
                      Icons.hub,
                      size: 64,
                      color: Colors.white,
                    ),
                    // Orbiting dots
                    ..._buildOrbitingDots(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildOrbitingDots() {
    return List.generate(3, (index) {
      return AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          final angle = (_particleController.value * math.pi * 2) +
              (index * math.pi * 2 / 3);
          final x = math.cos(angle) * 80;
          final y = math.sin(angle) * 80;
          
          return Transform.translate(
            offset: Offset(x, y),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildAnimatedTitle() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _titleSlide.value),
          child: Opacity(
            opacity: _titleOpacity.value,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF3B82F6),
                  Color(0xFF8B5CF6),
                  Color(0xFF3B82F6),
                ],
              ).createShader(bounds),
              child: const Text(
                'IoTify Platform',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSubtitle() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Opacity(
          opacity: _subtitleOpacity.value,
          child: Text(
            'Smart IoT Dashboard with MQTT',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : Colors.black54,
              letterSpacing: 2,
              fontWeight: FontWeight.w300,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingSection(bool isDark) {
    return AnimatedBuilder(
      animation: _loadingController,
      builder: (context, child) {
        return Opacity(
          opacity: _loadingOpacity.value,
          child: Column(
            children: [
              // Custom loading indicator
              SizedBox(
                width: 200,
                child: _buildCustomLoadingIndicator(isDark),
              ),
              const SizedBox(height: 16),
              // Loading text with animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _loadingText,
                  key: ValueKey(_loadingText),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomLoadingIndicator(bool isDark) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
          child: Stack(
            children: [
              // Animated gradient bar
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      final progress = _particleController.value;
                      return LinearGradient(
                        begin: Alignment(-1.0 + progress * 3, 0),
                        end: Alignment(-0.5 + progress * 3, 0),
                        colors: const [
                          Colors.transparent,
                          Color(0xFF3B82F6),
                          Color(0xFF8B5CF6),
                          Color(0xFF3B82F6),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                      ).createShader(bounds);
                    },
                    child: Container(color: Colors.white),
                  ),
                ),
              ),
              // Glowing dots
              ...List.generate(3, (index) {
                final delay = index * 0.2;
                final wave = math.sin(
                  (_particleController.value * math.pi * 4) - delay * math.pi,
                );
                final position = ((wave + 1) / 2) * 196;
                
                return Positioned(
                  left: position,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.8),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVersionText() {
    return AnimatedBuilder(
      animation: _loadingController,
      builder: (context, child) {
        return Opacity(
          opacity: _loadingOpacity.value * 0.5,
          child: Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white38
                  : Colors.black38,
              letterSpacing: 1,
            ),
          ),
        );
      },
    );
  }
}

// Custom Particle Painter for floating particles effect
class ParticlePainter extends CustomPainter {
  final double animation;
  final bool isDark;
  final List<_Particle> particles;

  ParticlePainter({
    required this.animation,
    required this.isDark,
  }) : particles = _generateParticles();

  static List<_Particle> _generateParticles() {
    final random = math.Random(42); // Fixed seed for consistency
    return List.generate(50, (index) {
      return _Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 3 + 1,
        speed: random.nextDouble() * 0.5 + 0.2,
        opacity: random.nextDouble() * 0.5 + 0.1,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      // Calculate animated position
      final y = (particle.y + animation * particle.speed) % 1.0;
      final x = particle.x + math.sin(animation * math.pi * 2 * particle.speed) * 0.02;
      
      // Calculate position on canvas
      final px = x * size.width;
      final py = y * size.height;
      
      // Fade in/out near edges
      double opacity = particle.opacity;
      if (y < 0.1) opacity *= y / 0.1;
      if (y > 0.9) opacity *= (1 - y) / 0.1;
      
      paint.color = (isDark ? Colors.white : const Color(0xFF3B82F6))
          .withOpacity(opacity);
      
      canvas.drawCircle(Offset(px, py), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}
