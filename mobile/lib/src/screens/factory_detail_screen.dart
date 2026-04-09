import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_session_controller.dart';
import '../core/factory_grouping.dart';
import '../core/formatters.dart';
import '../models/domain.dart';
import '../widgets/app_widgets.dart';
import '../widgets/filter_strip.dart';
import '../widgets/invoice_summary_card.dart';
import 'invoice_detail_screen.dart';

class FactoryDetailScreen extends StatefulWidget {
  const FactoryDetailScreen({super.key, required this.factory});

  final FactorySummary factory;

  @override
  State<FactoryDetailScreen> createState() => _FactoryDetailScreenState();
}

class _FactoryDetailScreenState extends State<FactoryDetailScreen> {
  late final TextEditingController _searchController;
  late FactorySummary _factory;
  bool _refreshing = false;
  String? _message;
  String? _status;
  String? _riskLevel;

  @override
  void initState() {
    super.initState();
    _factory = widget.factory;
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InvoiceSummary> get _visibleInvoices {
    final query = _searchController.text.trim().toLowerCase();
    return _factory.invoices.where((invoice) {
      final matchesQuery =
          query.isEmpty ||
          invoice.invoiceNumber.toLowerCase().contains(query) ||
          (invoice.companyName ?? '').toLowerCase().contains(query) ||
          (invoice.sellerName ?? '').toLowerCase().contains(query);
      final matchesStatus = _status == null || invoice.status == _status;
      final matchesRisk =
          _riskLevel == null || invoice.risk.riskLevel == _riskLevel;
      return matchesQuery && matchesStatus && matchesRisk;
    }).toList()..sort((left, right) => right.id.compareTo(left.id));
  }

  Future<void> _refreshFactory() async {
    setState(() {
      _refreshing = true;
      _message = null;
    });

    try {
      final invoices = await context.read<AppSessionController>().getInvoices();
      final response = buildFactoryListResponse(invoices.items);
      if (!mounted) {
        return;
      }

      FactorySummary? refreshed;
      for (final item in response.items) {
        if (item.name.toLowerCase() == widget.factory.name.toLowerCase()) {
          refreshed = item;
          break;
        }
      }

      setState(() {
        _factory =
            refreshed ??
            FactorySummary(
              name: _factory.name,
              country: _factory.country,
              invoiceCount: 0,
              highRiskCount: 0,
              totalAmount: 0,
              remainingAmount: 0,
              invoices: const [],
            );
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _message = error.message);
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _openInvoice(InvoiceSummary invoice) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => InvoiceDetailScreen(invoiceId: invoice.id),
      ),
    );
    if (changed == true && mounted) {
      await _refreshFactory();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoices = _visibleInvoices;

    return Scaffold(
      body: WoodGuardSurface(
        child: RefreshIndicator(
          onRefresh: _refreshFactory,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SectionHeader(
                title: _factory.name,
                subtitle: _factory.country ?? 'Factory country is not set yet.',
                trailing: StatusPill(
                  label: _factory.highRiskCount > 0
                      ? '${_factory.highRiskCount} high'
                      : 'Stable',
                  tone: _factory.highRiskCount > 0
                      ? PillTone.high
                      : PillTone.success,
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
                    label: 'Invoices',
                    value: _factory.invoiceCount.toString(),
                  ),
                  MetricCard(
                    label: 'Open Exposure',
                    value: formatCurrency(_factory.remainingAmount),
                    tone: MetricTone.warm,
                  ),
                  MetricCard(
                    label: 'High Risk',
                    value: _factory.highRiskCount.toString(),
                    tone: _factory.highRiskCount > 0
                        ? MetricTone.warm
                        : MetricTone.defaultTone,
                  ),
                  MetricCard(
                    label: 'Gross Value',
                    value: formatCurrency(_factory.totalAmount),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              WoodCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Search inside factory',
                        hintText: 'Invoice / company / seller',
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
                      onChanged: (value) => setState(() => _status = value),
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
                      onChanged: (value) => setState(() => _riskLevel = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_refreshing)
                const BusyState(label: 'Refreshing factory feed...')
              else if (invoices.isEmpty)
                EmptyState(
                  title: 'No invoices in this factory view',
                  description:
                      _message ??
                      'Try another search or relax the risk and status filters.',
                )
              else ...[
                Text(
                  '${invoices.length} invoice(s) in this factory view',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 12),
                ...invoices.map(
                  (invoice) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InvoiceSummaryCard(
                      invoice: invoice,
                      onTap: () => _openInvoice(invoice),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
