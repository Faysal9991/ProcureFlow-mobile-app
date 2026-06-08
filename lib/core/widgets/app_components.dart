import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import 'app_icons.dart';

export 'app_icons.dart';

class AppScreenListView extends StatelessWidget {
  const AppScreenListView({
    super.key,
    required this.children,
    this.padding = AppInsets.screen,
    this.physics,
    this.shrinkWrap = false,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        for (var index = 0; index < children.length; index++)
          AppAnimatedEntry(index: index, child: children[index]),
      ],
    );
  }
}

class AppSeparatedListView extends StatelessWidget {
  const AppSeparatedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.separatorBuilder,
    this.padding = AppInsets.screen,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemBuilder: (context, index) =>
          AppAnimatedEntry(index: index, child: itemBuilder(context, index)),
      separatorBuilder:
          separatorBuilder ?? (context, index) => const SizedBox(height: 10),
      itemCount: itemCount,
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({super.key, required this.message, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stateIcon = icon ?? AppIcons.inbox;
    return Center(
      child: Padding(
        padding: AppInsets.cardXLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppNeumorphic.surfaceGradient(theme.brightness),
                borderRadius: AppRadius.cardBorder,
                boxShadow: AppNeumorphic.softShadow(
                  theme.brightness,
                  depth: 0.16,
                  distance: 7,
                  blur: 16,
                ),
              ),
              child: Icon(
                stateIcon,
                size: 28,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class AppEmptyCard extends StatelessWidget {
  const AppEmptyCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Row(
        children: [
          const Icon(AppIcons.inbox, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.child,
    this.padding = AppInsets.card,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _NeumorphicSurface(
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}

class AppListTileCard extends StatelessWidget {
  const AppListTileCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.margin,
    this.contentPadding,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    return _NeumorphicSurface(
      margin: margin,
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: contentPadding,
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

class AppMetricTile extends StatelessWidget {
  const AppMetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    this.route,
    this.onTap,
  }) : assert(route != null || onTap != null);

  final IconData icon;
  final String label;
  final String value;
  final Color tone;
  final String? route;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      onTap: () => _handleTap(context),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.10),
              borderRadius: AppRadius.iconBorder,
              boxShadow: AppNeumorphic.softShadow(
                Theme.of(context).brightness,
                depth: 0.12,
                distance: 5,
                blur: 12,
              ),
            ),
            child: Icon(icon, color: tone, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    context.go(route!);
  }
}

class AppActionTile extends StatelessWidget {
  const AppActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.route,
    this.onTap,
    this.trailing,
    this.compact = false,
    this.margin,
  }) : assert(route != null || onTap != null);

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? route;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool compact;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    if (compact && subtitle == null) {
      return AppSectionCard(
        margin: margin,
        onTap: () => _handleTap(context),
        child: Row(
          children: [
            _AppIconBadge(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleSmall),
            ),
            trailing ?? const Icon(AppIcons.chevronRight),
          ],
        ),
      );
    }

    return AppListTileCard(
      margin: margin,
      leading: _AppIconBadge(icon: icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing ?? const Icon(AppIcons.chevronRight),
      onTap: () => _handleTap(context),
    );
  }

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    context.go(route!);
  }
}

class AppInfoRow extends StatelessWidget {
  const AppInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppIconBadge extends StatelessWidget {
  const _AppIconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.iconBorder,
        boxShadow: AppNeumorphic.softShadow(
          theme.brightness,
          depth: 0.12,
          distance: 5,
          blur: 12,
        ),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class AppInfoGrid extends StatelessWidget {
  const AppInfoGrid({super.key, required this.items});

  final List<AppInfoItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth > 560 ? 4 : 2,
            childAspectRatio: 2.1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final theme = Theme.of(context);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppNeumorphic.surfaceGradient(theme.brightness),
                borderRadius: AppRadius.controlBorder,
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.24),
                ),
                boxShadow: AppNeumorphic.softShadow(
                  theme.brightness,
                  depth: 0.10,
                  distance: 5,
                  blur: 12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class AppInfoItem {
  const AppInfoItem({required this.label, required this.value});

  final String label;
  final String value;
}

class AppAnimatedEntry extends StatelessWidget {
  const AppAnimatedEntry({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cappedIndex = index > 8 ? 8 : index;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + cappedIndex * 34),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _NeumorphicSurface extends StatefulWidget {
  const _NeumorphicSurface({
    required this.child,
    this.padding = AppInsets.card,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  State<_NeumorphicSurface> createState() => _NeumorphicSurfaceState();
}

class _NeumorphicSurfaceState extends State<_NeumorphicSurface> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.dividerColor.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.22 : 0.34,
    );
    final surface = AnimatedScale(
      scale: _pressed ? 0.988 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 190),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: AppNeumorphic.surfaceGradient(theme.brightness),
          borderRadius: AppRadius.cardBorder,
          border: Border.all(color: borderColor, width: 0.8),
          boxShadow: _pressed
              ? AppNeumorphic.pressedShadow(theme.brightness)
              : AppNeumorphic.softShadow(theme.brightness),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.cardBorder,
            onTap: widget.onTap,
            onHighlightChanged: (pressed) {
              if (_pressed != pressed) {
                setState(() => _pressed = pressed);
              }
            },
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );

    if (widget.margin == null) {
      return surface;
    }
    return Padding(padding: widget.margin!, child: surface);
  }
}
