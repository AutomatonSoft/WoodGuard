import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_session_controller.dart';
import '../controllers/app_view_controller.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/domain.dart';
import '../widgets/app_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.revision});

  final int revision;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardMetrics? _metrics;
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final metrics = await context.read<AppSessionController>().getMetrics();
      if (!mounted) {
        return;
      }
      setState(() => _metrics = metrics);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _message = error.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppSessionController>().currentUser;
    final view = context.watch<AppViewController>();
    final copy = view.copy;
    final metrics = _metrics;

    return Scaffold(
      body: WoodGuardSurface(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SectionHeader(
                      eyebrow: copy.indexEyebrow,
                      title: copy.dashboardTitle,
                      subtitle: copy.dashboardSubtitle(user?.username),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const GlassIconBubble(icon: Icons.auto_awesome_rounded),
                ],
              ),
              const SizedBox(height: 18),
              if (_loading && metrics == null)
                BusyState(label: copy.dashboardLoading)
              else if (metrics == null)
                EmptyState(
                  title: copy.dashboardUnavailable,
                  description: _message ?? copy.dashboardFallback,
                  icon: Icons.cloud_off_rounded,
                )
              else ...[
                WoodCard(
                  tint: Colors.white.withValues(alpha: 0.2),
                  child: Row(
                    children: [
                      const GlassIconBubble(
                        icon: Icons.shield_rounded,
                        size: 56,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              copy.compliancePulseTitle,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              copy.compliancePulseBody,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.82),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ResponsiveMetricGrid(
                  maxColumns: 2,
                  minTileWidth: 160,
                  mainAxisExtent: 136,
                  children: [
                    MetricCard(
                      label: copy.invoices,
                      value: metrics.totalInvoices.toString(),
                      icon: Icons.receipt_long_rounded,
                    ),
                    MetricCard(
                      label: copy.openExposure,
                      value: formatCurrency(view.locale, metrics.openExposure),
                      icon: Icons.account_balance_wallet_rounded,
                      tone: MetricTone.warm,
                    ),
                    MetricCard(
                      label: copy.coverageAverage,
                      value: formatPercent(
                        view.locale,
                        metrics.averageCoverage,
                      ),
                      icon: Icons.donut_large_rounded,
                    ),
                    MetricCard(
                      label: copy.highRisk,
                      value: metrics.highRiskCount.toString(),
                      icon: Icons.warning_amber_rounded,
                      tone: MetricTone.warm,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                WoodCard(
                  tint: const Color(0xFFDDE8FF),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: WoodGuardColors.ember.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: WoodGuardColors.ember,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              copy.operationalPulse,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        copy.paidOpenLabel(
                          metrics.paidInvoices,
                          metrics.openInvoices,
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        copy.nonEuSuppliersLabel(metrics.nonEuSuppliers),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        copy.lastSyncLabel(
                          formatDateTime(view.locale, metrics.latestSyncAt),
                        ),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: WoodGuardColors.pine,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy.suppliersTitle,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          copy.supplierCount(metrics.suppliers.length),
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (metrics.suppliers.isEmpty)
                  EmptyState(
                    title: copy.noSuppliersYet,
                    description: copy.noSuppliersHint,
                    icon: Icons.factory_outlined,
                  )
                else
                  ...metrics.suppliers.take(10).map((supplier) {
                    final hasHighRisk = supplier.highRiskCount > 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: WoodCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF2F67FF),
                                        Color(0xFF7AA3FF),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.apartment_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        supplier.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        supplier.country ?? copy.countryNotSet,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: WoodGuardColors.pine,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        copy.supplierOpenSummary(
                                          supplier.invoiceCount,
                                          formatCurrency(
                                            view.locale,
                                            supplier.remainingAmount,
                                          ),
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: WoodGuardColors.pine,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: StatusPill(
                                label: copy.supplierHighRiskCount(
                                  supplier.highRiskCount,
                                ),
                                tone: hasHighRisk
                                    ? PillTone.high
                                    : PillTone.success,
                                compact: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
