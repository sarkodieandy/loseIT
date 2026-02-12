import 'package:flutter/cupertino.dart';

import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/theme/discipline_tokens.dart';
import '../../../../core/widgets/discipline_button.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_mark.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../../../../core/widgets/fade_in.dart';
import '../auth_flow.dart';
import '../widgets/social_auth_button.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isWide = media.size.width >= 540;
    final isCompactHeight = media.size.height < 760;
    final sidePadding = isWide ? 32.0 : 24.0;
    final maxContentWidth = isWide ? 460.0 : double.infinity;

    return DisciplineScaffold(
      padding: EdgeInsets.symmetric(horizontal: sidePadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bottomInset = media.viewInsets.bottom;
          final minHeight = (constraints.maxHeight - bottomInset)
              .clamp(0.0, double.infinity)
              .toDouble();
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              top: isCompactHeight ? 12 : 20,
              bottom: bottomInset + (isCompactHeight ? 14 : 24),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const FadeIn(
                        child: Center(
                          child: DisciplineMark(size: 64),
                        ),
                      ),
                      SizedBox(height: isCompactHeight ? 14 : 18),
                      const FadeIn(
                        delay: Duration(milliseconds: 40),
                        child: Text(
                          'Create your account.',
                          style: DisciplineTextStyles.title,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FadeIn(
                        delay: const Duration(milliseconds: 80),
                        child: Text(
                          'Build a private recovery system in under a minute.',
                          style: DisciplineTextStyles.secondary
                              .copyWith(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: isCompactHeight ? 14 : 16),
                      FadeIn(
                        delay: const Duration(milliseconds: 105),
                        child: DisciplineCard(
                          shadow: false,
                          borderColor: DisciplineColors.accent.withValues(
                            alpha: 0.38,
                          ),
                          color:
                              DisciplineColors.surface.withValues(alpha: 0.78),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                CupertinoIcons.lock_shield_fill,
                                color: DisciplineColors.accent,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Start free. Cancel anytime.',
                                  style: DisciplineTextStyles.caption.copyWith(
                                    color: DisciplineColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                'No spam',
                                style: DisciplineTextStyles.caption.copyWith(
                                  color: DisciplineColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isCompactHeight ? 14 : 18),
                      FadeIn(
                        delay: const Duration(milliseconds: 130),
                        child: SocialAuthButton(
                          label: 'Continue with Apple',
                          leading: const Text(''),
                          style: SocialAuthButtonStyle.primary,
                          onPressed: () => Navigator.of(context)
                              .pushNamed(AuthFlow.biometric),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeIn(
                        delay: const Duration(milliseconds: 160),
                        child: SocialAuthButton(
                          label: 'Continue with Google',
                          icon: CupertinoIcons.globe,
                          onPressed: () => Navigator.of(context)
                              .pushNamed(AuthFlow.biometric),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeIn(
                        delay: const Duration(milliseconds: 190),
                        child: SocialAuthButton(
                          label: 'Continue with Email',
                          icon: CupertinoIcons.mail_solid,
                          onPressed: () => Navigator.of(context)
                              .pushNamed(AuthFlow.emailSignUp),
                        ),
                      ),
                      SizedBox(height: isCompactHeight ? 14 : 18),
                      FadeIn(
                        delay: const Duration(milliseconds: 220),
                        child: Row(
                          children: <Widget>[
                            const Expanded(child: _Divider()),
                            const SizedBox(width: 12),
                            Text(
                              'or',
                              style: DisciplineTextStyles.caption.copyWith(
                                color: DisciplineColors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: _Divider()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      FadeIn(
                        delay: const Duration(milliseconds: 250),
                        child: DisciplineTextButton(
                          label: 'Continue anonymously',
                          onPressed: () => Navigator.of(context)
                              .pushNamed(AuthFlow.biometric),
                          color: DisciplineColors.textSecondary,
                        ),
                      ),
                      FadeIn(
                        delay: const Duration(milliseconds: 280),
                        child: DisciplineTextButton(
                          label: 'Already have an account? Log in',
                          onPressed: () =>
                              Navigator.of(context).pushNamed(AuthFlow.login),
                          color: DisciplineColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FadeIn(
                        delay: const Duration(milliseconds: 310),
                        child: Row(
                          children: const <Widget>[
                            Expanded(
                              child: _TrustPill(
                                icon: CupertinoIcons.lock_fill,
                                label: 'Encrypted',
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _TrustPill(
                                icon: CupertinoIcons.eye_slash_fill,
                                label: 'Alias only',
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isCompactHeight ? 10 : 14),
                      FadeIn(
                        delay: const Duration(milliseconds: 330),
                        child: Text(
                          'By continuing you agree to the Terms and Privacy Policy.',
                          style: DisciplineTextStyles.caption.copyWith(
                            color: DisciplineColors.textTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: DisciplineColors.border.withValues(alpha: 0.75),
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DisciplineColors.surface2.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(DisciplineRadii.field),
        border: Border.all(
          color: DisciplineColors.border.withValues(alpha: 0.72),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 14, color: DisciplineColors.textSecondary),
          const SizedBox(width: 7),
          Text(
            label,
            style: DisciplineTextStyles.caption.copyWith(
              color: DisciplineColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
