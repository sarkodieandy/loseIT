import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/theme/discipline_tokens.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/widgets/discipline_button.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_mark.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../../../../core/widgets/discipline_text_field.dart';
import '../../../../services/supabase/supabase_error_text.dart';
import '../auth_flow.dart';

class EmailSignUpScreen extends StatefulWidget {
  const EmailSignUpScreen({super.key});

  @override
  State<EmailSignUpScreen> createState() => _EmailSignUpScreenState();
}

class _EmailSignUpScreenState extends State<EmailSignUpScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _didAttempt = false;
  bool _authBusy = false;

  @override
  void initState() {
    super.initState();
    _email.addListener(_onChanged);
    _password.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _email.removeListener(_onChanged);
    _password.removeListener(_onChanged);
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    final text = value.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
  }

  _PasswordReport _passwordReport(String value) => _PasswordReport(value);

  Future<void> _continue() async {
    setState(() => _didAttempt = true);

    final emailValid = _isValidEmail(_email.text);
    final passwordOk = _passwordReport(_password.text).meetsMinimum;
    if (!emailValid) {
      _emailFocus.requestFocus();
      return;
    }
    if (!passwordOk) {
      _passwordFocus.requestFocus();
      return;
    }

    if (_authBusy) return;

    TextInput.finishAutofillContext(shouldSave: true);
    setState(() => _authBusy = true);
    final app = AppScope.of(context);
    try {
      await app.services.auth.signUpWithEmail(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamed(AuthFlow.biometric);
    } catch (error, stackTrace) {
      AppLogger.error('EmailSignUpScreen._continue', error, stackTrace);
      if (!mounted) return;
      await showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Sign up failed'),
          content: Text(supabaseErrorText(error)),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _authBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isWide = media.size.width >= 540;
    final isCompactHeight = media.size.height < 760;
    final sidePadding = isWide ? 32.0 : 24.0;
    final maxContentWidth = isWide ? 460.0 : double.infinity;

    final emailValid = _isValidEmail(_email.text);
    final report = _passwordReport(_password.text);

    final emailError =
        _didAttempt && !emailValid ? 'Enter a valid email address.' : null;
    final passwordError = _didAttempt && !report.meetsMinimum
        ? 'Use at least 8 characters.'
        : null;

    return DisciplineScaffold(
      title: 'Sign Up',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Center(child: DisciplineMark(size: 54)),
                      SizedBox(height: isCompactHeight ? 14 : 16),
                      const Text(
                        'Continue with email.',
                        style: DisciplineTextStyles.title,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'One account. Private by default.',
                        style: DisciplineTextStyles.secondary
                            .copyWith(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isCompactHeight ? 14 : 16),
                      DisciplineCard(
                        shadow: false,
                        borderColor: DisciplineColors.accent.withValues(
                          alpha: 0.34,
                        ),
                        color: DisciplineColors.surface.withValues(alpha: 0.78),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              CupertinoIcons.shield_lefthalf_fill,
                              color: DisciplineColors.accent,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No marketing spam. Your data stays private.',
                                style: DisciplineTextStyles.caption.copyWith(
                                  color: DisciplineColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isCompactHeight ? 14 : 16),
                      AutofillGroup(
                        child: Column(
                          children: <Widget>[
                            DisciplineTextField(
                              label: 'Email',
                              placeholder: 'you@domain.com',
                              controller: _email,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const <String>[
                                AutofillHints.email
                              ],
                              errorText: emailError,
                              onSubmitted: (_) => _passwordFocus.requestFocus(),
                            ),
                            const SizedBox(height: 14),
                            DisciplineTextField(
                              label: 'Password',
                              placeholder: '••••••••',
                              controller: _password,
                              focusNode: _passwordFocus,
                              keyboardType: TextInputType.visiblePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const <String>[
                                AutofillHints.password,
                              ],
                              obscureText: _obscurePassword,
                              errorText: passwordError,
                              onSubmitted: (_) => _continue(),
                              suffix: CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                minimumSize: Size.zero,
                                onPressed: _authBusy
                                    ? null
                                    : () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                child: Icon(
                                  _obscurePassword
                                      ? CupertinoIcons.eye
                                      : CupertinoIcons.eye_slash,
                                  size: 18,
                                  color: DisciplineColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _PasswordStrengthCard(report: report),
                      SizedBox(height: isCompactHeight ? 14 : 18),
                      Text(
                        'By continuing you agree to the Terms and Privacy Policy.',
                        style: DisciplineTextStyles.caption.copyWith(
                          color: DisciplineColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      DisciplineTextButton(
                        label: 'Already have an account? Log in',
                        onPressed: _authBusy
                            ? null
                            : () =>
                                Navigator.of(context).pushNamed(AuthFlow.login),
                      ),
                      SizedBox(height: isCompactHeight ? 10 : 12),
                      DisciplineButton(
                        label: _authBusy ? 'Creating account…' : 'Create account',
                        onPressed: _authBusy ? null : _continue,
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

class _PasswordStrengthCard extends StatelessWidget {
  const _PasswordStrengthCard({required this.report});

  final _PasswordReport report;

  Color get _activeColor {
    return switch (report.level) {
      _PasswordStrength.weak => DisciplineColors.danger,
      _PasswordStrength.ok => DisciplineColors.warning,
      _PasswordStrength.strong => DisciplineColors.accent,
    };
  }

  String get _label {
    return switch (report.level) {
      _PasswordStrength.weak => 'Weak',
      _PasswordStrength.ok => 'OK',
      _PasswordStrength.strong => 'Strong',
    };
  }

  Widget _segment(BuildContext context, {required bool active}) {
    return Expanded(
      child: AnimatedContainer(
        duration: DisciplineMotion.medium,
        curve: DisciplineMotion.standard,
        height: 8,
        decoration: BoxDecoration(
          color: active ? _activeColor : DisciplineColors.surface2,
          borderRadius: BorderRadius.circular(DisciplineRadii.pill),
          boxShadow: active
              ? <BoxShadow>[
                  BoxShadow(
                    color: _activeColor.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  Widget _check({required String label, required bool ok}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          AnimatedContainer(
            duration: DisciplineMotion.fast,
            curve: DisciplineMotion.standard,
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: ok ? _activeColor.withValues(alpha: 0.16) : null,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: (ok ? _activeColor : DisciplineColors.border)
                    .withValues(alpha: 0.75),
              ),
            ),
            child: Icon(
              ok ? CupertinoIcons.check_mark : CupertinoIcons.minus,
              size: 12,
              color: ok ? _activeColor : DisciplineColors.textTertiary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: DisciplineTextStyles.caption.copyWith(
                color: ok
                    ? DisciplineColors.textPrimary
                    : DisciplineColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = report.score;

    return DisciplineCard(
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('Password strength',
                  style: DisciplineTextStyles.caption),
              AnimatedSwitcher(
                duration: DisciplineMotion.fast,
                switchInCurve: DisciplineMotion.standard,
                switchOutCurve: DisciplineMotion.standard,
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Text(
                  _label,
                  key: ValueKey<String>(_label),
                  style: DisciplineTextStyles.caption.copyWith(
                    color: _activeColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              _segment(context, active: score >= 1),
              const SizedBox(width: 8),
              _segment(context, active: score >= 2),
              const SizedBox(width: 8),
              _segment(context, active: score >= 3),
            ],
          ),
          const SizedBox(height: 12),
          _check(label: '8+ characters', ok: report.lengthOk),
          _check(label: '1 number', ok: report.numberOk),
          _check(label: '1 symbol', ok: report.symbolOk),
        ],
      ),
    );
  }
}

enum _PasswordStrength { weak, ok, strong }

class _PasswordReport {
  _PasswordReport(String password)
      : lengthOk = password.length >= 8,
        numberOk = RegExp(r'\d').hasMatch(password),
        symbolOk = RegExp(r'[^A-Za-z0-9]').hasMatch(password);

  final bool lengthOk;
  final bool numberOk;
  final bool symbolOk;

  bool get meetsMinimum => lengthOk;

  int get score => <bool>[lengthOk, numberOk, symbolOk].where((v) => v).length;

  _PasswordStrength get level {
    if (score >= 3) return _PasswordStrength.strong;
    if (score >= 2) return _PasswordStrength.ok;
    return _PasswordStrength.weak;
  }
}
