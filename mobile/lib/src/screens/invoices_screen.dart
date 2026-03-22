import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_session_controller.dart';
import '../controllers/app_view_controller.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/domain.dart';
import '../widgets/app_widgets.dart';
import 'invoice_detail_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({
    super.key,
    required this.revision,
    required this.onDataChanged,
  });

  final int revision;
  final VoidCallback onDataChanged;

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<InvoiceSummary> _items = const [];
  bool _loading = true;
  String? _message;
  String? _status;
  String? _riskLevel;
  String? _factory;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant InvoicesScreen oldWidget) {
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
      final response = await context.read<AppSessionController>().getInvoices(
        search: _searchController.text,
        status: _status,
        riskLevel: _riskLevel,
      );
      if (!mounted) {
        return;
      }
      setState(() => _items = response.items);
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

  Future<void> _openInvoice(InvoiceSummary item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => InvoiceDetailScreen(invoiceId: item.id),
      ),
    );
    if (changed == true && mounted) {
      widget.onDataChanged();
      await _load();
    }
  }

  Future<void> _openManualInvoiceSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ManualInvoiceSheet(),
    );
    if (created == true && mounted) {
      widget.onDataChanged();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppSessionController>().currentUser;
    final view = context.watch<AppViewController>();
    final copy = view.copy;
    final factories = buildFactorySummaries(_items, copy.unassignedSupplier);
    final filteredItems = _factory == null
        ? _items
        : _items
              .where(
                (item) =>
                    resolveFactoryName(item, copy.unassignedSupplier) ==
                    _factory,
              )
              .toList();
    final openExposure = filteredItems.fold<double>(
      0,
      (total, item) => total + item.remainingAmount,
    );
    final coverageAverage = filteredItems.isEmpty
        ? 0.0
        : filteredItems.fold<double>(
                0,
                (total, item) => total + item.risk.coveragePercent,
              ) /
              filteredItems.length;
    final highRiskCount = filteredItems
        .where((item) => item.risk.riskLevel == 'high')
        .length;

    return Scaffold(
      floatingActionButton: canCreateManualInvoice(user?.role)
          ? FloatingActionButton.extended(
              onPressed: _openManualInvoiceSheet,
              backgroundColor: WoodGuardColors.forest,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(copy.manualInvoice),
            )
          : null,
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
                      title: copy.mobileDossiersTitle,
                      subtitle: copy.mobileDossiersSubtitle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const GlassIconBubble(icon: Icons.inventory_2_rounded),
                ],
              ),
              const SizedBox(height: 18),
              WoodCard(
                tint: Colors.white.withValues(alpha: 0.18),
                child: Row(
                  children: [
                    const GlassIconBubble(icon: Icons.manage_search_rounded),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        copy.dossiersVisible(filteredItems.length),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ResponsiveMetricGrid(
                maxColumns: 3,
                minTileWidth: 145,
                mainAxisExtent: 136,
                children: [
                  MetricCard(
                    label: copy.invoices,
                    value: filteredItems.length.toString(),
                    icon: Icons.receipt_long_rounded,
                  ),
                  MetricCard(
                    label: copy.openExposure,
                    value: formatCurrency(view.locale, openExposure),
                    icon: Icons.account_balance_wallet_rounded,
                    tone: MetricTone.warm,
                  ),
                  MetricCard(
                    label: copy.highRisk,
                    value: highRiskCount.toString(),
                    icon: Icons.warning_amber_rounded,
                    tone: MetricTone.warm,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              WoodCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => _scheduleSearch(),
                      decoration: InputDecoration(
                        labelText: copy.search,
                        hintText: copy.searchPlaceholder,
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FilterStrip(
                      label: copy.status,
                      currentValue: _status,
                      options: [
                        _FilterOption(label: copy.all, value: null),
                        _FilterOption(
                          label: copy.translateInvoiceStatus('pending'),
                          value: 'pending',
                        ),
                        _FilterOption(
                          label: copy.translateInvoiceStatus('paid'),
                          value: 'paid',
                        ),
                        _FilterOption(
                          label: copy.translateInvoiceStatus('draft'),
                          value: 'draft',
                        ),
                        _FilterOption(
                          label: copy.translateInvoiceStatus('partial'),
                          value: 'partial',
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _status = value);
                        _load();
                      },
                    ),
                    const SizedBox(height: 12),
                    _FilterStrip(
                      label: copy.riskLevel,
                      currentValue: _riskLevel,
                      options: [
                        _FilterOption(label: copy.all, value: null),
                        _FilterOption(
                          label: copy.translateRiskLevel('high'),
                          value: 'high',
                        ),
                        _FilterOption(
                          label: copy.translateRiskLevel('medium'),
                          value: 'medium',
                        ),
                        _FilterOption(
                          label: copy.translateRiskLevel('low'),
                          value: 'low',
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _riskLevel = value);
                        _load();
                      },
                    ),
                    const SizedBox(height: 12),
                    _FactoryDropdown(
                      value: _factory,
                      factories: factories,
                      onChanged: (value) => setState(() => _factory = value),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${copy.coverageAverage}: '
                        '${formatPercent(view.locale, coverageAverage)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: WoodGuardColors.pine,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_loading && filteredItems.isEmpty)
                BusyState(label: copy.loadingInvoiceQueue)
              else if (filteredItems.isEmpty)
                EmptyState(
                  title: copy.noDossiersMatched,
                  description: _message ?? copy.noDossiersHint,
                  icon: Icons.filter_alt_off_rounded,
                )
              else
                ...filteredItems.map((item) {
                  final tone = switch (item.risk.riskLevel) {
                    'high' => PillTone.high,
                    'medium' => PillTone.medium,
                    'low' => PillTone.low,
                    _ => PillTone.neutral,
                  };

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _openInvoice(item),
                      borderRadius: BorderRadius.circular(28),
                      child: WoodCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: WoodGuardColors.sand,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.description_rounded,
                                    color: WoodGuardColors.forest,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.companyName ??
                                            item.sellerName ??
                                            copy.unassignedSupplier,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.invoiceNumber,
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
                                label: copy.translateRiskLevel(
                                  item.risk.riskLevel,
                                ),
                                tone: tone,
                                compact: true,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: WoodGuardColors.sand.withValues(
                                  alpha: 0.52,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.schedule_rounded,
                                        size: 18,
                                        color: WoodGuardColors.pine,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          copy.translateInvoiceStatus(
                                            item.status,
                                          ),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    formatDate(view.locale, item.dueDate),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: WoodGuardColors.pine),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatCurrency(view.locale, item.amount),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontSize: 22),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${formatCurrency(view.locale, item.remainingAmount)} '
                                  '${copy.openShort.toLowerCase()}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: WoodGuardColors.ember,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterOption {
  const _FilterOption({required this.label, required this.value});

  final String label;
  final String? value;
}

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({
    required this.label,
    required this.currentValue,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? currentValue;
  final List<_FilterOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return ChoiceChip(
              label: Text(option.label),
              selected: currentValue == option.value,
              onSelected: (_) => onChanged(option.value),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _FactoryDropdown extends StatelessWidget {
  const _FactoryDropdown({
    required this.value,
    required this.factories,
    required this.onChanged,
  });

  final String? value;
  final List<FactorySummaryView> factories;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final copy = context.watch<AppViewController>().copy;

    return DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: InputDecoration(labelText: copy.noFiltersFactory),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text(copy.allFactories)),
        ...factories.map(
          (factory) => DropdownMenuItem<String?>(
            value: factory.name,
            child: Text(factory.name),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _ManualInvoiceSheet extends StatefulWidget {
  const _ManualInvoiceSheet();

  @override
  State<_ManualInvoiceSheet> createState() => _ManualInvoiceSheetState();
}

class _ManualInvoiceSheetState extends State<_ManualInvoiceSheet> {
  final _invoiceController = TextEditingController();
  final _companyController = TextEditingController();
  final _amountController = TextEditingController(text: '0');
  String _country = 'TR';
  bool _loadingReference = true;
  bool _submitting = false;
  String? _message;
  ReferenceOptions? _reference;

  @override
  void initState() {
    super.initState();
    _loadReference();
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _companyController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadReference() async {
    try {
      final reference = await context
          .read<AppSessionController>()
          .getReferenceOptions();
      if (!mounted) {
        return;
      }
      setState(() {
        _reference = reference;
        if (reference.countries.isNotEmpty &&
            !reference.countries.any((country) => country.code == _country)) {
          _country = reference.countries.first.code;
        }
      });
    } catch (_) {
      // Dropdown data is optional for manual invoice creation.
    } finally {
      if (mounted) {
        setState(() => _loadingReference = false);
      }
    }
  }

  Future<void> _submit() async {
    final copy = context.read<AppViewController>().copy;
    if (_invoiceController.text.trim().isEmpty) {
      setState(() => _message = copy.invoiceNumberRequired);
      return;
    }

    setState(() {
      _submitting = true;
      _message = null;
    });

    try {
      await context.read<AppSessionController>().createManualInvoice({
        'invoice_number': _invoiceController.text.trim(),
        'company_name': normalizeText(_companyController.text),
        'company_country': _country,
        'amount': parseNullableDouble(_amountController.text) ?? 0,
        'status': 'pending',
      });
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _message = error.message);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.watch<AppViewController>().copy;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SectionHeader(
                    eyebrow: copy.indexEyebrow,
                    title: copy.createManualInvoice,
                    subtitle: copy.manualInvoiceSubtitle,
                  ),
                ),
                const SizedBox(width: 12),
                const GlassIconBubble(icon: Icons.add_chart_rounded),
              ],
            ),
            const SizedBox(height: 18),
            WoodCard(
              child: Column(
                children: [
                  TextField(
                    controller: _invoiceController,
                    decoration: InputDecoration(labelText: copy.invoiceNumber),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _companyController,
                    decoration: InputDecoration(labelText: copy.companyName),
                  ),
                  const SizedBox(height: 14),
                  if (_loadingReference)
                    const LinearProgressIndicator(minHeight: 2)
                  else if (_reference != null &&
                      _reference!.countries.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: _country,
                      items: _reference!.countries
                          .map(
                            (country) => DropdownMenuItem<String>(
                              value: country.code,
                              child: Text('${country.name} (${country.code})'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _country = value);
                        }
                      },
                      decoration: InputDecoration(labelText: copy.country),
                    )
                  else
                    InputDecorator(
                      decoration: InputDecoration(labelText: copy.country),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(_country),
                      ),
                    ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: copy.amount),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    InlineStatusBanner(message: _message!, isError: true),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: Text(
                        _submitting
                            ? copy.creatingInvoice
                            : copy.createManualInvoice,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
