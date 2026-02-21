import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/widgets/discipline_button.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';

class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;
  String? _statusMessage;

  String _messageForPlatformException(PlatformException error) {
    final code = error.code.toLowerCase();

    if (code.contains('notavailable')) {
      return 'Biometric authentication is not available on this device.';
    }
    if (code.contains('notenrolled')) {
      return 'No biometrics are enrolled. Add Face ID in system settings.';
    }
    if (code.contains('passcodenotset')) {
      return 'Set a device passcode before enabling Face ID.';
    }
    if (code.contains('lockedout')) {
      return 'Biometrics are temporarily locked. Unlock the device and try again.';
    }

    final raw = error.message?.trim();
    if (raw != null && raw.isNotEmpty) {
      return raw;
    }
    return 'Face ID could not be verified. Please try again.';
  }

  Future<void> _enableFaceId(AppController app) async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _statusMessage = null;
    });

    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!supported || !canCheckBiometrics) {
        setState(() {
          _statusMessage =
              'Biometric authentication is not available on this device.';
        });
        return;
      }

      final available = await _localAuth.getAvailableBiometrics();
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          !available.contains(BiometricType.face)) {
        setState(() {
          _statusMessage =
              'Face ID is not available. Enable Face ID in iOS settings.';
        });
        return;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason:
            'Authenticate with Face ID to protect your Discipline account.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );

      if (!mounted) return;

      if (didAuthenticate) {
        app.completeAuth(biometricEnabled: true);
      } else {
        setState(() {
          _statusMessage = 'Face ID verification did not complete. Try again.';
        });
      }
    } on PlatformException catch (error, stackTrace) {
      AppLogger.error('BiometricSetupScreen._enableFaceId.platform', error,
          stackTrace);
      if (!mounted) return;
      setState(() {
        _statusMessage = _messageForPlatformException(error);
      });
    } catch (error, stackTrace) {
      AppLogger.error('BiometricSetupScreen._enableFaceId', error, stackTrace);
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Face ID could not be verified. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return DisciplineScaffold(
      title: 'Face ID',
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 28),
          const Icon(
            CupertinoIcons.lock_shield,
            size: 56,
            color: DisciplineColors.accent,
          ),
          const SizedBox(height: 16),
          const Text('Secure access.', style: DisciplineTextStyles.title),
          const SizedBox(height: 10),
          Text(
            'Use Face ID to keep your Discipline system private.',
            style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          DisciplineCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Recommended', style: DisciplineTextStyles.caption),
                const SizedBox(height: 10),
                Text(
                  'Protects sensitive analytics, relapse predictions, and emergency logs.',
                  style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 12),
            DisciplineCard(
              shadow: false,
              borderColor: DisciplineColors.danger.withValues(alpha: 0.5),
              color: DisciplineColors.danger.withValues(alpha: 0.12),
              child: Text(
                _statusMessage!,
                style: DisciplineTextStyles.caption.copyWith(
                  color: DisciplineColors.textPrimary,
                ),
              ),
            ),
          ],
          const Spacer(),
          DisciplineButton(
            label: _isAuthenticating ? 'Verifying Face ID…' : 'Enable Face ID',
            onPressed: _isAuthenticating ? null : () => _enableFaceId(app),
          ),
          const SizedBox(height: 12),
          DisciplineButton(
            label: 'Not now',
            variant: DisciplineButtonVariant.secondary,
            onPressed: _isAuthenticating
                ? null
                : () => app.completeAuth(biometricEnabled: false),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
