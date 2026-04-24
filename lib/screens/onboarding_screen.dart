library;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:no_to_distraction/models/auth.dart';
import 'package:no_to_distraction/providers/auth_provider.dart';
import 'package:no_to_distraction/providers/stats_provider.dart';
import 'package:no_to_distraction/theme/app_theme.dart';
import 'package:no_to_distraction/widgets/common/form_widgets.dart';
import 'package:no_to_distraction/widgets/synapse_illustrations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Preferences (unchanged logic)
  int _dailyFocusGoal = 120;
  TimeOfDay _studyStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _studyEnd = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _sleepStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _sleepEnd = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _institutionStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _institutionEnd = const TimeOfDay(hour: 17, minute: 0);

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _submitOnboarding(AuthProvider authProvider) async {
    final data = OnboardingData(
      dailyFocusGoalMinutes: _dailyFocusGoal,
      studyTime: TimeRange(
        startTime: AppTimeOfDay(
          hour: _studyStart.hour,
          minute: _studyStart.minute,
        ),
        endTime: AppTimeOfDay(hour: _studyEnd.hour, minute: _studyEnd.minute),
      ),
      sleepTime: TimeRange(
        startTime: AppTimeOfDay(
          hour: _sleepStart.hour,
          minute: _sleepStart.minute,
        ),
        endTime: AppTimeOfDay(hour: _sleepEnd.hour, minute: _sleepEnd.minute),
      ),
      institutionTime: TimeRange(
        startTime: AppTimeOfDay(
          hour: _institutionStart.hour,
          minute: _institutionStart.minute,
        ),
        endTime: AppTimeOfDay(
          hour: _institutionEnd.hour,
          minute: _institutionEnd.minute,
        ),
      ),
    );

    final success = await authProvider.submitOnboarding(data: data);
    if (success && mounted) {
      // Initialize stats for the newly onboarded user
      context.read<StatsProvider>().refreshAll();
      
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile setup complete!')));
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return Column(
              children: [
                // ── Dot indicators ──
                const SizedBox(height: AppTheme.spacingLg),
                _DotIndicator(count: 3, current: _currentPage),
                const SizedBox(height: AppTheme.spacingMd),

                // ── PageView ──
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) =>
                        _safeSetState(() => _currentPage = page),
                    children: [
                      _OnboardingPage(
                        illustration: const ReclaimTimeIllustration(),
                        headline: 'Reclaim Your Time',
                        subtitle:
                            'Set a daily focus goal and take control of how you spend your hours.',
                        content: _buildFocusGoalContent(),
                      ),
                      _OnboardingPage(
                        illustration: const EnhanceFocusIllustration(),
                        headline: 'Enhance Your Focus',
                        subtitle:
                            'Tell us your schedule so Synapse can protect your most productive hours.',
                        content: _buildScheduleContent(),
                      ),
                      _OnboardingPage(
                        illustration: const HabitLoopIllustration(),
                        headline: 'Rewire Your Habit Loop',
                        subtitle:
                            'Share your institution hours. We\'ll help you stay in flow when it matters most.',
                        content: _buildInstitutionContent(authProvider),
                      ),
                    ],
                  ),
                ),

                // ── Navigation buttons ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg,
                    AppTheme.spacingMd,
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                  ),
                  child: Column(
                    children: [
                      if (authProvider.errorMessage != null) ...[
                        ErrorMessage(message: authProvider.errorMessage),
                        const SizedBox(height: AppTheme.spacingMd),
                      ],
                      Row(
                        children: [
                          if (_currentPage > 0) ...[
                            Expanded(
                              child: SoftOutlinedButton(
                                label: 'Back',
                                onPressed: _prevPage,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                          ],
                          Expanded(
                            flex: 2,
                            child: GradientButton(
                              label: _currentPage < 2
                                  ? 'Continue'
                                  : 'Get Started →',
                              isLoading: authProvider.isLoading,
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () {
                                      if (_currentPage < 2) {
                                        _nextPage();
                                      } else {
                                        _submitOnboarding(authProvider);
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFocusGoalContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.spacingLg,
              horizontal: AppTheme.spacingXl,
            ),
            decoration: AppTheme.softCard(
              color: AppTheme.primaryColor.withValues(alpha: 0.06),
            ),
            child: Column(
              children: [
                Text(
                  '$_dailyFocusGoal',
                  style: GoogleFonts.inter(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text('minutes per day', style: AppTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: AppTheme.borderColor,
              thumbColor: AppTheme.primaryColor,
              overlayColor: AppTheme.primaryColor.withValues(alpha: 0.12),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _dailyFocusGoal.toDouble(),
              min: 15,
              max: 960,
              divisions: 63,
              onChanged: (v) =>
                  _safeSetState(() => _dailyFocusGoal = v.toInt()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('15 min', style: AppTheme.bodySmall),
              Text('16 hours', style: AppTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        children: [
          TimeRangePickerWidget(
            label: 'Study Hours',
            startTime: _studyStart,
            endTime: _studyEnd,
            onTimeRangeSelected: (times) => _safeSetState(() {
              _studyStart = times.$1;
              _studyEnd = times.$2;
            }),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          TimeRangePickerWidget(
            label: 'Sleep Time',
            startTime: _sleepStart,
            endTime: _sleepEnd,
            onTimeRangeSelected: (times) => _safeSetState(() {
              _sleepStart = times.$1;
              _sleepEnd = times.$2;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInstitutionContent(AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        children: [
          TimeRangePickerWidget(
            label: 'Institution / Work Hours',
            startTime: _institutionStart,
            endTime: _institutionEnd,
            onTimeRangeSelected: (times) => _safeSetState(() {
              _institutionStart = times.$1;
              _institutionEnd = times.$2;
            }),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: AppTheme.softCard(
              color: AppTheme.successColor.withValues(alpha: 0.08),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppTheme.successColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Text(
                    'All set! Tap Get Started to begin your focus journey.',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.successColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// A single onboarding page with illustration + headline + content.
// ─────────────────────────────────────────────────────────────────────────────
class _OnboardingPage extends StatelessWidget {
  final Widget illustration;
  final String headline;
  final String subtitle;
  final Widget content;

  const _OnboardingPage({
    required this.illustration,
    required this.headline,
    required this.subtitle,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spacingMd),
          illustration,
          const SizedBox(height: AppTheme.spacingLg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            child: Column(
              children: [
                Text(
                  headline,
                  style: AppTheme.headingMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  subtitle,
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          content,
          const SizedBox(height: AppTheme.spacingMd),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Animated dot page indicator.
// ─────────────────────────────────────────────────────────────────────────────
class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;

  const _DotIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primaryColor
                : AppTheme.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
        );
      }),
    );
  }
}
