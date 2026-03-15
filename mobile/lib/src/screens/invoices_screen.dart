import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_session_controller.dart';
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
              const SectionHeader(
                title: 'Mobile Dossiers',
                subtitle:
                    'Search, filter, open and update invoice dossiers from the same backend as the web workspace.',
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
                    const SizedBox(height: 16),
                    _FilterStrip(
                      label: 'Status',
                      currentValue: _status,
                      options: const [
                        _FilterOption(label: 'All', value: null),
                        _FilterOption(label: 'Pending', value: 'pending'),
                        _FilterOption(label: 'Paid', value: 'paid'),
                        _FilterOption(label: 'Draft', value: 'draft'),
                        _FilterOption(label: 'Partial', value: 'partial'),
                      ],
                      onChanged: (value) {
                        setState(() => _status = value);
                        _load();
                      },
                    ),
                    const SizedBox(height: 12),
                    _FilterStrip(
                      label: 'Risk level',
                      currentValue: _riskLevel,
                      options: const [
                        _FilterOption(label: 'All', value: null),
                        _FilterOption(label: 'High', value: 'high'),
                        _FilterOption(label: 'Medium', value: 'medium'),
                        _FilterOption(label: 'Low', value: 'low'),
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
              if (_loading && _items.isEmpty)
                const BusyState(label: 'Loading invoice queue...')
              else if (_items.isEmpty)
                EmptyState(
                  title: 'No dossiers matched',
                  description:
                      _message ??
                      'Try a broader search or sync fresh invoice data from the account tab.',
                )
              else
                ..._items.map((item) {
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.companyName ??
                                            item.sellerName ??
                                            'Unassigned supplier',
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
                                StatusPill(
                                  label: translateRiskLevel(
                                    item.risk.riskLevel,
                                  ),
                                  tone: tone,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  translateInvoiceStatus(item.status),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  formatDate(item.dueDate),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: WoodGuardColors.pine),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatCurrency(item.amount),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontSize: 22),
                                ),
                                Text(
                                  '${formatCurrency(item.remainingAmount)} open',
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
      // A country dropdown is helpful but not required to create a manual invoice.
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
