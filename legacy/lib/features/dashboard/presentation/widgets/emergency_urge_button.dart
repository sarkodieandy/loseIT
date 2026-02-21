import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';

class EmergencyUrgeButton extends StatefulWidget {
  const EmergencyUrgeButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  State<EmergencyUrgeButton> createState() => _EmergencyUrgeButtonState();
}

class _EmergencyUrgeButtonState extends State<EmergencyUrgeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_pulse.value);
        final glowOpacity = (0.10 + (t * 0.12)).clamp(0.0, 0.28);
        final glowScale = 1.0 + (t * 0.03);

        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Transform.scale(
              scale: glowScale,
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  color: DisciplineColors.danger.withValues(alpha: glowOpacity),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.onPressed();
                },
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: DisciplineColors.danger,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: DisciplineColors.dangerGlow.withValues(alpha: 0.9),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color:
                            DisciplineColors.dangerGlow.withValues(alpha: 0.55),
                        blurRadius: 26,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'I Feel an Urge',
                      style: DisciplineTextStyles.button,
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
}
