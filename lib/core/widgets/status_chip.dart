import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'app_icons.dart';

enum StatusToneKind {
  neutral,
  info,
  warning,
  success,
  error,
  cancelled,
  issued,
  received,
}

class StatusTone {
  const StatusTone({required this.kind, required this.color});

  final StatusToneKind kind;
  final Color color;
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = statusToneFor(context, status);
    final label = statusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.color.withValues(alpha: 0.10),
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: tone.color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: tone.color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

StatusTone statusToneFor(BuildContext context, String value) {
  final normalized = normalizeStatus(value);
  final colorScheme = Theme.of(context).colorScheme;

  return switch (normalized) {
    'DRAFT' => StatusTone(
      kind: StatusToneKind.neutral,
      color: colorScheme.onSurface.withValues(alpha: 0.58),
    ),
    'SUBMITTED' || 'OPEN' => const StatusTone(
      kind: StatusToneKind.info,
      color: AppColors.info,
    ),
    'PENDING' ||
    'PENDING_SYNC' ||
    'PROCESSING' ||
    'WAITING' ||
    'PARTIALLY_PAID' => const StatusTone(
      kind: StatusToneKind.warning,
      color: AppColors.warning,
    ),
    'APPROVED' || 'COMPLETED' || 'CLOSED' || 'PAID' || 'SYNCED' || 'SUCCESS' =>
      const StatusTone(kind: StatusToneKind.success, color: AppColors.success),
    'REJECTED' || 'FAILED' || 'ERROR' || 'OVERDUE' => const StatusTone(
      kind: StatusToneKind.error,
      color: AppColors.error,
    ),
    'CANCELLED' || 'CANCELED' => const StatusTone(
      kind: StatusToneKind.cancelled,
      color: AppColors.neutral800,
    ),
    'ISSUED' => const StatusTone(
      kind: StatusToneKind.issued,
      color: Color(0xFF7C3AED),
    ),
    'RECEIVED' => const StatusTone(
      kind: StatusToneKind.received,
      color: Color(0xFF0F766E),
    ),
    _ => StatusTone(
      kind: StatusToneKind.neutral,
      color: colorScheme.onSurface.withValues(alpha: 0.60),
    ),
  };
}

String normalizeStatus(String value) {
  return value.trim().toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');
}

String statusLabel(String value) {
  return normalizeStatus(value).replaceAll('_', ' ');
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
            Container(
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
              Container(
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
