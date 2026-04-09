import 'package:flutter/material.dart';

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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6489D1), Color(0xFF36569B)],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: -40,
              left: -70,
              child: _AmbientBlob(size: 220, color: Color(0x40FFFFFF)),
            ),
            const Positioned(
              right: -90,
              bottom: 40,
              child: _AmbientBlob(size: 280, color: Color(0x267EA7FF)),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
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
        color: tint ?? WoodGuardColors.panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24111F46),
            blurRadius: 32,
            offset: Offset(0, 16),
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
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: WoodGuardColors.pine),
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
  });

  final String label;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final background = switch (tone) {
      PillTone.high => const Color(0x24E26172),
      PillTone.medium => const Color(0x24F0A945),
      PillTone.low => const Color(0x241DB97B),
      PillTone.success => const Color(0x241DB97B),
      PillTone.neutral => WoodGuardColors.sand,
    };
    final foreground = switch (tone) {
      PillTone.high => WoodGuardColors.danger,
      PillTone.medium => const Color(0xFF946014),
      PillTone.low => WoodGuardColors.success,
      PillTone.success => WoodGuardColors.success,
      PillTone.neutral => WoodGuardColors.forest,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
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
    this.tone = MetricTone.defaultTone,
  });

  final String label;
  final String value;
  final MetricTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      MetricTone.defaultTone => (
        const Color(0xFF2F67FF),
        const Color(0xFF234FCA),
      ),
      MetricTone.warm => (const Color(0xFFF0A945), const Color(0xFFE17F35)),
    };

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.$1, colors.$2],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x242A50A8),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return WoodCard(
      tint: Colors.white.withValues(alpha: 0.86),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: WoodGuardColors.forest.withValues(alpha: 0.8),
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
          const CircularProgressIndicator(),
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

class _AmbientBlob extends StatelessWidget {
  const _AmbientBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
