import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/app_session_controller.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/domain.dart';
import '../widgets/app_widgets.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  final int invoiceId;

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  InvoiceDetail? _draft;
  ReferenceOptions? _reference;
  AuditLogListResponse? _audit;
  bool _loading = true;
  bool _saving = false;
  bool _autofilling = false;
  bool _locating = false;
  String? _uploadingSection;
  String? _message;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _canEdit {
    final role = context.read<AppSessionController>().currentUser?.role;
    return canEditDossier(role);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    final controller = context.read<AppSessionController>();
    try {
      final detailFuture = controller.getInvoice(widget.invoiceId);
      final auditFuture = controller.getInvoiceAuditLogs(widget.invoiceId);
      Future<ReferenceOptions?> referenceFuture() async {
        try {
          return await controller.getReferenceOptions();
        } catch (_) {
          return null;
        }
      }

      final detail = await detailFuture;
      final audit = await auditFuture;
      final reference = await referenceFuture();

      if (!mounted) {
        return;
      }
      setState(() {
        _draft = detail.clone();
        _audit = audit;
        _reference = reference;
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

  Future<void> _refreshAudit() async {
    try {
      final audit = await context
          .read<AppSessionController>()
          .getInvoiceAuditLogs(widget.invoiceId);
      if (!mounted) {
        return;
      }
      setState(() => _audit = audit);
    } catch (_) {
      // Keep existing audit state.
    }
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null || !_canEdit) {
      return;
    }

    setState(() {
      _saving = true;
      _message = null;
    });

    try {
      final controller = context.read<AppSessionController>();
      await controller.updateInvoice(
        widget.invoiceId,
        buildMetadataPayload(draft),
      );
      final updated = await controller.updateAssessment(
        widget.invoiceId,
        buildAssessmentPayload(draft),
      );
      if (!mounted) {
        return;
      }
      _changed = true;
      setState(() {
        _draft = updated.clone();
        _message = 'Invoice dossier saved.';
      });
      await _refreshAudit();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _message = error.message);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _autofillLocation() async {
    final draft = _draft;
    if (draft == null || !_canEdit) {
      return;
    }
    if (!hasGeolocationAutofillInput(draft)) {
      setState(() {
        _message =
            'Fill geolocation source, seller address, label or seller name first.';
      });
      return;
    }

    setState(() {
      _autofilling = true;
      _message = null;
    });

    try {
      final updated = await context
          .read<AppSessionController>()
          .autofillGeolocation(widget.invoiceId, buildAutofillPayload(draft));
      if (!mounted) {
        return;
      }
      _changed = true;
      setState(() {
        _draft = updated.clone();
        _message = 'Geolocation fields refreshed from backend lookup.';
      });
      await _refreshAudit();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _message = error.message);
    } finally {
      if (mounted) {
        setState(() => _autofilling = false);
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    final draft = _draft;
    if (draft == null || !_canEdit) {
      return;
    }
    final controller = context.read<AppSessionController>();

    setState(() {
      _locating = true;
      _message = null;
    });

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw ApiException('Location permission was denied.', 0);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      final latitude = double.parse(position.latitude.toStringAsFixed(6));
      final longitude = double.parse(position.longitude.toStringAsFixed(6));

      var derivedLabel = buildCurrentLocationLabel(latitude, longitude);
      String? resolvedAddress;
      var reverseLookupFailed = false;

      try {
        final reverse = await controller.reverseGeocode(
          latitude: latitude,
          longitude: longitude,
        );
        derivedLabel = reverse.displayName;
        resolvedAddress = reverse.displayName;
      } catch (_) {
        reverseLookupFailed = true;
      }

      setState(() {
        if (_draft == null) {
          return;
        }
        _draft!.sellerLatitude = latitude;
        _draft!.sellerLongitude = longitude;
        _draft!.assessment.geolocationLatitude = latitude;
        _draft!.assessment.geolocationLongitude = longitude;
        _draft!.sellerAddress = normalizeText(_draft!.sellerAddress) == null
            ? resolvedAddress ?? _draft!.sellerAddress
            : _draft!.sellerAddress;
        if (shouldReplaceDerivedLocationText(_draft!.sellerGeolocationLabel)) {
          _draft!.sellerGeolocationLabel = derivedLabel;
        }
        if (shouldReplaceDerivedLocationText(
          _draft!.assessment.geolocationSourceText,
        )) {
          _draft!.assessment.geolocationSourceText = derivedLabel;
        }
        _message = reverseLookupFailed
            ? 'Current coordinates loaded into the draft. Review and save.'
            : 'Current location loaded into the draft. Review and save.';
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _message = error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _message = error.toString());
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  Future<void> _uploadEvidence(EvidenceSection section) async {
    final draft = _draft;
    if (draft == null || !_canEdit) {
      return;
    }
    final controller = context.read<AppSessionController>();

    final picked = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (picked == null || picked.files.isEmpty) {
      return;
    }

    setState(() {
      _uploadingSection = section.key;
      _message = null;
    });

    try {
      final uploads = await controller.uploadEvidence(
        invoiceId: widget.invoiceId,
        section: section.key,
        files: picked.files,
      );
      final evidence = draft.assessment.evidenceFor(section.key);
      evidence.files.addAll(uploads.map((item) => item.url));
      if (evidence.status == 'missing') {
        evidence.status = 'uploaded';
      }

      final updated = await controller.updateAssessment(
        widget.invoiceId,
        buildAssessmentPayload(draft),
      );
      if (!mounted) {
        return;
      }
      _changed = true;
      setState(() {
        _draft = updated.clone();
        _message = '${uploads.length} file(s) uploaded for ${section.label}.';
      });
      await _refreshAudit();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _message = error.message);
    } finally {
      if (mounted) {
        setState(() => _uploadingSection = null);
      }
    }
  }

  Future<void> _pickDate({
    required String? currentValue,
    required ValueChanged<String?> onChanged,
  }) async {
    final initialDate = parseApiDate(currentValue) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onChanged(toApiDate(picked));
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Widget _buildInput({
    required String fieldKey,
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      key: ValueKey('$fieldKey-$value-$enabled'),
      initialValue: value,
      onChanged: onChanged,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _buildDateField({
    required String label,
    required String? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _canEdit ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          children: [
            Expanded(
              child: Text(
                formatDate(value),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const Icon(Icons.calendar_month_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceWrap<T>({
    required String title,
    required List<T> options,
    required T currentValue,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return ChoiceChip(
              label: Text(labelBuilder(option)),
              selected: currentValue == option,
              onSelected: _canEdit ? (_) => onSelected(option) : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  (double, double)? _currentCoordinates(InvoiceDetail draft) {
    if (draft.assessment.geolocationLatitude != null &&
        draft.assessment.geolocationLongitude != null) {
      return (
        draft.assessment.geolocationLatitude!,
        draft.assessment.geolocationLongitude!,
      );
    }
    if (draft.sellerLatitude != null && draft.sellerLongitude != null) {
      return (draft.sellerLatitude!, draft.sellerLongitude!);
    }
    return null;
  }

  Widget _buildHeader(InvoiceDetail draft) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: () => Navigator.of(context).pop(_changed),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                draft.sellerName ?? draft.companyName ?? draft.invoiceNumber,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Invoice ${draft.invoiceNumber} | '
                '${translateInvoiceStatus(draft.status)}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: WoodGuardColors.pine),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: _saving || !_canEdit ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save Dossier'),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(InvoiceDetail draft) {
    return WoodCard(
      tint: const Color(0xFFF3E5D8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.invoiceNumber,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text('Amount: ${formatCurrency(draft.amount)}'),
                    const SizedBox(height: 4),
                    Text(
                      'Open: ${formatCurrency(draft.remainingAmount)}',
                      style: const TextStyle(
                        color: WoodGuardColors.ember,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: translateRiskLevel(draft.risk.riskLevel),
                tone: switch (draft.risk.riskLevel) {
                  'high' => PillTone.high,
                  'medium' => PillTone.medium,
                  'low' => PillTone.low,
                  _ => PillTone.neutral,
                },
              ),
            ],
          ),
          if (!_canEdit) ...[
            const SizedBox(height: 12),
            const Text(
              'This role can inspect the dossier but cannot write changes.',
              style: TextStyle(color: WoodGuardColors.pine),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(
              _message!,
              style: TextStyle(
                color:
                    _message!.toLowerCase().contains('failed') ||
                        _message!.toLowerCase().contains('error')
                    ? WoodGuardColors.danger
                    : WoodGuardColors.ember,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataCard(InvoiceDetail draft) {
    return WoodCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Metadata', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildInput(
            fieldKey: 'company_name',
            label: 'Company Name',
            value: draft.companyName ?? '',
            onChanged: (value) => draft.companyName = value,
            enabled: _canEdit,
          ),
          const SizedBox(height: 14),
          _buildInput(
            fieldKey: 'company_country',
            label: 'Company Country',
            value: draft.companyCountry ?? '',
            onChanged: (value) => draft.companyCountry = value.toUpperCase(),
            enabled: _canEdit,
          ),
          const SizedBox(height: 14),
          _buildInput(
            fieldKey: 'invoice_number',
            label: 'Invoice Number',
            value: draft.invoiceNumber,
            onChanged: (_) {},
            enabled: false,
          ),
          const SizedBox(height: 14),
          _buildChoiceWrap<String>(
            title: 'Status',
            options: statusOptions,
            currentValue: draft.status,
            labelBuilder: translateInvoiceStatus,
            onSelected: (value) => setState(() => draft.status = value),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  fieldKey: 'amount',
                  label: 'Amount',
                  value: formatNullableDouble(draft.amount),
                  onChanged: (value) =>
                      draft.amount = parseNullableDouble(value) ?? draft.amount,
                  enabled: _canEdit,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInput(
                  fieldKey: 'remaining_amount',
                  label: 'Remaining Amount',
                  value: formatNullableDouble(draft.remainingAmount),
                  onChanged: (value) => draft.remainingAmount =
                      parseNullableDouble(value) ?? draft.remainingAmount,
                  enabled: _canEdit,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Invoice Date',
                  value: draft.invoiceDate,
                  onTap: () => _pickDate(
                    currentValue: draft.invoiceDate,
                    onChanged: (value) =>
                        setState(() => draft.invoiceDate = value),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  label: 'Due Date',
                  value: draft.dueDate,
                  onTap: () => _pickDate(
                    currentValue: draft.dueDate,
                    onChanged: (value) => setState(() => draft.dueDate = value),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Production Date',
                  value: draft.productionDate,
                  onTap: () => _pickDate(
                    currentValue: draft.productionDate,
                    onChanged: (value) =>
                        setState(() => draft.productionDate = value),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  label: 'Import Date',
                  value: draft.importDate,
                  onTap: () => _pickDate(
                    currentValue: draft.importDate,
                    onChanged: (value) =>
                        setState(() => draft.importDate = value),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInput(
            fieldKey: 'notes',
            label: 'Internal Notes',
            value: draft.notes ?? '',
            onChanged: (value) => draft.notes = value,
            enabled: _canEdit,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard(InvoiceDetail draft) {
    return WoodCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Seller Card', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildInput(
            fieldKey: 'seller_name',
            label: 'Seller Name',
            value: draft.sellerName ?? '',
            onChanged: (value) => draft.sellerName = value,
            enabled: _canEdit,
          ),
          const SizedBox(height: 14),
          _buildInput(
            fieldKey: 'seller_address',
            label: 'Address',
            value: draft.sellerAddress ?? '',
            onChanged: (value) => draft.sellerAddress = value,
            enabled: _canEdit,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  fieldKey: 'seller_phone',
                  label: 'Phone',
                  value: draft.sellerPhone ?? '',
                  onChanged: (value) => draft.sellerPhone = value,
                  enabled: _canEdit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInput(
                  fieldKey: 'seller_email',
                  label: 'Email',
                  value: draft.sellerEmail ?? '',
                  onChanged: (value) => draft.sellerEmail = value,
                  enabled: _canEdit,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  fieldKey: 'seller_website',
                  label: 'Website',
                  value: draft.sellerWebsite ?? '',
                  onChanged: (value) => draft.sellerWebsite = value,
                  enabled: _canEdit,
                  keyboardType: TextInputType.url,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInput(
                  fieldKey: 'seller_contact',
                  label: 'Contact Person',
                  value: draft.sellerContactPerson ?? '',
                  onChanged: (value) => draft.sellerContactPerson = value,
                  enabled: _canEdit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWoodSpecCard(InvoiceDetail draft) {
    return WoodCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wood Specification',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (_reference != null) ...[
            Text(
              'Wood Species',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reference!.woodSpecies.map((item) {
                final selected = draft.assessment.woodSpecies.contains(item);
                return FilterChip(
                  label: Text(item.replaceAll('_', ' ')),
                  selected: selected,
                  onSelected: _canEdit
                      ? (value) {
                          setState(() {
                            if (value) {
                              draft.assessment.woodSpecies.add(item);
                            } else {
                              draft.assessment.woodSpecies.remove(item);
                            }
                          });
                        }
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Text(
              'Material Types',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reference!.materialTypes.map((item) {
                final selected = draft.assessment.materialTypes.contains(item);
                return FilterChip(
                  label: Text(item.replaceAll('_', ' ')),
                  selected: selected,
                  onSelected: _canEdit
                      ? (value) {
                          setState(() {
                            if (value) {
                              draft.assessment.materialTypes.add(item);
                            } else {
                              draft.assessment.materialTypes.remove(item);
                            }
                          });
                        }
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],
          _buildInput(
            fieldKey: 'wood_memo',
            label: 'Wood Specification Memo',
            value: draft.assessment.woodSpecificationMemo ?? '',
            onChanged: (value) =>
                draft.assessment.woodSpecificationMemo = value,
            enabled: _canEdit,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  fieldKey: 'origin_country',
                  label: 'Country of Origin',
                  value: draft.assessment.countryOfOrigin ?? '',
                  onChanged: (value) =>
                      draft.assessment.countryOfOrigin = value.toUpperCase(),
                  enabled: _canEdit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInput(
                  fieldKey: 'quantity',
                  label: 'Quantity',
                  value: formatNullableDouble(draft.assessment.quantity),
                  onChanged: (value) =>
                      draft.assessment.quantity = parseNullableDouble(value),
                  enabled: _canEdit,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  fieldKey: 'quantity_unit',
                  label: 'Quantity Unit',
                  value: draft.assessment.quantityUnit ?? '',
                  onChanged: (value) => draft.assessment.quantityUnit = value,
                  enabled: _canEdit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  label: 'Delivery Date',
                  value: draft.assessment.deliveryDate,
                  onTap: () => _pickDate(
                    currentValue: draft.assessment.deliveryDate,
                    onChanged: (value) =>
                        setState(() => draft.assessment.deliveryDate = value),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskCard(InvoiceDetail draft) {
    return WoodCard(
      tint: const Color(0xFFE5EFE8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Risk Inputs', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildChoiceWrap<String>(
            title: 'Child Labor',
            options: complianceOptions,
            currentValue: draft.assessment.childLaborOk,
            labelBuilder: translateComplianceChoice,
            onSelected: (value) =>
                setState(() => draft.assessment.childLaborOk = value),
          ),
          const SizedBox(height: 14),
          _buildChoiceWrap<String>(
            title: 'Human Rights',
            options: complianceOptions,
            currentValue: draft.assessment.humanRightsOk,
            labelBuilder: translateComplianceChoice,
            onSelected: (value) =>
                setState(() => draft.assessment.humanRightsOk = value),
          ),
          const SizedBox(height: 14),
          _buildChoiceWrap<String?>(
            title: 'Personal Risk',
            options: personalRiskOptions,
            currentValue: draft.assessment.personalRiskLevel,
            labelBuilder: translateRiskLevel,
            onSelected: (value) =>
                setState(() => draft.assessment.personalRiskLevel = value),
          ),
          const SizedBox(height: 14),
          _buildInput(
            fieldKey: 'risk_reason',
            label: 'Why?',
            value: draft.assessment.riskReason ?? '',
            onChanged: (value) => draft.assessment.riskReason = value,
            enabled: _canEdit,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildGeolocationCard(InvoiceDetail draft) {
    final coordinates = _currentCoordinates(draft);
    return WoodCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Geolocation', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildInput(
            fieldKey: 'geo_label',
            label: 'Geolocation Label',
            value: draft.sellerGeolocationLabel ?? '',
            onChanged: (value) => draft.sellerGeolocationLabel = value,
            enabled: _canEdit,
          ),
          const SizedBox(height: 14),
          _buildInput(
            fieldKey: 'geo_source',
            label: 'Geolocation Source',
            value: draft.assessment.geolocationSourceText ?? '',
            onChanged: (value) =>
                draft.assessment.geolocationSourceText = value,
            enabled: _canEdit,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  fieldKey: 'seller_lat',
                  label: 'Seller Latitude',
                  value: formatNullableDouble(draft.sellerLatitude),
                  onChanged: (value) =>
                      draft.sellerLatitude = parseNullableDouble(value),
                  enabled: _canEdit,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInput(
                  fieldKey: 'seller_lon',
                  label: 'Seller Longitude',
                  value: formatNullableDouble(draft.sellerLongitude),
                  onChanged: (value) =>
                      draft.sellerLongitude = parseNullableDouble(value),
                  enabled: _canEdit,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  fieldKey: 'assessment_lat',
                  label: 'Assessment Latitude',
                  value: formatNullableDouble(
                    draft.assessment.geolocationLatitude,
                  ),
                  onChanged: (value) => draft.assessment.geolocationLatitude =
                      parseNullableDouble(value),
                  enabled: _canEdit,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInput(
                  fieldKey: 'assessment_lon',
                  label: 'Assessment Longitude',
                  value: formatNullableDouble(
                    draft.assessment.geolocationLongitude,
                  ),
                  onChanged: (value) => draft.assessment.geolocationLongitude =
                      parseNullableDouble(value),
                  enabled: _canEdit,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _locating ? null : _useCurrentLocation,
              child: Text(
                _locating
                    ? 'Reading device location...'
                    : 'Use Current Location',
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _autofilling ? null : _autofillLocation,
              child: Text(
                _autofilling
                    ? 'Resolving location...'
                    : 'Auto Detect From Fields',
              ),
            ),
          ),
          if (coordinates != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _launchExternalUrl(
                  buildMapUrl(coordinates.$1, coordinates.$2),
                ),
                child: const Text('Open Map'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(InvoiceDetail draft) {
    return WoodCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Evidence', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...evidenceSections.map((section) {
            final evidence = draft.assessment.evidenceFor(section.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F4ED),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            section.label,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        StatusPill(
                          label: translateDocumentStatus(evidence.status),
                          tone: switch (evidence.status) {
                            'verified' => PillTone.success,
                            'uploaded' => PillTone.medium,
                            _ => PillTone.neutral,
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: evidence.status,
                      items: const [
                        DropdownMenuItem(
                          value: 'missing',
                          child: Text('Missing'),
                        ),
                        DropdownMenuItem(
                          value: 'uploaded',
                          child: Text('Uploaded'),
                        ),
                        DropdownMenuItem(
                          value: 'verified',
                          child: Text('Verified'),
                        ),
                      ],
                      onChanged: _canEdit
                          ? (value) {
                              if (value != null) {
                                setState(() => evidence.status = value);
                              }
                            }
                          : null,
                      decoration: const InputDecoration(labelText: 'Status'),
                    ),
                    const SizedBox(height: 14),
                    _buildInput(
                      fieldKey: 'memo_${section.key}',
                      label: 'Memo',
                      value: evidence.memo ?? '',
                      onChanged: (value) => evidence.memo = value,
                      enabled: _canEdit,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _uploadingSection == section.key
                            ? null
                            : () => _uploadEvidence(section),
                        child: Text(
                          _uploadingSection == section.key
                              ? 'Uploading...'
                              : 'Upload Evidence',
                        ),
                      ),
                    ),
                    if (evidence.files.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...evidence.files.map((file) {
                        final uri = Uri.parse(file);
                        final fileName = uri.pathSegments.isEmpty
                            ? file
                            : uri.pathSegments.last;
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _launchExternalUrl(
                              absoluteFileUrl(
                                context.read<AppSessionController>().apiBaseUrl,
                                file,
                              ),
                            ),
                            icon: const Icon(Icons.attach_file_rounded),
                            label: Text(fileName),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAuditCard() {
    final auditItems = _audit?.items ?? const <AuditLogEntry>[];
    return WoodCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Audit Trail',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (auditItems.isEmpty)
            const EmptyState(
              title: 'No audit events yet',
              description:
                  'Dossier changes, uploads and sync actions will appear here.',
            )
          else
            ...auditItems.take(8).map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F4ED),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.action,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              entry.summary ?? 'No summary provided.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: WoodGuardColors.pine),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatDateTime(entry.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: WoodGuardColors.pine,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRecapCard(InvoiceDetail draft) {
    return WoodCard(
      tint: const Color(0xFFF0E7D6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Risk Recap', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text('Coverage: ${formatPercent(draft.risk.coveragePercent)}'),
          const SizedBox(height: 6),
          Text('Penalty points: ${draft.risk.penaltyPoints}'),
          const SizedBox(height: 6),
          Text(
            'Child labor: ${translateComplianceChoice(draft.assessment.childLaborOk)}',
          ),
          const SizedBox(height: 6),
          Text(
            'Human rights: ${translateComplianceChoice(draft.assessment.humanRightsOk)}',
          ),
          const SizedBox(height: 6),
          Text(
            'Last reviewed: ${formatDateTime(draft.assessment.lastReviewedAt)}',
          ),
          if (draft.risk.breakdown.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Breakdown', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ...draft.risk.breakdown.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(item.label)),
                    Text(
                      '${item.awardedPoints} / ${item.weight}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (draft.risk.blockers.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Blockers', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ...draft.risk.blockers.map((blocker) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  blocker,
                  style: const TextStyle(
                    color: WoodGuardColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        body: WoodGuardSurface(
          child: _loading && _draft == null
              ? const BusyState(label: 'Loading dossier...')
              : _draft == null
              ? EmptyState(
                  title: 'Invoice not available',
                  description:
                      _message ??
                      'The invoice could not be loaded. Refresh the queue and try again.',
                )
              : _buildLoadedState(),
        ),
      ),
    );
  }

  Widget _buildLoadedState() {
    final draft = _draft!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
        children: [
          _buildHeader(draft),
          const SizedBox(height: 18),
          _buildSummaryCard(draft),
          const SizedBox(height: 18),
          _buildMetadataCard(draft),
          const SizedBox(height: 18),
          _buildSellerCard(draft),
          const SizedBox(height: 18),
          _buildWoodSpecCard(draft),
          const SizedBox(height: 18),
          _buildRiskCard(draft),
          const SizedBox(height: 18),
          _buildGeolocationCard(draft),
          const SizedBox(height: 18),
          _buildEvidenceCard(draft),
          const SizedBox(height: 18),
          _buildAuditCard(),
          const SizedBox(height: 18),
          _buildRecapCard(draft),
        ],
      ),
    );
  }
}
