/// Reusable form input field widget.
library;
import 'package:flutter/material.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

class FormInputField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final void Function(String)? onChanged;

  const FormInputField({
    super.key,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    required this.controller,
    this.validator,
    this.obscureText = false,
    this.onChanged,
  });

  @override
  State<FormInputField> createState() => _FormInputFieldState();
}

class _FormInputFieldState extends State<FormInputField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: _obscureText,
      onChanged: widget.onChanged,
      validator: widget.validator,
      decoration: AppTheme.buildInputDecoration(
        label: widget.label,
        hint: widget.hint,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _obscureText = !_obscureText);
                },
              )
            : null,
      ),
    );
  }
}

/// Reusable time picker button.
class TimePickerButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onTimeSelected;

  const TimePickerButton({
    super.key,
    required this.label,
    required this.time,
    required this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyLarge,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        GestureDetector(
          onTap: () => _selectTime(context),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: AppTheme.bodyLarge,
                ),
                const Icon(Icons.access_time, color: AppTheme.primaryColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: time,
    );

    if (picked != null && picked != time) {
      onTimeSelected(picked);
    }
  }
}

/// Reusable time range picker widget.
class TimeRangePickerWidget extends StatelessWidget {
  final String label;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final ValueChanged<(TimeOfDay, TimeOfDay)> onTimeRangeSelected;

  const TimeRangePickerWidget({
    super.key,
    required this.label,
    required this.startTime,
    required this.endTime,
    required this.onTimeRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.headingSmall,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Row(
          children: [
            Expanded(
              child: TimePickerButton(
                label: 'Start Time',
                time: startTime,
                onTimeSelected: (newStart) {
                  onTimeRangeSelected((newStart, endTime));
                },
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: TimePickerButton(
                label: 'End Time',
                time: endTime,
                onTimeSelected: (newEnd) {
                  onTimeRangeSelected((startTime, newEnd));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Reusable error message widget.
class ErrorMessage extends StatelessWidget {
  final String? message;

  const ErrorMessage({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        border: Border.all(color: AppTheme.errorColor),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Text(
              message!,
              style: const TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
