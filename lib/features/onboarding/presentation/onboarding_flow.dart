import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/section_card.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/auth_repository.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final PageController _controller = PageController();
  int _pageIndex = 0;
  bool _submitting = false;

  // true until we discover the backend has disabled anonymous logins
  bool _anonymousAllowed = true;

  late final TextEditingController _dailySpendController;
  late final TextEditingController _dailyTimeController;

  final List<String> _habits = const <String>[
    'Alcohol',
    'Smoking',
    'Drugs',
    'Quit Porn',
    'Quit Masturbation',
    'Other',
  ];

  String _habit = 'Alcohol';
  String _customHabit = '';
  DateTime _startDate = DateTime.now();
  String _motivation = '';
  double _dailySpend = 0;
  int _dailyTime = 0;
  File? _motivationPhoto;

  @override
  void initState() {
    super.initState();
    _dailySpendController = TextEditingController();
    _dailyTimeController = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _dailySpendController.dispose();
    _dailyTimeController.dispose();
    super.dispose();
  }

  void _next() {
    if (_pageIndex >= 4) return;
    _controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_pageIndex == 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    setState(() {
      _motivationPhoto = File(image.path);
    });
  }

  /// Prompt the user for email authentication and repeat onboarding.
  Future<void> _promptForEmail(AuthRepository authRepo) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _EmailAuthDialog(
        authRepo: authRepo,
        initialIsSignUp: true,
      ),
    );
    if (!mounted) return;
    if (result == true) {
      await _completeOnboarding();
    } else {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _completeOnboarding() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final authRepo = ref.read(authRepositoryProvider);
    final profileRepo = ref.read(profileRepositoryProvider);
    final settings = ref.read(settingsControllerProvider.notifier);
    final profileController = ref.read(profileControllerProvider.notifier);

    try {
      AppLogger.info('🔄 [ONBOARDING] _handleSignUp() START');
      User? user = Supabase.instance.client.auth.currentUser;
      AppLogger.info('🔄 [ONBOARDING] Current user: ${user?.id}');

      if (user == null) {
        if (!_anonymousAllowed) {
          await _promptForEmail(authRepo);
          return;
        }

        AppLogger.info(
            '🔄 [ONBOARDING] No current user, attempting anonymous sign-in...');
        try {
          AppLogger.info(
              '🔄 [ONBOARDING] Calling authRepo.signInAnonymously()...');
          user = (await authRepo.signInAnonymously()).user;
          AppLogger.info(
              '✅ [ONBOARDING] Anonymous sign-in SUCCESS: userId=${user?.id}');
        } catch (e, stackTrace) {
          if (e is AuthApiException &&
              e.code == 'anonymous_provider_disabled') {
            AppLogger.warn(
                '⚠️ [ONBOARDING] Anonymous sign-in disabled by backend');
            setState(() => _anonymousAllowed = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Anonymous login is disabled. Please create an account using email.'),
                  duration: Duration(seconds: 5),
                ),
              );
            }
            if (mounted) await _promptForEmail(authRepo);
            return;
          }
          AppLogger.error('onboarding.auth', e, stackTrace);
          if (mounted) {
            final message = switch (e) {
              AppAuthException() => e.message,
              AuthException() => e.message,
              _ => e.toString(),
            };
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message.trim().isEmpty
                    ? 'Failed to create session.'
                    : 'Failed to create session: $message'),
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      }

      if (user == null) {
        AppLogger.error(
            'onboarding.auth', 'User is still null after all attempts');
        throw Exception('Unable to create session.');
      }

      final existingProfile = await profileRepo.fetchProfile();
      if (existingProfile != null) {
        AppLogger.info(
            '✅ [ONBOARDING] Existing profile found, redirecting to home');
        await settings.setOnboardingComplete(true);
        await profileController.load();
        if (mounted) {
          context.go('/');
        }
        return;
      }

      String? photoUrl;
      if (_motivationPhoto != null) {
        try {
          AppLogger.info('➕ [ONBOARDING] Uploading motivation photo...');
          photoUrl = await profileRepo.uploadMotivationPhoto(
            _motivationPhoto!,
            userId: user.id,
          );
          AppLogger.info('✅ [ONBOARDING] Photo uploaded: $photoUrl');
        } catch (e) {
          AppLogger.warn(
              '⚠️ [ONBOARDING] Photo upload failed (continuing): $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo upload failed. Continuing without it.'),
              ),
            );
          }
        }
      }

      final profile = UserProfile(
        id: user.id,
        soberStartDate: _startDate,
        habitName: _habit,
        habitCustomName:
            _customHabit.trim().isEmpty ? null : _customHabit.trim(),
        dailySpend: _dailySpend <= 0 ? null : _dailySpend,
        dailyTimeSpent: _dailyTime <= 0 ? null : _dailyTime,
        motivationText: _motivation.trim().isEmpty ? null : _motivation.trim(),
        motivationPhotoUrl: photoUrl,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      await profileRepo.createProfile(profile);
      await settings.setOnboardingComplete(true);
      await profileController.load();
      if (mounted) {
        context.go('/');
      }
    } catch (error, stackTrace) {
      AppLogger.error('onboarding.complete', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final media = MediaQuery.of(context);
      final padding = media.padding;

      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: <Widget>[
                    if (_pageIndex > 0)
                      IconButton(
                        onPressed: _back,
                        icon: const Icon(Icons.arrow_back),
                      ),
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: (_pageIndex + 1) / 5),
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${_pageIndex + 1}/5'),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (index) => setState(() => _pageIndex = index),
                  children: <Widget>[
                    _WelcomeStep(
                      onNext: _next,
                      onSignIn: () async {
                        final authRepo = ref.read(authRepositoryProvider);
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => _EmailAuthDialog(
                            authRepo: authRepo,
                            initialIsSignUp: false,
                          ),
                        );
                        if (result == true) {
                          await _completeOnboarding();
                        }
                      },
                    ),
                    _HabitStep(
                      habits: _habits,
                      habit: _habit,
                      customHabit: _customHabit,
                      spendController: _dailySpendController,
                      timeController: _dailyTimeController,
                      onChanged: (habit, custom, spend, time) {
                        setState(() {
                          _habit = habit;
                          _customHabit = custom;
                          _dailySpend = spend;
                          _dailyTime = time;
                        });
                      },
                      onNext: _next,
                    ),
                    _StartDateStep(
                      startDate: _startDate,
                      onDateChanged: (date) =>
                          setState(() => _startDate = date),
                      onNext: _next,
                    ),
                    _MotivationStep(
                      motivation: _motivation,
                      photo: _motivationPhoto,
                      onChanged: (value) => setState(() => _motivation = value),
                      onPickPhoto: _pickPhoto,
                      onNext: _next,
                    ),
                    _FinishStep(
                      padding: padding,
                      onSubmit: _completeOnboarding,
                      submitting: _submitting,
                      anonymousAllowed: _anonymousAllowed,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error('onboarding.build', error, stackTrace);
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'An unexpected error occurred while opening onboarding.\n'
              'Please try again later.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }
  }
}

class _WelcomeStep extends StatefulWidget {
  const _WelcomeStep({
    required this.onNext,
    required this.onSignIn,
  });

  final VoidCallback onNext;
  final Future<void> Function() onSignIn;

  @override
  State<_WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<_WelcomeStep> {
  static const _autoSlideDuration = Duration(seconds: 4);
  static const _slideAnimationDuration = Duration(milliseconds: 650);

  late final PageController _imageController;
  Timer? _autoTimer;
  int _currentIndex = 0;

  final List<_IntroSlide> _slides = const <_IntroSlide>[
    _IntroSlide(
      title: 'Find your calm',
      subtitle: 'Track sober time and celebrate every steady step.',
      imageUrl:
          'https://cdn.jsdelivr.net/npm/undraw-svg@1.0.0/svgs/a-moment-to-relax.svg',
    ),
    _IntroSlide(
      title: 'Reflect daily',
      subtitle: 'Capture wins, cravings, and motivation in a private journal.',
      imageUrl:
          'https://cdn.jsdelivr.net/npm/undraw-svg@1.0.0/svgs/add-notes.svg',
    ),
    _IntroSlide(
      title: 'Lean on community',
      subtitle: 'Anonymous support from people walking the same road.',
      imageUrl:
          'https://cdn.jsdelivr.net/npm/undraw-svg@1.0.0/svgs/online-community.svg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _imageController = PageController();
    // start timer after first frame to avoid firing during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _autoTimer = Timer.periodic(_autoSlideDuration, (_) => _advanceSlide());
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _imageController.dispose();
    super.dispose();
  }

  void _advanceSlide() {
    if (!mounted || !_imageController.hasClients) return;
    final nextIndex = (_currentIndex + 1) % _slides.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_imageController.hasClients) return;
      _imageController.animateToPage(
        nextIndex,
        duration: _slideAnimationDuration,
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 32),
          Text(
            AppStrings.appName,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.tagline,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: PageView.builder(
                    controller: _imageController,
                    itemCount: _slides.length,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) =>
                        setState(() => _currentIndex = index),
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return AnimatedBuilder(
                        animation: _imageController,
                        builder: (context, child) {
                          var scale = 1.0;
                          if (_imageController.hasClients &&
                              _imageController.position.haveDimensions) {
                            final page = _imageController.page ??
                                _imageController.initialPage.toDouble();
                            final distance =
                                (page - index).abs().clamp(0.0, 1.0);
                            scale = 1.0 - (distance * 0.06);
                          }
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: SvgPicture.network(
                                  slide.imageUrl,
                                  fit: BoxFit.contain,
                                  colorFilter: ColorFilter.mode(
                                    colorScheme.primary.withValues(alpha: 0.85),
                                    BlendMode.modulate,
                                  ),
                                  placeholderBuilder: (context) => Center(
                                    child: SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              slide.subtitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _SlideDots(
                  count: _slides.length,
                  currentIndex: _currentIndex,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Get Started', onPressed: widget.onNext),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: widget.onSignIn,
              child: const Text('Already have an account? Sign in'),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroSlide {
  const _IntroSlide({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
}

class _SlideDots extends StatelessWidget {
  const _SlideDots({
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final selected = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: selected ? 22 : 8,
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary
                : colorScheme.primary.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _HabitStep extends StatelessWidget {
  const _HabitStep({
    required this.habits,
    required this.habit,
    required this.customHabit,
    required this.spendController,
    required this.timeController,
    required this.onChanged,
    required this.onNext,
  });

  final List<String> habits;
  final String habit;
  final String customHabit;
  final TextEditingController spendController;
  final TextEditingController timeController;
  final void Function(String habit, String custom, double spend, int time)
      onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 420;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(
          'What are you focusing on?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          'Pick one. You can add more later.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: habits.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 3 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final item = habits[index];
            final selected = habit == item;
            final icon = _habitIcon(item);
            final caption = _habitCaption(item);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              decoration: BoxDecoration(
                color: selected
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? colorScheme.primary.withValues(alpha: 0.6)
                      : colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onChanged(
                  item,
                  customHabit,
                  double.tryParse(spendController.text) ?? 0,
                  int.tryParse(timeController.text) ?? 0,
                ),
                child: Stack(
                  children: <Widget>[
                    if (selected)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Icon(
                          Icons.check_circle,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? colorScheme.primary.withValues(alpha: 0.15)
                                  : colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              icon,
                              color: selected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            caption,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: habit == 'Other'
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SectionCard(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Custom habit name',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => onChanged(
                        habit,
                        value,
                        double.tryParse(spendController.text) ?? 0,
                        int.tryParse(timeController.text) ?? 0,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 20),
        Text(
          'Baseline (optional)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            children: <Widget>[
              TextField(
                controller: spendController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Daily spend (USD)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => onChanged(
                  habit,
                  customHabit,
                  double.tryParse(value) ?? 0,
                  int.tryParse(timeController.text) ?? 0,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minutes spent daily',
                  prefixIcon: Icon(Icons.timelapse),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => onChanged(
                  habit,
                  customHabit,
                  double.tryParse(spendController.text) ?? 0,
                  int.tryParse(value) ?? 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: 'Continue', onPressed: onNext),
      ],
    );
  }
}

IconData _habitIcon(String habit) {
  switch (habit) {
    case 'Alcohol':
      return Icons.local_bar;
    case 'Smoking':
      return Icons.smoking_rooms;
    case 'Drugs':
      return Icons.medication;
    case 'Quit Porn':
      return Icons.visibility_off;
    case 'Quit Masturbation':
      return Icons.self_improvement;
    case 'Other':
      return Icons.add_circle_outline;
    default:
      return Icons.check_circle_outline;
  }
}

String _habitCaption(String habit) {
  switch (habit) {
    case 'Alcohol':
      return 'Cut back or quit drinking.';
    case 'Smoking':
      return 'Break the nicotine loop.';
    case 'Drugs':
      return 'Stay clean and steady.';
    case 'Quit Porn':
      return 'Reset your focus.';
    case 'Quit Masturbation':
      return 'Build healthier habits.';
    case 'Other':
      return 'Name your own focus.';
    default:
      return '';
  }
}

class _StartDateStep extends StatelessWidget {
  const _StartDateStep({
    required this.startDate,
    required this.onDateChanged,
    required this.onNext,
  });

  final DateTime startDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'When did you start?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            'You can always adjust this later.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: startDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (selected != null) {
                onDateChanged(selected);
              }
            },
            icon: const Icon(Icons.calendar_today),
            label:
                Text('${startDate.month}/${startDate.day}/${startDate.year}'),
          ),
          const Spacer(),
          PrimaryButton(label: 'Continue', onPressed: onNext),
        ],
      ),
    );
  }
}

class _MotivationStep extends StatelessWidget {
  const _MotivationStep({
    required this.motivation,
    required this.photo,
    required this.onChanged,
    required this.onPickPhoto,
    required this.onNext,
  });

  final String motivation;
  final File? photo;
  final ValueChanged<String> onChanged;
  final VoidCallback onPickPhoto;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(
          'Your motivation',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        TextField(
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Write a note to your future self…',
            border: OutlineInputBorder(),
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: onPickPhoto,
              icon: const Icon(Icons.photo),
              label: const Text('Add photo'),
            ),
            if (photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  photo!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        PrimaryButton(label: 'Continue', onPressed: onNext),
      ],
    );
  }
}

class _FinishStep extends ConsumerWidget {
  const _FinishStep({
    required this.padding,
    required this.onSubmit,
    required this.submitting,
    required this.anonymousAllowed,
  });

  final EdgeInsets padding;
  final VoidCallback onSubmit;
  final bool submitting;
  final bool anonymousAllowed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepo = ref.read(authRepositoryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + padding.bottom),
      children: <Widget>[
        Text(
          'You’re all set.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose how you want to start. You can always change this later.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: <Color>[
                colorScheme.primary.withValues(alpha: 0.14),
                colorScheme.secondary.withValues(alpha: 0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'What you’ll get',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              const _FinishBenefit(
                icon: Icons.timer_outlined,
                label: 'Live sober timer and milestones',
              ),
              const SizedBox(height: 8),
              const _FinishBenefit(
                icon: Icons.book_outlined,
                label: 'Private journal with photo memories',
              ),
              const SizedBox(height: 8),
              const _FinishBenefit(
                icon: Icons.people_outline,
                label: 'Anonymous community support',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label:
              anonymousAllowed ? 'Continue anonymously' : 'Anonymous disabled',
          onPressed: (submitting || !anonymousAllowed) ? null : onSubmit,
          isLoading: submitting,
        ),
        const SizedBox(height: 12),
        SecondaryButton(
          label: 'Use email instead',
          onPressed: submitting
              ? null
              : () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => _EmailAuthDialog(authRepo: authRepo),
                  );
                  if (result == true) {
                    onSubmit();
                  }
                },
        ),
        const SizedBox(height: 8),
        Text(
          'Anonymous mode keeps you private. You can link an email anytime.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _FinishBenefit extends StatelessWidget {
  const _FinishBenefit({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 18,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _EmailAuthDialog extends StatefulWidget {
  const _EmailAuthDialog({
    required this.authRepo,
    this.initialIsSignUp = true,
  });

  final AuthRepository authRepo;
  final bool initialIsSignUp;

  @override
  State<_EmailAuthDialog> createState() => _EmailAuthDialogState();
}

class _EmailAuthDialogState extends State<_EmailAuthDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late bool _isSignUp;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter both email and password.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      if (_isSignUp) {
        final result = await widget.authRepo.signUpWithEmail(
          email,
          password,
        );
        if (result.needsEmailConfirmation) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Check your email to confirm your account, then sign in.',
              ),
            ),
          );
          return;
        }
      } else {
        await widget.authRepo.signInWithEmail(
          email,
          password,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      AppLogger.error('onboarding.emailAuth', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isSignUp ? 'Create account' : 'Sign in'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              child: Text(_isSignUp
                  ? 'Already have an account? Sign in'
                  : 'Need an account? Sign up'),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: Text(_loading ? 'Please wait…' : 'Continue'),
        ),
      ],
    );
  }
}
