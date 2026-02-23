import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Generates App Store review-ready screenshots for the paywall.
//
// Run:
//   flutter test --update-goldens test/appstore/paywall_review_screenshot_test.dart
//
// Output:
//   tool/appstore/paywall_review_1170x2532.png
//   tool/appstore/paywall_review_1290x2796.png
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final outDir = Directory('tool/appstore');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);

    goldenFileComparator = LocalFileComparator(outDir.absolute.uri);
  });

  Future<void> _pumpSized(
    WidgetTester tester, {
    required Size physicalSize,
    required double dpr,
  }) async {
    final binding = tester.binding;
    binding.window.devicePixelRatioTestValue = dpr;
    binding.window.physicalSizeTestValue = physicalSize;
    addTearDown(() {
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    await tester.pumpWidget(const _PaywallScreenshotApp());
    await tester.pumpAndSettle();
  }

  testWidgets('Paywall review screenshot (iPhone 13/14 - 1170x2532)',
      (tester) async {
    await _pumpSized(
      tester,
      physicalSize: const Size(1170, 2532),
      dpr: 3,
    );

    await expectLater(
      find.byKey(const Key('golden')),
      matchesGoldenFile('paywall_review_1170x2532.png'),
    );
  });

  testWidgets('Paywall review screenshot (iPhone 14 Pro Max - 1290x2796)',
      (tester) async {
    await _pumpSized(
      tester,
      physicalSize: const Size(1290, 2796),
      dpr: 3,
    );

    await expectLater(
      find.byKey(const Key('golden')),
      matchesGoldenFile('paywall_review_1290x2796.png'),
    );
  });
}

class _PaywallScreenshotApp extends StatelessWidget {
  const _PaywallScreenshotApp();

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _PaywallColors.accent,
        secondary: _PaywallColors.green,
        surface: _PaywallColors.card,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(scaffoldBackgroundColor: _PaywallColors.bgTop),
      home: const RepaintBoundary(
        key: Key('golden'),
        child: _PaywallReviewScreen(),
      ),
    );
  }
}

class _PaywallColors {
  static const Color bgTop = Color(0xFF050607);
  static const Color bgBottom = Color(0xFF0B0E11);
  static const Color card = Color(0xFF0E1216);
  static const Color cardBorder = Color(0x1AFFFFFF);
  static const Color muted = Color(0xFF9AA3AB);
  static const Color accent = Color(0xFF26B7FF);
  static const Color green = Color(0xFF19C37D);
  static const Color amber = Color(0xFFFFB020);
}

class _PaywallReviewScreen extends StatelessWidget {
  const _PaywallReviewScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              _PaywallColors.bgTop,
              _PaywallColors.bgBottom,
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            const _GlowBlob(
              alignment: Alignment(-0.9, -0.8),
              size: 260,
              color: _PaywallColors.accent,
              opacity: 0.35,
            ),
            const _GlowBlob(
              alignment: Alignment(1.0, -0.6),
              size: 220,
              color: _PaywallColors.green,
              opacity: 0.22,
            ),
            const _GlowBlob(
              alignment: Alignment(0.6, 0.9),
              size: 280,
              color: _PaywallColors.amber,
              opacity: 0.15,
            ),
            SafeArea(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Be Sober Pro',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            height: 1.05,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Personalized insights + accountability tools to keep you consistent.',
                                      style: TextStyle(
                                        color: _PaywallColors.muted,
                                        fontSize: 15,
                                        height: 1.35,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              const _IconCircle(icon: Icons.close),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: <Widget>[
                              _Pill(
                                  icon: Icons.shield_outlined,
                                  label: 'Private'),
                              _Pill(
                                  icon: Icons.auto_graph,
                                  label: 'Weekly insights'),
                              _Pill(
                                  icon: Icons.groups_2_outlined,
                                  label: 'Groups + chat'),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const _FeatureCard(),
                          const SizedBox(height: 18),
                          Text(
                            'Choose your plan',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 12),
                          const _PlanCard(
                            title: 'Monthly',
                            subtitle: 'Full access · billed monthly',
                            price: r'$4.99 / mo',
                            badge: 'Flexible',
                            selected: false,
                          ),
                          const SizedBox(height: 12),
                          const _PlanCard(
                            title: 'Yearly',
                            subtitle: 'Best for streaks · billed annually',
                            price: r'$39.99 / yr',
                            badge: 'Best value',
                            selected: true,
                          ),
                          const SizedBox(height: 12),
                          const _PlanCard(
                            title: 'Lifetime',
                            subtitle: 'One-time purchase · forever access',
                            price: r'$99.99 once',
                            badge: 'Own it',
                            selected: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _PaywallColors.accent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: () {},
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 2,
                          children: <Widget>[
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor: _PaywallColors.muted,
                              ),
                              child: const Text(
                                'Restore',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const Text(
                              '·',
                              style: TextStyle(
                                color: _PaywallColors.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor: _PaywallColors.muted,
                              ),
                              child: const Text(
                                'Terms & Privacy',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Cancel anytime in App Store settings.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _PaywallColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.alignment,
    required this.size,
    required this.color,
    required this.opacity,
  });

  final Alignment alignment;
  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0),
              ],
              stops: const <double>[0.0, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _PaywallColors.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _PaywallColors.cardBorder),
      ),
      child: Icon(icon, color: _PaywallColors.muted, size: 20),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: _PaywallColors.muted),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: _PaywallColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _PaywallColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _PaywallColors.cardBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _BenefitRow(
            icon: Icons.insights_outlined,
            title: 'Weekly insights',
            subtitle:
                'See what helps you stay consistent (and what trips you up).',
          ),
          SizedBox(height: 12),
          _BenefitRow(
            icon: Icons.chat_bubble_outline,
            title: 'Groups + group chat',
            subtitle: 'Private circles for accountability and support.',
          ),
          SizedBox(height: 12),
          _BenefitRow(
            icon: Icons.auto_graph,
            title: 'Advanced tracking',
            subtitle: 'Multiple habits, streak history, and progress trends.',
          ),
          SizedBox(height: 12),
          _BenefitRow(
            icon: Icons.self_improvement_outlined,
            title: 'Craving rescue tools',
            subtitle: 'Fast routines to ride out urges when it’s hardest.',
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _PaywallColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _PaywallColors.accent.withValues(alpha: 0.25),
            ),
          ),
          child: Icon(icon, color: _PaywallColors.accent, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _PaywallColors.muted,
                  fontSize: 13,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.badge,
    required this.selected,
  });

  final String title;
  final String subtitle;
  final String price;
  final String badge;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? _PaywallColors.accent : _PaywallColors.cardBorder;
    final bg = selected
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              _PaywallColors.accent.withValues(alpha: 0.20),
              _PaywallColors.card.withValues(alpha: 1),
            ],
          )
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _PaywallColors.card,
        gradient: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor.withValues(alpha: 0.70)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: selected ? 0.40 : 0.25),
            blurRadius: selected ? 26 : 18,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    _PlanBadge(
                      label: badge,
                      selected: selected,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _PaywallColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            price,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final bg =
        selected ? _PaywallColors.accent : Colors.white.withValues(alpha: 0.06);
    final fg = selected ? Colors.black : _PaywallColors.muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
