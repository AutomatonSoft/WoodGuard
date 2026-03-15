import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_session_controller.dart';
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

    return Scaffold(
      body: WoodGuardSurface(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SectionHeader(
                title: 'Field Overview',
                subtitle: user == null
                    ? 'Workspace'
                    : 'Signed in as ${user.username}',
              ),
              const SizedBox(height: 18),
              if (_loading && _metrics == null)
                const BusyState(label: 'Loading dashboard metrics...')
              else if (_metrics == null)
                EmptyState(
                  title: 'Dashboard unavailable',
                  description:
                      _message ??
                      'Check API connectivity and sign in again if needed.',
                )
              else ...[
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    MetricCard(
                      label: 'Invoices',
                      value: _metrics!.totalInvoices.toString(),
                    ),
                    MetricCard(
                      label: 'Open Exposure',
                      value: formatCurrency(_metrics!.openExposure),
                      tone: MetricTone.warm,
                    ),
                    MetricCard(
                      label: 'Coverage Avg',
                      value: formatPercent(_metrics!.averageCoverage),
                    ),
                    MetricCard(
                      label: 'High Risk',
                      value: _metrics!.highRiskCount.toString(),
                      tone: MetricTone.warm,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                WoodCard(
                  tint: const Color(0xFFE5EFE8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Operational Pulse',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Paid: ${_metrics!.paidInvoices} | '
                        'Open: ${_metrics!.openInvoices}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Non-EU suppliers: ${_metrics!.nonEuSuppliers}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Last sync: ${formatDateTime(_metrics!.latestSyncAt)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: WoodGuardColors.pine,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Supplier Pressure',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (_metrics!.suppliers.isEmpty)
                  const EmptyState(
                    title: 'No suppliers yet',
                    description:
                        'Sync Warehub or create invoices from the workspace first.',
                  )
                else
                  ..._metrics!.suppliers.take(10).map((supplier) {
                    final hasHighRisk = supplier.highRiskCount > 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: WoodCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    supplier.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    supplier.country ?? 'Country not set',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: WoodGuardColors.pine),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${supplier.invoiceCount} invoices | '
                                    '${formatCurrency(supplier.remainingAmount)} open',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: WoodGuardColors.pine),
                                  ),
                                ],
                              ),
                            ),
                            StatusPill(
                              label: '${supplier.highRiskCount} high',
                              tone: hasHighRisk
                                  ? PillTone.high
                                  : PillTone.success,
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
