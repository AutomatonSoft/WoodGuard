import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_view_controller.dart';
import '../core/app_copy.dart';
import '../core/theme.dart';

class WoodGuardSurface extends StatelessWidget {
  const WoodGuardSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 28),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0C1221), Color(0xFF17243D), Color(0xFF213760)]
              : const [Color(0xFF6489D1), Color(0xFF4B73C2), Color(0xFF36569B)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -40,
            left: -60,
            child: _AmbientOrb(size: 180, color: Color(0x44FFFFFF)),
          ),
          const Positioned(
            right: -70,
            bottom: 90,
            child: _AmbientOrb(size: 220, color: Color(0x337EA7FF)),
          ),
          SafeArea(
            child: Padding(padding: padding, child: child),
          ),
        ],
      ),
    );
  }
}

class WoodCard extends StatelessWidget {
  const WoodCard({
    super.key,
    required this.child,
    this.tint,
    this.padding = const EdgeInsets.all(22),
  });

  final Widget child;
  final Color? tint;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tint ?? Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24111F46),
            blurRadius: 32,
            offset: Offset(0, 18),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.eyebrow,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow ?? 'MOBILE WORKSPACE',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 6),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ],
          ),
        ),
        ...(trailing == null ? const <Widget>[] : <Widget>[trailing!]),
      ],
    );
  }
}

enum PillTone { neutral, low, medium, high, success }

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.tone = PillTone.neutral,
    this.compact = false,
  });

  final String label;
  final PillTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final background = switch (tone) {
      PillTone.high => WoodGuardColors.danger.withValues(alpha: 0.14),
      PillTone.medium => WoodGuardColors.amber.withValues(alpha: 0.16),
      PillTone.low => WoodGuardColors.success.withValues(alpha: 0.14),
      PillTone.success => WoodGuardColors.success.withValues(alpha: 0.14),
      PillTone.neutral => WoodGuardColors.sand.withValues(alpha: 0.8),
    };
    final foreground = switch (tone) {
      PillTone.high => WoodGuardColors.danger,
      PillTone.medium => const Color(0xFF9C6B15),
      PillTone.low => WoodGuardColors.success,
      PillTone.success => WoodGuardColors.success,
      PillTone.neutral => WoodGuardColors.forest,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.16)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

enum MetricTone { defaultTone, warm }

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tone = MetricTone.defaultTone,
  });

  final String label;
  final String value;
  final IconData? icon;
  final MetricTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      MetricTone.defaultTone => (
        const Color(0xFF172B52),
        const Color(0xFF2F67FF),
      ),
      MetricTone.warm => (const Color(0xFF244CBB), const Color(0xFF7AA3FF)),
    };

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.$1, colors.$2],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
              if (icon != null) const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ResponsiveMetricGrid extends StatelessWidget {
  const ResponsiveMetricGrid({
    super.key,
    required this.children,
    this.maxColumns = 2,
    this.minTileWidth = 150,
    this.mainAxisExtent = 130,
    this.spacing = 12,
  });

  final List<Widget> children;
  final int maxColumns;
  final double minTileWidth;
  final double mainAxisExtent;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final estimatedCount =
            ((availableWidth + spacing) / (minTileWidth + spacing))
                .floor()
                .clamp(1, maxColumns);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: estimatedCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.inventory_2_outlined,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return WoodCard(
      tint: Colors.white.withValues(alpha: 0.86),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: WoodGuardColors.ember.withValues(alpha: 0.8),
            size: 28,
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: WoodGuardColors.pine),
          ),
        ],
      ),
    );
  }
}

class BusyState extends StatelessWidget {
  const BusyState({super.key, this.label = 'Loading workspace...'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class GlassIconBubble extends StatelessWidget {
  const GlassIconBubble({super.key, required this.icon, this.size = 48});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.34),
        color: Colors.white.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.42),
    );
  }
}

class MotionReveal extends StatefulWidget {
  const MotionReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.beginOffset = const Offset(0, 0.08),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;
  final Curve curve;

  @override
  State<MotionReveal> createState() => _MotionRevealState();
}

class _MotionRevealState extends State<MotionReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    _fade = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(curved);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class AppLanguageSwitcher extends StatelessWidget {
  const AppLanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppViewController>(
      builder: (context, view, _) {
        final copy = view.copy;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: supportedAppLocales.map((locale) {
            final selected = locale == view.locale;
            return ChoiceChip(
              label: Text(locale.code.toUpperCase()),
              tooltip: copy.localeLabel(locale),
              selected: selected,
              onSelected: (_) => view.setLocale(locale),
            );
          }).toList(),
        );
      },
    );
  }
}

class AppThemeModeToggle extends StatelessWidget {
  const AppThemeModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppViewController>(
      builder: (context, view, _) {
        final copy = view.copy;
        final isDark = view.themeMode == ThemeMode.dark;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                label: Text(copy.light),
                icon: const Icon(Icons.light_mode_rounded),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                label: Text(copy.dark),
                icon: const Icon(Icons.dark_mode_rounded),
              ),
            ],
            selected: <ThemeMode>{isDark ? ThemeMode.dark : ThemeMode.light},
            onSelectionChanged: (selection) {
              view.setThemeMode(selection.first);
            },
          ),
        );
      },
    );
  }
}

class InlineStatusBanner extends StatelessWidget {
  const InlineStatusBanner({
    super.key,
    required this.message,
    this.isError = false,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final background = isError
        ? WoodGuardColors.danger.withValues(alpha: 0.14)
        : WoodGuardColors.amber.withValues(alpha: 0.16);
    final foreground = isError ? WoodGuardColors.danger : WoodGuardColors.ember;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: foreground.withValues(alpha: 0.2)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 50, spreadRadius: 10),
          ],
        ),
      ),
    );
  }
}
