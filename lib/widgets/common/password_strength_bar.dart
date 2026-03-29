import 'package:flutter/material.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

/// Animated gradient password strength bar.
class PasswordStrengthBar extends StatelessWidget {
  final String password;
  const PasswordStrengthBar({required this.password, super.key});

  int get _strength {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*]'))) score++;
    return score;
  }

  String get _label {
    final s = _strength;
    if (s <= 1) return 'Weak';
    if (s <= 3) return 'Fair';
    return 'Strong';
  }

  Color get _color {
    final s = _strength;
    if (s <= 1) return const Color(0xFFEF5350);
    if (s <= 3) return const Color(0xFFFFB74D);
    return AppTheme.successColor;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = (_strength / 5).clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: AppTheme.borderColor,
                valueColor: AlwaysStoppedAnimation<Color>(_color),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Text(
          _label,
          style: AppTheme.bodySmall.copyWith(
            color: _color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
