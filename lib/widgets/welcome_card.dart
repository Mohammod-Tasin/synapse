import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:no_to_distraction/theme/app_theme.dart';
import 'package:no_to_distraction/widgets/synapse_illustrations.dart';

class WelcomeCard extends StatelessWidget {
  final String? name;
  final bool isLoadingStats;
  final int focusScore;

  const WelcomeCard({
    required this.name,
    required this.isLoadingStats,
    required this.focusScore,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: AppTheme.softCard(radius: AppTheme.radiusLg),
      child: Row(
        children: [
          // Left: greeting text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${name ?? 'there'} 👋',
                  style: AppTheme.headingSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready to focus today?',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Base Focus Score',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Right: score badge
          if (isLoadingStats)
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
          else
            FocusScoreBadge(score: focusScore, size: 110),
        ],
      ),
    );
  }
}
