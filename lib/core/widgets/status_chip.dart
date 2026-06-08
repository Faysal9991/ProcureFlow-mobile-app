import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'app_icons.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(context, status);
    final label = status.trim().replaceAll('_', ' ').toUpperCase();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context, String value) {
    final normalized = value.toLowerCase();

    if (normalized.contains('approved') ||
        normalized.contains('synced') ||
        normalized.contains('completed') ||
        normalized.contains('success') ||
        normalized.contains('paid')) {
      return AppColors.success;
    }

    if (normalized.contains('pending') ||
        normalized.contains('submitted') ||
        normalized.contains('waiting') ||
        normalized.contains('processing')) {
      return AppColors.warning;
    }

    if (normalized.contains('rejected') ||
        normalized.contains('failed') ||
        normalized.contains('cancelled') ||
        normalized.contains('canceled') ||
        normalized.contains('error')) {
      return AppColors.error;
    }

    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60);
  }
}

class Timeline extends StatelessWidget {
  const Timeline({super.key, required this.steps});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (var index = 0; index < steps.length; index++)
          _TimelineRow(step: steps[index], isLast: index == steps.length - 1),
      ],
    );
  }
}

class TimelineStep {
  const TimelineStep({
    required this.title,
    required this.subtitle,
    required this.complete,
  });

  final String title;
  final String subtitle;
  final bool complete;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.isLast});

  final TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withValues(alpha: 0.45);

    final color = step.complete ? activeColor : inactiveColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: step.complete
                    ? activeColor.withValues(alpha: 0.12)
                    : theme.colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              child: Icon(
                step.complete ? AppIcons.check : AppIcons.circle,
                size: 16,
                color: color,
              ),
            ),
            if (!isLast)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 1.5,
                height: 34,
                color: color.withValues(alpha: 0.28),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
