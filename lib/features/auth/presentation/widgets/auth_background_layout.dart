import 'package:flutter/material.dart';

class AuthBackgroundLayout extends StatelessWidget {
  final List<Widget> children;

  const AuthBackgroundLayout({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background nebula with radial gradient
          Positioned.fill(
            child: Stack(
              children: [
                // Black background
                Container(
                  color: Colors.black,
                ),
                // Nebula image with radial mask
                Positioned(
                  top: screenSize.height * 0.44,
                  left: 0,
                  right: 0,
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.2,
                        colors: [
                          Colors.white.withAlpha(255),
                          Colors.white.withAlpha(204),
                          Colors.white.withAlpha(102),
                          Colors.white.withAlpha(0),
                        ],
                        stops: const [0.0, 0.3, 0.6, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: SizedBox(
                      width: screenSize.width,
                      height: screenSize.height * 0.4,
                      child: Image.asset(
                        'assets/images/nebula_bg.webp',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                // Additional radial gradient for smooth transition
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, 0.4),
                      radius: 0.8,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(128),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenSize.height * 0.015),
                  // Logo
                  Image.asset(
                    'assets/images/logo.png',
                    width: 48,
                    height: 48,
                  ),

                  SizedBox(height: screenSize.height * 0.02),
                  // Text section
                  const Text(
                    'Read',
                    style: TextStyle(
                      fontFamily: 'PaytoneOne',
                      fontSize: 48,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                  const Text(
                    'Memo',
                    style: TextStyle(
                      fontFamily: 'PaytoneOne',
                      fontSize: 48,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                  const Text(
                    'Insight',
                    style: TextStyle(
                      fontFamily: 'PaytoneOne',
                      fontSize: 48,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),

                  ...children, // 추가 위젯들을 여기에 삽입
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
