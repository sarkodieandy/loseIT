import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/widgets/discipline_button.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_mark.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../../../../core/widgets/discipline_text_field.dart';
import '../auth_flow.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _didAttempt = false;

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

  void _continue() {
    setState(() => _didAttempt = true);

    if (!_isValidEmail(_email.text)) {
      _emailFocus.requestFocus();
      return;
    }
    if (_password.text.trim().isEmpty) {
      _passwordFocus.requestFocus();
      return;
    }

    TextInput.finishAutofillContext(shouldSave: true);
    Navigator.of(context).pushNamed(AuthFlow.biometric);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isWide = media.size.width >= 540;
    final isCompactHeight = media.size.height < 760;
    final sidePadding = isWide ? 32.0 : 24.0;
    final maxContentWidth = isWide ? 460.0 : double.infinity;

    final emailError = _didAttempt && !_isValidEmail(_email.text)
        ? 'Enter a valid email address.'
        : null;
    final passwordError = _didAttempt && _password.text.trim().isEmpty
        ? 'Password cannot be empty.'
        : null;

    return DisciplineScaffold(
      title: 'Log In',
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
                        'Welcome back.',
                        style: DisciplineTextStyles.title,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sign in to restore your private system and streak data.',
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
                              CupertinoIcons.person_crop_circle_badge_checkmark,
                              color: DisciplineColors.accent,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Fast sign-in with Face ID available after login.',
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
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
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
                            Align(
                              alignment: Alignment.centerRight,
                              child: DisciplineTextButton(
                                label: 'Forgot password?',
                                color: DisciplineColors.accent,
                                onPressed: () {
                                  showCupertinoDialog<void>(
                                    context: context,
                                    builder: (_) => CupertinoAlertDialog(
                                      title: const Text('Recovery'),
                                      content: const Text(
                                        'Connect password recovery service here.',
                                      ),
                                      actions: <CupertinoDialogAction>[
                                        CupertinoDialogAction(
                                          isDefaultAction: true,
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isCompactHeight ? 10 : 14),
                      DisciplineButton(
                        label: 'Continue',
                        onPressed: _continue,
                      ),
                      DisciplineTextButton(
                        label: 'Need an account? Create one',
                        onPressed: () => Navigator.of(context).pop(),
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
