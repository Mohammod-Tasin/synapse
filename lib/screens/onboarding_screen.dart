// Onboarding screen for collecting user preferences.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:no_to_distraction/models/user.dart';
import 'package:no_to_distraction/providers/auth_provider.dart';
import 'package:no_to_distraction/theme/app_theme.dart';
import 'package:no_to_distraction/widgets/form_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;

  // Preferences
  int _dailyFocusGoal = 120; // minutes
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile setup complete!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final steps = [_buildStep1(), _buildStep2(), _buildStep3()];

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress indicator
                    Row(
                      children: List.generate(
                        3,
                        (index) => Expanded(
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: index <= _currentStep
                                  ? AppTheme.primaryColor
                                  : AppTheme.borderColor,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSm,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    // Step content
                    steps[_currentStep],
                    const SizedBox(height: AppTheme.spacingXl),
                    // Buttons
                    ErrorMessage(message: authProvider.errorMessage),
                    if (authProvider.errorMessage != null)
                      const SizedBox(height: AppTheme.spacingMd),
                    Row(
                      children: [
                        if (_currentStep > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _safeSetState(() => _currentStep--);
                              },
                              child: const Text('Back'),
                            ),
                          ),
                        if (_currentStep > 0)
                          const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : () {
                                    if (_currentStep < 2) {
                                      _safeSetState(() => _currentStep++);
                                    } else {
                                      _submitOnboarding(authProvider);
                                    }
                                  },
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _currentStep < 2
                                        ? 'Next'
                                        : 'Complete Setup',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Daily Focus Goal', style: AppTheme.headingMedium),
        const SizedBox(height: AppTheme.spacingSm),
        const Text(
          'How many minutes a day do you want to focus?',
          style: AppTheme.bodyMedium,
        ),
        const SizedBox(height: AppTheme.spacingXl),
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                children: [
                  Text(
                    '$_dailyFocusGoal',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  const Text('minutes per day', style: AppTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Slider(
              value: _dailyFocusGoal.toDouble(),
              min: 15,
              max: 480,
              divisions: 93, // 15-minute increments
              activeColor: AppTheme.primaryColor,
              inactiveColor: AppTheme.borderColor,
              onChanged: (value) {
                _safeSetState(() => _dailyFocusGoal = value.toInt());
              },
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('15 min', style: AppTheme.bodySmall),
                Text('480 min (8h)', style: AppTheme.bodySmall),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Schedule', style: AppTheme.headingMedium),
        const SizedBox(height: AppTheme.spacingSm),
        const Text(
          'Tell us about your daily routine',
          style: AppTheme.bodyMedium,
        ),
        const SizedBox(height: AppTheme.spacingXl),
        TimeRangePickerWidget(
          label: 'Study Hours',
          startTime: _studyStart,
          endTime: _studyEnd,
          onTimeRangeSelected: (times) {
            _safeSetState(() {
              _studyStart = times.$1;
              _studyEnd = times.$2;
            });
          },
        ),
        const SizedBox(height: AppTheme.spacingLg),
        TimeRangePickerWidget(
          label: 'Sleep Time',
          startTime: _sleepStart,
          endTime: _sleepEnd,
          onTimeRangeSelected: (times) {
            _safeSetState(() {
              _sleepStart = times.$1;
              _sleepEnd = times.$2;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Work/Institution Hours', style: AppTheme.headingMedium),
        const SizedBox(height: AppTheme.spacingSm),
        const Text(
          'When are you at work or school?',
          style: AppTheme.bodyMedium,
        ),
        const SizedBox(height: AppTheme.spacingXl),
        TimeRangePickerWidget(
          label: 'Institution/Work Time',
          startTime: _institutionStart,
          endTime: _institutionEnd,
          onTimeRangeSelected: (times) {
            _safeSetState(() {
              _institutionStart = times.$1;
              _institutionEnd = times.$2;
            });
          },
        ),
        const SizedBox(height: AppTheme.spacingXl),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            children: const [
              Icon(Icons.check_circle, color: AppTheme.successColor),
              SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Text(
                  'All set! Tap Complete Setup to finish.',
                  style: AppTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
