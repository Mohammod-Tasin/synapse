/// Synapse — Neuro-Minimalist Form Widgets
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
/// Soft, rounded input field consistent with Neuro-Minimalist design.
// ─────────────────────────────────────────────────────────────────────────────
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
      style: GoogleFonts.inter(
        fontSize: 14,
        color: AppTheme.textPrimaryColor,
      ),
      decoration: AppTheme.buildInputDecoration(
        label: widget.label,
        hint: widget.hint,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppTheme.textSecondaryColor,
                  size: 20,
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

// ─────────────────────────────────────────────────────────────────────────────
/// Gradient primary action button.
// ─────────────────────────────────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: onPressed != null
            ? AppTheme.primaryGradient
            : const LinearGradient(
                colors: [Color(0xFFB0BEC5), Color(0xFFCFD8DC)],
              ),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Soft secondary / outline button.
// ─────────────────────────────────────────────────────────────────────────────
class SoftOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? textColor;

  const SoftOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? AppTheme.primaryColor;
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.4), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          backgroundColor: color.withValues(alpha: 0.04),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Soft error message banner with rose background.
// ─────────────────────────────────────────────────────────────────────────────
class ErrorMessage extends StatelessWidget {
  final String? message;

  const ErrorMessage({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm + 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: AppTheme.errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 18),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              message!,
              style: GoogleFonts.inter(
                color: AppTheme.errorColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Soft time picker button with rounded filled styling.
// ─────────────────────────────────────────────────────────────────────────────
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
        Text(label, style: AppTheme.bodyMedium),
        const SizedBox(height: AppTheme.spacingSm),
        GestureDetector(
          onTap: () => _selectTime(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: AppTheme.inputFillColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const Icon(
                  Icons.access_time_rounded,
                  color: AppTheme.primaryColor,
                  size: 18,
                ),
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

// ─────────────────────────────────────────────────────────────────────────────
/// Time range picker with two TimePickerButton children.
// ─────────────────────────────────────────────────────────────────────────────
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
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: AppTheme.softCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.headingSmall),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: TimePickerButton(
                  label: 'Start',
                  time: startTime,
                  onTimeSelected: (newStart) {
                    onTimeRangeSelected((newStart, endTime));
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: TimePickerButton(
                  label: 'End',
                  time: endTime,
                  onTimeSelected: (newEnd) {
                    onTimeRangeSelected((startTime, newEnd));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
