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
import '../widgets/invoice_summary_card.dart';
import 'invoice_detail_screen.dart';

const _allFactoriesValue = '__all_factories__';

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
  FactoryListResponse? _response;
  bool _loading = true;
  String? _message;
  String? _status;
  String? _riskLevel;
  String? _selectedFactoryName;

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
      final invoices = await context.read<AppSessionController>().getInvoices(
        search: _searchController.text,
        status: _status,
        riskLevel: _riskLevel,
      );
      final response = buildFactoryListResponse(invoices.items);
      if (!mounted) {
        return;
      }

      final hasSelectedFactory =
          _selectedFactoryName == null ||
          response.items.any((item) => item.name == _selectedFactoryName);

      setState(() {
        _response = response;
        if (!hasSelectedFactory) {
          _selectedFactoryName = null;
        }
      });
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

  List<_FactoryInvoiceItem> get _visibleInvoices {
    final response = _response;
    if (response == null) {
      return const [];
    }

    final items = <_FactoryInvoiceItem>[];
    for (final factory in response.items) {
      if (_selectedFactoryName != null &&
          factory.name != _selectedFactoryName) {
        continue;
      }
      for (final invoice in factory.invoices) {
        items.add(_FactoryInvoiceItem(factory: factory, invoice: invoice));
      }
    }
    items.sort((left, right) => right.invoice.id.compareTo(left.invoice.id));
    return items;
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
    final response = _response;
    final visibleInvoices = _visibleInvoices;
    final visibleFactories = {
      for (final item in visibleInvoices) item.factory.name,
    }.length;
    final highRiskInvoices = visibleInvoices
        .where((item) => item.invoice.risk.riskLevel == 'high')
        .length;
    final exposure = visibleInvoices.fold<double>(
      0,
      (sum, item) => sum + item.invoice.remainingAmount,
    );

    return Scaffold(
      floatingActionButton: canCreateManualInvoice(user?.role)
          ? FloatingActionButton.extended(
              onPressed: _openManualInvoiceSheet,
              backgroundColor: WoodGuardColors.forest,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Manual Invoice'),
            )
          : null,
      body: WoodGuardSurface(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SectionHeader(
                title: 'Invoice Queue',
                subtitle:
                    'All invoice dossiers from every factory, loaded through the factory feed.',
                trailing: StatusPill(
                  label: '${visibleInvoices.length} results',
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
                    value: visibleInvoices.length.toString(),
                  ),
                  MetricCard(
                    label: 'Factories',
                    value: visibleFactories.toString(),
                  ),
                  MetricCard(
                    label: 'Open Exposure',
                    value: formatCurrency(exposure),
                    tone: MetricTone.warm,
                  ),
                  MetricCard(
                    label: 'High Risk',
                    value: highRiskInvoices.toString(),
                    tone: highRiskInvoices > 0
                        ? MetricTone.warm
                        : MetricTone.defaultTone,
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
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        hintText: 'Invoice / company / seller',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedFactoryName ?? _allFactoriesValue,
                      items: [
                        const DropdownMenuItem<String>(
                          value: _allFactoriesValue,
                          child: Text('All factories'),
                        ),
                        ...?response?.items.map(
                          (factory) => DropdownMenuItem<String>(
                            value: factory.name,
                            child: Text(factory.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedFactoryName = value == _allFactoriesValue
                              ? null
                              : value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Factory'),
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
                const BusyState(label: 'Loading invoice queue...')
              else if (visibleInvoices.isEmpty)
                EmptyState(
                  title: 'No dossiers matched',
                  description:
                      _message ??
                      'Try another factory or relax the search and risk filters.',
                )
              else
                ...visibleInvoices.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InvoiceSummaryCard(
                      invoice: item.invoice,
                      factoryName: item.factory.name,
                      showFactoryName: _selectedFactoryName == null,
                      onTap: () => _openInvoice(item.invoice),
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

class _FactoryInvoiceItem {
  const _FactoryInvoiceItem({required this.factory, required this.invoice});

  final FactorySummary factory;
  final InvoiceSummary invoice;
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
      // Country reference is optional for the manual mobile shortcut.
    } finally {
      if (mounted) {
        setState(() => _loadingReference = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_invoiceController.text.trim().isEmpty) {
      setState(() => _message = 'Invoice number is required.');
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Create Manual Invoice',
              subtitle:
                  'Quick mobile fallback when Warehub data is not enough.',
            ),
            const SizedBox(height: 18),
            WoodCard(
              child: Column(
                children: [
                  TextField(
                    controller: _invoiceController,
                    decoration: const InputDecoration(
                      labelText: 'Invoice Number',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _companyController,
                    decoration: const InputDecoration(
                      labelText: 'Company Name',
                    ),
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
                      decoration: const InputDecoration(labelText: 'Country'),
                    )
                  else
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Country'),
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
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _message!,
                      style: const TextStyle(
                        color: WoodGuardColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: Text(
                        _submitting
                            ? 'Creating invoice...'
                            : 'Create Manual Invoice',
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
