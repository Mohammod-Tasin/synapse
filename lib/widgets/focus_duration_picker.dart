import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

class FocusDurationPicker extends StatefulWidget {
  final List<String> selectedDistractingApps;
  final Future<List<String>> Function() onManageApps;
  final Function(int) onDurationSelected;

  const FocusDurationPicker({
    required this.selectedDistractingApps,
    required this.onManageApps,
    required this.onDurationSelected,
    super.key,
  });

  @override
  State<FocusDurationPicker> createState() => _FocusDurationPickerState();
}

class _FocusDurationPickerState extends State<FocusDurationPicker> {
  int _selectedDuration = 25;
  bool _isRefreshingApps = false;
  late List<String> _selectedApps;

  @override
  void initState() {
    super.initState();
    _selectedApps = List<String>.from(widget.selectedDistractingApps);
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours h';
    return '$hours h $mins m';
  }

  Future<void> _manageApps() async {
    setState(() => _isRefreshingApps = true);
    try {
      final updatedApps = await widget.onManageApps();
      if (!mounted) return;
      setState(() => _selectedApps = updatedApps);
    } finally {
      if (mounted) setState(() => _isRefreshingApps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Start Focus Mode',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimaryColor,
        ),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
          maxWidth: 420,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select duration:', style: AppTheme.bodyMedium),
              const SizedBox(height: AppTheme.spacingSm),
              Center(
                child: Text(
                  _formatDuration(_selectedDuration),
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppTheme.primaryColor,
                  inactiveTrackColor: AppTheme.borderColor,
                  thumbColor: AppTheme.primaryColor,
                  overlayColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _selectedDuration.toDouble(),
                  min: 5,
                  max: 720,
                  divisions: 143,
                  label: _formatDuration(_selectedDuration),
                  onChanged: (v) =>
                      setState(() => _selectedDuration = v.toInt()),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final d in [15, 25, 45, 60, 90, 120, 180, 360, 720])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_formatDuration(d)),
                          selected: _selectedDuration == d,
                          onSelected: (_) =>
                              setState(() => _selectedDuration = d),
                          selectedColor: AppTheme.primaryColor.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: AppTheme.warningColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Distracting apps', style: AppTheme.bodyLarge),
                    const SizedBox(height: AppTheme.spacingSm),
                    if (_selectedApps.isEmpty)
                      Text(
                        'No apps selected. You can continue anyway.',
                        style: AppTheme.bodySmall,
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedApps
                            .map(
                              (name) => Chip(
                                label: Text(name),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: AppTheme.spacingSm),
                    TextButton.icon(
                      onPressed: _isRefreshingApps ? null : _manageApps,
                      icon: _isRefreshingApps
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Manage App List'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        textStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('During focus mode:', style: AppTheme.bodyLarge),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      '✓ Reels and Shorts will be blocked',
                      style: AppTheme.bodySmall,
                    ),
                    Text(
                      '✓ Selected apps will be blocked',
                      style: AppTheme.bodySmall,
                    ),
                    Text(
                      '✓ Motivational quotes will be shown',
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onDurationSelected(_selectedDuration);
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: 10,
            ),
          ),
          child: Text(
            'Start Focus',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
