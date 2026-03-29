/// Profile Settings Screen
/// Allows the user to view and edit their onboarding preferences.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:no_to_distraction/models/user.dart';
import 'package:no_to_distraction/services/api_service.dart';
import 'package:no_to_distraction/theme/app_theme.dart';
import 'package:no_to_distraction/widgets/form_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Defaults fallback
  int _dailyFocusGoal = 120;
  TimeOfDay _studyStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _studyEnd = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _sleepStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _sleepEnd = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _institutionStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _institutionEnd = const TimeOfDay(hour: 17, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _loadProfileData() async {
    _safeSetState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getOnboardingData();
      if (data != null && mounted) {
        _safeSetState(() {
          _dailyFocusGoal = data.dailyFocusGoalMinutes;
          
          _studyStart = TimeOfDay(hour: data.studyTime.startTime.hour, minute: data.studyTime.startTime.minute);
          _studyEnd = TimeOfDay(hour: data.studyTime.endTime.hour, minute: data.studyTime.endTime.minute);
          
          _sleepStart = TimeOfDay(hour: data.sleepTime.startTime.hour, minute: data.sleepTime.startTime.minute);
          _sleepEnd = TimeOfDay(hour: data.sleepTime.endTime.hour, minute: data.sleepTime.endTime.minute);
          
          _institutionStart = TimeOfDay(hour: data.institutionTime.startTime.hour, minute: data.institutionTime.startTime.minute);
          _institutionEnd = TimeOfDay(hour: data.institutionTime.endTime.hour, minute: data.institutionTime.endTime.minute);
        });
      }
    } catch (e) {
      _safeSetState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      _safeSetState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    _safeSetState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final data = OnboardingData(
        dailyFocusGoalMinutes: _dailyFocusGoal,
        studyTime: TimeRange(
          startTime: AppTimeOfDay(hour: _studyStart.hour, minute: _studyStart.minute),
          endTime: AppTimeOfDay(hour: _studyEnd.hour, minute: _studyEnd.minute),
        ),
        sleepTime: TimeRange(
          startTime: AppTimeOfDay(hour: _sleepStart.hour, minute: _sleepStart.minute),
          endTime: AppTimeOfDay(hour: _sleepEnd.hour, minute: _sleepEnd.minute),
        ),
        institutionTime: TimeRange(
          startTime: AppTimeOfDay(hour: _institutionStart.hour, minute: _institutionStart.minute),
          endTime: AppTimeOfDay(hour: _institutionEnd.hour, minute: _institutionEnd.minute),
        ),
      );

      await _apiService.submitOnboarding(data: data);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully!')),
        );
        Navigator.pop(context); // Go back to Home
      }
    } catch (e) {
      _safeSetState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      _safeSetState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile Settings',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      ErrorMessage(message: _errorMessage),
                      const SizedBox(height: AppTheme.spacingMd),
                    ],

                    Text(
                      'Daily Focus Goal',
                      style: AppTheme.headingSmall,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _buildFocusGoalContent(),
                    
                    const SizedBox(height: AppTheme.spacingXl),

                    Text(
                      'Your Schedule',
                      style: AppTheme.headingSmall,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    
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
                    const SizedBox(height: AppTheme.spacingMd),

                    TimeRangePickerWidget(
                      label: 'Institution / Work Hours',
                      startTime: _institutionStart,
                      endTime: _institutionEnd,
                      onTimeRangeSelected: (times) => _safeSetState(() {
                        _institutionStart = times.$1;
                        _institutionEnd = times.$2;
                      }),
                    ),

                    const SizedBox(height: 48),

                    GradientButton(
                      label: 'Save Changes',
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _saveChanges,
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFocusGoalContent() {
    return Container(
      decoration: AppTheme.softCard(
        color: AppTheme.surfaceColor,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.spacingMd,
              horizontal: AppTheme.spacingLg,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              children: [
                Text(
                  '$_dailyFocusGoal',
                  style: GoogleFonts.inter(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text('minutes per day', style: AppTheme.bodySmall),
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
              onChanged: (v) => _safeSetState(() => _dailyFocusGoal = v.toInt()),
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
}
