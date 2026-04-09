import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_session_controller.dart';
import '../core/factory_grouping.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/domain.dart';
import '../widgets/app_widgets.dart';
import '../widgets/filter_strip.dart';
import 'factory_detail_screen.dart';

class FactoriesScreen extends StatefulWidget {
  const FactoriesScreen({
    super.key,
    required this.revision,
    required this.onDataChanged,
  });

  final int revision;
  final VoidCallback onDataChanged;

  @override
  State<FactoriesScreen> createState() => _FactoriesScreenState();
}

class _FactoriesScreenState extends State<FactoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  FactoryListResponse? _response;
  bool _loading = true;
  String? _message;
  String? _status;
  String? _riskLevel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant FactoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) {
      _load();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final invoices = await context.read<AppSessionController>().getInvoices(
        search: _searchController.text,
        status: _status,
        riskLevel: _riskLevel,
      );
      final response = buildFactoryListResponse(invoices.items);
      if (!mounted) {
        return;
      }
      setState(() => _response = response);
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

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _openFactory(FactorySummary factory) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => FactoryDetailScreen(factory: factory)),
    );
    if (changed == true && mounted) {
      widget.onDataChanged();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final response = _response;
    final factories = response?.items ?? const <FactorySummary>[];
    final highRiskFactories = factories
        .where((factory) => factory.highRiskCount > 0)
        .length;
    final exposure = factories.fold<double>(
      0,
      (sum, factory) => sum + factory.remainingAmount,
    );
    final countryCount = factories
        .map((factory) => normalizeText(factory.country))
        .whereType<String>()
        .toSet()
        .length;

    return Scaffold(
      body: WoodGuardSurface(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SectionHeader(
                title: 'Factory Network',
                subtitle:
                    'One mobile feed for every factory and all linked invoice dossiers.',
                trailing: StatusPill(
                  label: response == null
                      ? 'Factories'
                      : '${response.total} factories',
                ),
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.18,
                children: [
                  MetricCard(
                    label: 'Factories',
                    value: (response?.total ?? 0).toString(),
                  ),
                  MetricCard(
                    label: 'Invoices',
                    value: (response?.invoiceTotal ?? 0).toString(),
                  ),
                  MetricCard(
                    label: 'Open Exposure',
                    value: formatCurrency(exposure),
                    tone: MetricTone.warm,
                  ),
                  MetricCard(
                    label: 'Countries',
                    value: countryCount.toString(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              WoodCard(
                tint: const Color(0xFFE6EEF8),
                child: Row(
                  children: [
                    Expanded(
                      child: _PulseMetric(
                        label: 'High-risk factories',
                        value: '$highRiskFactories',
                        tone: WoodGuardColors.danger,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PulseMetric(
                        label: 'Invoices in view',
                        value: '${response?.invoiceTotal ?? 0}',
                        tone: WoodGuardColors.ember,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              WoodCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => _scheduleSearch(),
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        hintText: 'Factory / invoice / seller',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilterStrip(
                      label: 'Status',
                      currentValue: _status,
                      options: const [
                        FilterOption(label: 'All', value: null),
                        FilterOption(label: 'Pending', value: 'pending'),
                        FilterOption(label: 'Paid', value: 'paid'),
                        FilterOption(label: 'Draft', value: 'draft'),
                        FilterOption(label: 'Partial', value: 'partial'),
                      ],
                      onChanged: (value) {
                        setState(() => _status = value);
                        _load();
                      },
                    ),
                    const SizedBox(height: 12),
                    FilterStrip(
                      label: 'Risk level',
                      currentValue: _riskLevel,
                      options: const [
                        FilterOption(label: 'All', value: null),
                        FilterOption(label: 'High', value: 'high'),
                        FilterOption(label: 'Medium', value: 'medium'),
                        FilterOption(label: 'Low', value: 'low'),
                      ],
                      onChanged: (value) {
                        setState(() => _riskLevel = value);
                        _load();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_loading && response == null)
                const BusyState(label: 'Loading factory network...')
              else if (factories.isEmpty)
                EmptyState(
                  title: 'No factories matched',
                  description:
                      _message ??
                      'Try a broader search or sync fresh invoice data from the account tab.',
                )
              else
                ...factories.map(
                  (factory) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FactoryCard(
                      factory: factory,
                      onTap: () => _openFactory(factory),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseMetric extends StatelessWidget {
  const _PulseMetric({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: WoodGuardColors.pine),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: tone,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FactoryCard extends StatelessWidget {
  const _FactoryCard({required this.factory, required this.onTap});

  final FactorySummary factory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final previewInvoices = factory.invoices.take(3).toList();
    final tone = factory.highRiskCount > 0 ? PillTone.high : PillTone.success;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: WoodCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        factory.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        factory.country ?? 'Country not set',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: WoodGuardColors.pine,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusPill(
                  label: factory.highRiskCount > 0
                      ? '${factory.highRiskCount} high'
                      : 'Clear',
                  tone: tone,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _FactoryBadge(
                  icon: Icons.inventory_2_outlined,
                  label: '${factory.invoiceCount} invoices',
                ),
                _FactoryBadge(
                  icon: Icons.euro_rounded,
                  label: '${formatCurrency(factory.remainingAmount)} open',
                ),
                _FactoryBadge(
                  icon: Icons.payments_outlined,
                  label: formatCurrency(factory.totalAmount),
                ),
              ],
            ),
            if (previewInvoices.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Recent invoices',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              ...previewInvoices.map(
                (invoice) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: WoodGuardColors.sand,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            invoice.invoiceNumber,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          formatDate(invoice.dueDate),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: WoodGuardColors.pine),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FactoryBadge extends StatelessWidget {
  const _FactoryBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: WoodGuardColors.sand,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: WoodGuardColors.pine),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
