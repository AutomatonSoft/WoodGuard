import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/app_session_controller.dart';
import '../controllers/app_view_controller.dart';
import '../core/app_copy.dart';
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
  final Map<String, TextEditingController> _fieldControllers = {};
  bool _loading = true;
  bool _saving = false;
  bool _autofilling = false;
  bool _locating = false;
  String? _uploadingSection;
  String? _message;
  bool _messageIsError = false;
  bool _changed = false;
  WorkspaceTab _activeTab = WorkspaceTab.overview;
  String _sliceCountInput = '';
  String _areaSquareMetersInput = '';

  AppViewController get _view => context.read<AppViewController>();
  AppCopy get _copy => _view.copy;

  bool get _canEdit {
    final role = context.read<AppSessionController>().currentUser?.role;
    return canEditDossier(role);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncAssessmentInputState(InvoiceDetail? draft) {
    _sliceCountInput = formatNullableInt(draft?.assessment.sliceCount);
    _areaSquareMetersInput = formatNullableDouble(
      draft?.assessment.areaSquareMeters,
    );
  }

  TextEditingController _controllerForField(String fieldKey, String value) {
    final controller = _fieldControllers.putIfAbsent(
      fieldKey,
      () => TextEditingController(text: value),
    );
    if (controller.text != value) {
      controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    return controller;
  }

  void _setMessage(String? value, {required bool isError}) {
    setState(() {
      _message = value;
      _messageIsError = isError;
    });
  }

  Future<void> _load() async {
    _setMessage(null, isError: false);
    setState(() => _loading = true);

    final controller = context.read<AppSessionController>();
    try {
      Future<ReferenceOptions?> loadReferenceOptions() async {
        try {
          return await controller.getReferenceOptions();
        } catch (_) {
          return null;
        }
      }

      final results = await Future.wait<dynamic>([
        controller.getInvoice(widget.invoiceId),
        controller.getInvoiceAuditLogs(widget.invoiceId),
        loadReferenceOptions(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _draft = (results[0] as InvoiceDetail).clone();
        _syncAssessmentInputState(_draft);
        _audit = results[1] as AuditLogListResponse;
        _reference = results[2] as ReferenceOptions?;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      _setMessage(error.message, isError: true);
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
      _messageIsError = false;
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
        _syncAssessmentInputState(_draft);
        _message = _copy.invoiceDossierSaved;
        _messageIsError = false;
      });
      await _refreshAudit();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      _setMessage(error.message, isError: true);
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
      _setMessage(_copy.geolocationAutofillHint, isError: true);
      return;
    }

    setState(() {
      _autofilling = true;
      _message = null;
      _messageIsError = false;
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
        _message = _copy.geolocationRefreshed;
        _messageIsError = false;
      });
      await _refreshAudit();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      _setMessage(error.message, isError: true);
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
      _messageIsError = false;
    });

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw ApiException(_copy.locationPermissionDenied, 0);
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
            ? _copy.currentCoordinatesLoaded
            : _copy.currentLocationLoaded;
        _messageIsError = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      _setMessage(error.message, isError: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _setMessage(error.toString(), isError: true);
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
      _messageIsError = false;
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
        _message = _copy.evidenceUploaded(
          uploads.length,
          _copy.translateEvidenceSection(section.key),
        );
        _messageIsError = false;
      });
      await _refreshAudit();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      _setMessage(error.message, isError: true);
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
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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

  Widget _buildInput({
    required String fieldKey,
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final controller = _controllerForField(fieldKey, value);
    return _buildFieldShell(
      label: label,
      child: TextFormField(
        key: ValueKey('$fieldKey-$enabled-$maxLines'),
        controller: controller,
        onChanged: onChanged,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        minLines: maxLines > 1 ? maxLines : 1,
        textAlignVertical: maxLines > 1
            ? TextAlignVertical.top
            : TextAlignVertical.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(alignLabelWithHint: maxLines > 1),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String? value,
    required AppLocale locale,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _canEdit ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: _buildFieldShell(
        label: label,
        child: InputDecorator(
          decoration: const InputDecoration(),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  formatDate(locale, value),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const Icon(Icons.calendar_month_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldShell({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: WoodGuardColors.pine,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildFieldRow({
    required List<Widget> children,
    double breakpoint = 560,
    double spacing = 12,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index += 1) ...[
                children[index],
                if (index != children.length - 1) SizedBox(height: spacing),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < children.length; index += 1) ...[
              Expanded(child: children[index]),
              if (index != children.length - 1) SizedBox(width: spacing),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    Key? fieldKey,
    Color? fillColor,
    Color? borderColor,
    Color? foregroundColor,
  }) {
    final accentColor =
        foregroundColor ?? Theme.of(context).colorScheme.onSurface;
    return _buildFieldShell(
      label: label,
      child: DropdownButtonFormField<T>(
        key: fieldKey,
        initialValue: value,
        isExpanded: true,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: accentColor,
          fontWeight: FontWeight.w700,
        ),
        iconEnabledColor: accentColor,
        decoration: InputDecoration(
          filled: fillColor != null,
          fillColor: fillColor,
          enabledBorder: borderColor == null
              ? null
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: borderColor.withValues(alpha: 0.42),
                  ),
                ),
          focusedBorder: borderColor == null
              ? null
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: borderColor, width: 1.6),
                ),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildInsetPanel({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
    Color? tint,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color:
            tint ??
            (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFF7FAFF)),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : WoodGuardColors.line.withValues(alpha: 0.12),
        ),
      ),
      child: child,
    );
  }

  Widget _buildSummaryFact({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
    bool emphasize = false,
  }) {
    final resolvedValueColor =
        valueColor ?? Theme.of(context).colorScheme.onSurface;

    return _buildInsetPanel(
      tint: Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.white.withValues(alpha: 0.74),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: WoodGuardColors.pine),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: WoodGuardColors.pine),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: resolvedValueColor,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  PillTone _invoiceStatusTone(String? value) {
    return switch (value) {
      'paid' => PillTone.success,
      'partial' => PillTone.medium,
      'pending' => PillTone.medium,
      'cancelled' => PillTone.high,
      _ => PillTone.neutral,
    };
  }

  PillTone _riskTone(String? value) {
    return switch (value) {
      'high' => PillTone.high,
      'medium' => PillTone.medium,
      'low' => PillTone.low,
      _ => PillTone.neutral,
    };
  }

  PillTone _documentTone(String? value) {
    return switch (value) {
      'verified' => PillTone.success,
      'uploaded' => PillTone.medium,
      _ => PillTone.neutral,
    };
  }

  Color _documentStatusFill(String? value) {
    return switch (value) {
      'verified' => WoodGuardColors.success.withValues(alpha: 0.12),
      'uploaded' => WoodGuardColors.amber.withValues(alpha: 0.14),
      _ => WoodGuardColors.danger.withValues(alpha: 0.12),
    };
  }

  Color _documentStatusAccent(String? value) {
    return switch (value) {
      'verified' => WoodGuardColors.success,
      'uploaded' => const Color(0xFF9C6B15),
      _ => WoodGuardColors.danger,
    };
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

  Widget _buildMultiSelectWrap({
    required String title,
    required List<String> options,
    required List<String> selectedValues,
    required String Function(String) labelBuilder,
    required ValueChanged<String> onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
<<<<<<< HEAD
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
=======
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return FilterChip(
              label: Text(labelBuilder(option)),
              selected: selectedValues.contains(option),
              onSelected: _canEdit ? (_) => onTap(option) : null,
            );
          }).toList(),
>>>>>>> b441d82364d200e118dd68b4bcefa0f1e21dc742
        ),
      ],
    );
  }

  void _toggleArraySelection({
    required List<String> values,
    required String value,
    required void Function(List<String> nextValues) apply,
  }) {
    final nextValues = values.contains(value)
        ? values.where((item) => item != value).toList()
        : [...values, value];
    setState(() => apply(nextValues));
  }

  List<Widget> _buildTopMetrics(InvoiceDetail draft, AppViewController view) {
    final evidenceRecords = evidenceSections
        .map((section) => draft.assessment.evidenceFor(section.key))
        .toList();
    final pendingEvidenceCount = evidenceRecords
        .where((item) => item.status == 'missing' && item.files.isEmpty)
        .length;
    final uploadedEvidenceCount = evidenceRecords.fold<int>(
      0,
      (total, item) => total + item.files.length,
    );
    final verifiedSectionsCount = evidenceRecords
        .where((item) => item.status == 'verified')
        .length;

    return [
      MetricCard(
        label: _copy.riskScore,
        value: '${draft.risk.riskScore.round()}%',
        icon: Icons.radar_rounded,
        tone: MetricTone.warm,
      ),
      MetricCard(
        label: _copy.coverage,
        value: formatPercent(view.locale, draft.risk.coveragePercent),
        icon: Icons.donut_large_rounded,
      ),
      MetricCard(
        label: _copy.pendingEvidence,
        value: pendingEvidenceCount.toString(),
        icon: Icons.pending_actions_rounded,
      ),
      MetricCard(
        label: _copy.uploadedEvidence,
        value: uploadedEvidenceCount.toString(),
        icon: Icons.upload_file_rounded,
      ),
      MetricCard(
        label: _copy.verifiedSections,
        value: verifiedSectionsCount.toString(),
        icon: Icons.verified_rounded,
      ),
      MetricCard(
        label: _copy.openExposure,
        value: formatCurrency(view.locale, draft.remainingAmount),
        icon: Icons.account_balance_wallet_rounded,
        tone: MetricTone.warm,
      ),
    ];
  }

  Widget _buildHeader(InvoiceDetail draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    draft.companyName ??
                        draft.sellerName ??
                        draft.invoiceNumber,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${_copy.selectedInvoice}: ${draft.invoiceNumber}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: WoodGuardColors.pine,
                        ),
                      ),
                      StatusPill(
                        label: _copy.translateInvoiceStatus(draft.status),
                        tone: _invoiceStatusTone(draft.status),
                        compact: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving || !_canEdit ? null : _save,
            child: Text(_saving ? _copy.saving : _copy.saveInvoiceDossier),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(InvoiceDetail draft, AppViewController view) {
    final companyName =
        draft.companyName ?? draft.sellerName ?? _copy.unassignedSupplier;
    final companyCountry = normalizeText(draft.companyCountry) ?? _copy.unset;

    return WoodCard(
      tint: const Color(0xFFF3E5D8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            draft.source == 'warehub'
                ? _copy.orderHubInvoice
                : _copy.manualIndex,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: WoodGuardColors.pine),
          ),
          const SizedBox(height: 8),
          Text(
            companyName,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            '${_copy.invoiceNumber}: ${draft.invoiceNumber}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: WoodGuardColors.pine),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                label: _copy.translateInvoiceStatus(draft.status),
                tone: _invoiceStatusTone(draft.status),
                compact: true,
              ),
              StatusPill(
                label: _copy.translateRiskLevel(draft.risk.riskLevel),
                tone: _riskTone(draft.risk.riskLevel),
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFieldRow(
            children: [
              _buildSummaryFact(
                label: _copy.amount,
                value: formatCurrency(view.locale, draft.amount),
                icon: Icons.receipt_long_rounded,
              ),
              _buildSummaryFact(
                label: _copy.openShort,
                value: formatCurrency(view.locale, draft.remainingAmount),
                icon: Icons.account_balance_wallet_rounded,
                valueColor: WoodGuardColors.ember,
                emphasize: true,
              ),
            ],
            breakpoint: 640,
          ),
          const SizedBox(height: 12),
          _buildFieldRow(
            children: [
              _buildSummaryFact(
                label: _copy.country,
                value: companyCountry,
                icon: Icons.public_rounded,
              ),
              _buildSummaryFact(
                label: _copy.invoiceDate,
                value: formatDate(view.locale, draft.invoiceDate),
                icon: Icons.calendar_today_rounded,
              ),
            ],
            breakpoint: 640,
          ),
          const SizedBox(height: 12),
          _buildFieldRow(
            children: [
              _buildSummaryFact(
                label: _copy.dueDate,
                value: formatDate(view.locale, draft.dueDate),
                icon: Icons.event_available_rounded,
              ),
              _buildSummaryFact(
                label: _copy.productionDate,
                value: formatDate(view.locale, draft.productionDate),
                icon: Icons.inventory_2_rounded,
              ),
            ],
            breakpoint: 640,
          ),
          if (!_canEdit) ...[
            const SizedBox(height: 12),
            _buildInsetPanel(
              tint: Colors.white.withValues(alpha: 0.44),
              child: Text(
                _copy.thisRoleReadOnly,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: WoodGuardColors.pine),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<WorkspaceTab>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment<WorkspaceTab>(
            value: WorkspaceTab.overview,
            label: Text(_copy.overviewTab),
            icon: const Icon(Icons.dashboard_customize_rounded),
          ),
          ButtonSegment<WorkspaceTab>(
            value: WorkspaceTab.evidence,
            label: Text(_copy.evidenceTab),
            icon: const Icon(Icons.attach_file_rounded),
          ),
          ButtonSegment<WorkspaceTab>(
            value: WorkspaceTab.analytics,
            label: Text(_copy.analyticsTab),
            icon: const Icon(Icons.analytics_rounded),
          ),
        ],
        selected: <WorkspaceTab>{_activeTab},
        onSelectionChanged: (selection) {
          setState(() => _activeTab = selection.first);
        },
      ),
    );
  }

  Widget _buildMetadataCard(InvoiceDetail draft, AppViewController view) {
    final countries = _reference?.countries ?? const <CountryProfile>[];
    final selectedCompanyCountry =
        countries.any((country) => country.code == draft.companyCountry)
        ? draft.companyCountry
        : '';

    return WoodCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_copy.metadata, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildInput(
            fieldKey: 'company_name',
            label: _copy.companyName,
            value: draft.companyName ?? '',
            onChanged: (value) => draft.companyName = value,
            enabled: _canEdit,
          ),
          const SizedBox(height: 14),
          if (countries.isNotEmpty)
            _buildDropdownField<String>(
              fieldKey: ValueKey('company-country-${draft.companyCountry}'),
              label: _copy.country,
              value: selectedCompanyCountry,
              items: [
                DropdownMenuItem<String>(
                  value: '',
                  child: Text(_copy.selectCountry),
                ),
                ...countries.map(
                  (country) => DropdownMenuItem<String>(
                    value: country.code,
                    child: Text('${country.name} (${country.code})'),
                  ),
                ),
              ],
              onChanged: _canEdit
                  ? (value) => setState(
                      () => draft.companyCountry = normalizeText(value),
                    )
                  : null,
            )
          else
            _buildInput(
              fieldKey: 'company_country',
              label: _copy.country,
              value: draft.companyCountry ?? '',
              onChanged: (value) => draft.companyCountry = value.toUpperCase(),
              enabled: _canEdit,
            ),
          const SizedBox(height: 14),
          _buildInput(
            fieldKey: 'invoice_number',
            label: _copy.invoiceNumber,
            value: draft.invoiceNumber,
            onChanged: (_) {},
            enabled: false,
          ),
          const SizedBox(height: 14),
          _buildChoiceWrap<String>(
            title: _copy.status,
            options: statusOptions,
            currentValue: draft.status,
            labelBuilder: _copy.translateInvoiceStatus,
            onSelected: (value) => setState(() => draft.status = value),
          ),
          const SizedBox(height: 14),
          _buildFieldRow(
            children: [
              _buildInput(
                fieldKey: 'amount',
                label: _copy.amount,
                value: formatNullableDouble(draft.amount),
                onChanged: (value) =>
                    draft.amount = parseNullableDouble(value) ?? draft.amount,
                enabled: _canEdit,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              _buildInput(
                fieldKey: 'remaining_amount',
                label: _copy.remainingAmount,
                value: formatNullableDouble(draft.remainingAmount),
                onChanged: (value) => draft.remainingAmount =
                    parseNullableDouble(value) ?? draft.remainingAmount,
                enabled: _canEdit,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildFieldRow(
            children: [
              _buildDateField(
                label: _copy.invoiceDate,
                value: draft.invoiceDate,
                locale: view.locale,
                onTap: () => _pickDate(
                  currentValue: draft.invoiceDate,
                  onChanged: (value) =>
                      setState(() => draft.invoiceDate = value),
                ),
              ),
              _buildDateField(
                label: _copy.dueDate,
                value: draft.dueDate,
                locale: view.locale,
                onTap: () => _pickDate(
                  currentValue: draft.dueDate,
                  onChanged: (value) => setState(() => draft.dueDate = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildFieldRow(
            children: [
              _buildDateField(
                label: _copy.productionDate,
                value: draft.productionDate,
                locale: view.locale,
                onTap: () => _pickDate(
                  currentValue: draft.productionDate,
                  onChanged: (value) =>
                      setState(() => draft.productionDate = value),
                ),
              ),
              _buildDateField(
                label: _copy.importDate,
                value: draft.importDate,
                locale: view.locale,
                onTap: () => _pickDate(
                  currentValue: draft.importDate,
                  onChanged: (value) =>
                      setState(() => draft.importDate = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInput(
            fieldKey: 'notes',
            label: _copy.internalNotes,
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
          Text(_copy.sellerCard, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildInput(
            fieldKey: 'seller_name',
            label: _copy.sellerName,
            value: draft.sellerName ?? '',
            onChanged: (value) => draft.sellerName = value,
            enabled: _canEdit,
          ),
          const SizedBox(height: 14),
          _buildInput(
            fieldKey: 'seller_address',
            label: _copy.address,
            value: draft.sellerAddress ?? '',
            onChanged: (value) => draft.sellerAddress = value,
            enabled: _canEdit,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          _buildFieldRow(
            children: [
              _buildInput(
                fieldKey: 'seller_phone',
                label: _copy.phone,
                value: draft.sellerPhone ?? '',
                onChanged: (value) => draft.sellerPhone = value,
                enabled: _canEdit,
              ),
              _buildInput(
                fieldKey: 'seller_email',
                label: _copy.email,
                value: draft.sellerEmail ?? '',
                onChanged: (value) => draft.sellerEmail = value,
                enabled: _canEdit,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildFieldRow(
            children: [
              _buildInput(
                fieldKey: 'seller_website',
                label: _copy.website,
                value: draft.sellerWebsite ?? '',
                onChanged: (value) => draft.sellerWebsite = value,
                enabled: _canEdit,
              ),
              _buildInput(
                fieldKey: 'seller_contact_person',
                label: _copy.contactPerson,
                value: draft.sellerContactPerson ?? '',
                onChanged: (value) => draft.sellerContactPerson = value,
                enabled: _canEdit,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInput(
            fieldKey: 'seller_geolocation_label',
            label: _copy.geolocationLabel,
            value: draft.sellerGeolocationLabel ?? '',
            onChanged: (value) => draft.sellerGeolocationLabel = value,
            enabled: _canEdit,
          ),
        ],
      ),
    );
  }

  Widget _buildGeolocationCard(InvoiceDetail draft) {
    final coordinates = _currentCoordinates(draft);
    final source =
        draft.assessment.geolocationSourceText ??
        draft.sellerGeolocationLabel ??
        draft.sellerAddress ??
        draft.sellerName ??
        _copy.unset;

    return WoodCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _copy.geoSnapshot,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildInput(
            fieldKey: 'assessment_geolocation_source',
            label: _copy.geolocationSource,
            value: draft.assessment.geolocationSourceText ?? '',
            onChanged: (value) =>
                draft.assessment.geolocationSourceText = value,
            enabled: _canEdit,
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          _buildFieldRow(
            children: [
              _buildInput(
                fieldKey: 'assessment_latitude',
                label: _copy.assessmentLatitude,
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
              _buildInput(
                fieldKey: 'assessment_longitude',
                label: _copy.assessmentLongitude,
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
            ],
          ),
          const SizedBox(height: 16),
          _buildInsetPanel(
            tint: WoodGuardColors.sand.withValues(alpha: 0.42),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_copy.coordinates}: '
                  '${coordinates == null ? _copy.unset : '${formatCoordinate(coordinates.$1)}, ${formatCoordinate(coordinates.$2)}'}',
                ),
                const SizedBox(height: 8),
                Text(
                  '${_copy.geolocationSource}: $source',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: WoodGuardColors.pine),
                ),
                const SizedBox(height: 12),
                _buildFieldRow(
                  children: [
                    OutlinedButton(
                      onPressed: _locating ? null : _useCurrentLocation,
                      child: Text(
                        _locating
                            ? _copy.readingDeviceLocation
                            : _copy.useCurrentLocation,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _autofilling ? null : _autofillLocation,
                      child: Text(
                        _autofilling
                            ? _copy.resolvingLocation
                            : _copy.autoDetectFromFields,
                      ),
                    ),
                  ],
                  breakpoint: 520,
                ),
                if (coordinates != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _launchExternalUrl(
                        buildMapUrl(coordinates.$1, coordinates.$2),
                      ),
                      child: Text(_copy.openMap),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(InvoiceDetail draft) {
    return WoodCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _copy.evidenceSections,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...evidenceSections.map((section) {
            final evidence = draft.assessment.evidenceFor(section.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildInsetPanel(
                tint: const Color(0xFFF8F4ED),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldRow(
                      children: [
                        Text(
                          _copy.translateEvidenceSection(section.key),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        StatusPill(
                          label: _copy.translateDocumentStatus(evidence.status),
                          tone: _documentTone(evidence.status),
                          compact: true,
                        ),
                      ],
                      breakpoint: 520,
                    ),
                    const SizedBox(height: 14),
                    _buildDropdownField<String>(
                      fieldKey: ValueKey(
                        'status-${section.key}-${evidence.status}',
                      ),
                      label: _copy.status,
                      value: evidence.status,
                      fillColor: _documentStatusFill(evidence.status),
                      borderColor: _documentStatusAccent(evidence.status),
                      foregroundColor: _documentStatusAccent(evidence.status),
                      items: [
                        for (final status in const [
                          'missing',
                          'uploaded',
                          'verified',
                        ])
                          DropdownMenuItem<String>(
                            value: status,
                            child: Text(_copy.translateDocumentStatus(status)),
                          ),
                      ],
                      onChanged: _canEdit
                          ? (value) {
                              if (value != null) {
                                setState(() => evidence.status = value);
                              }
                            }
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _buildInput(
                      fieldKey: 'memo_${section.key}',
                      label: _copy.memo,
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
                              ? _copy.uploading
                              : _copy.uploadEvidence,
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

  Widget _buildWoodSpecCard(InvoiceDetail draft) {
    final countries = _reference?.countries ?? const <CountryProfile>[];
    final woodSpecies = _reference?.woodSpecies ?? const <String>[];
    final materialTypes = _reference?.materialTypes ?? const <String>[];

    return WoodCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _copy.woodSpecification,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildMultiSelectWrap(
            title: _copy.woodSpecies,
            options: woodSpecies,
            selectedValues: draft.assessment.woodSpecies,
            labelBuilder: _copy.translateWoodSpecies,
            onTap: (value) => _toggleArraySelection(
              values: draft.assessment.woodSpecies,
              value: value,
              apply: (next) => draft.assessment.woodSpecies = next,
            ),
          ),
          const SizedBox(height: 14),
          _buildMultiSelectWrap(
            title: _copy.materialTypes,
            options: materialTypes,
            selectedValues: draft.assessment.materialTypes,
            labelBuilder: _copy.translateMaterialType,
            onTap: (value) => _toggleArraySelection(
              values: draft.assessment.materialTypes,
              value: value,
              apply: (next) => draft.assessment.materialTypes = next,
            ),
          ),
          const SizedBox(height: 14),
          if (countries.isNotEmpty)
            _buildDropdownField<String>(
              fieldKey: ValueKey('origin-${draft.assessment.countryOfOrigin}'),
              label: _copy.countryOfOrigin,
              value:
                  countries.any(
                    (country) =>
                        country.code == draft.assessment.countryOfOrigin,
                  )
                  ? draft.assessment.countryOfOrigin
                  : '',
              items: [
                DropdownMenuItem<String>(
                  value: '',
                  child: Text(_copy.selectCountry),
                ),
                ...countries.map(
                  (country) => DropdownMenuItem<String>(
                    value: country.code,
                    child: Text('${country.name} (${country.code})'),
                  ),
                ),
              ],
              onChanged: _canEdit
                  ? (value) => setState(
                      () => draft.assessment.countryOfOrigin = normalizeText(
                        value,
                      ),
                    )
                  : null,
            ),
          const SizedBox(height: 14),
          _buildFieldRow(
            children: [
              _buildInput(
                fieldKey: 'quantity',
                label: _copy.quantity,
                value: formatNullableDouble(draft.assessment.quantity),
                onChanged: (value) =>
                    draft.assessment.quantity = parseNullableDouble(value),
                enabled: _canEdit,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              _buildInput(
                fieldKey: 'quantity_unit',
                label: _copy.unit,
                value: draft.assessment.quantityUnit ?? '',
                onChanged: (value) => draft.assessment.quantityUnit = value,
                enabled: _canEdit,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildFieldRow(
            children: [
              _buildInput(
                fieldKey: 'slice_count',
                label: _copy.sliceCount,
                value: _sliceCountInput,
                onChanged: (value) => setState(() {
                  _sliceCountInput = value;
                  draft.assessment.sliceCount = parseNullableInt(value);
                }),
                enabled: _canEdit,
                keyboardType: TextInputType.number,
              ),
              _buildInput(
                fieldKey: 'area_square_meters',
                label: _copy.areaSquareMeters,
                value: _areaSquareMetersInput,
                onChanged: (value) => setState(() {
                  _areaSquareMetersInput = value;
                  draft.assessment.areaSquareMeters = parseNullableDouble(
                    value,
                  );
                }),
                enabled: _canEdit,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildDateField(
            label: _copy.deliveryDate,
            value: draft.assessment.deliveryDate,
            locale: _view.locale,
            onTap: () => _pickDate(
              currentValue: draft.assessment.deliveryDate,
              onChanged: (value) =>
                  setState(() => draft.assessment.deliveryDate = value),
            ),
          ),
          const SizedBox(height: 14),
          _buildInput(
            fieldKey: 'wood_specification_memo',
            label: _copy.woodSpecificationMemo,
            value: draft.assessment.woodSpecificationMemo ?? '',
            onChanged: (value) =>
                draft.assessment.woodSpecificationMemo = value,
            enabled: _canEdit,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildFilesRecapCard(InvoiceDetail draft) {
    return WoodCard(
      tint: const Color(0xFFF0E7D6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _copy.currentFiles,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...evidenceSections.map((section) {
            final evidence = draft.assessment.evidenceFor(section.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildInsetPanel(
                padding: const EdgeInsets.all(14),
                child: _buildFieldRow(
                  children: [
                    Text(_copy.translateEvidenceSection(section.key)),
                    Text(
                      '${evidence.files.length} | '
                      '${_copy.translateDocumentStatus(evidence.status)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                  breakpoint: 460,
                  spacing: 10,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRiskInputsCard(InvoiceDetail draft) {
    return WoodCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_copy.riskInputs, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildChoiceWrap<String>(
            title: _copy.childLabor,
            options: complianceOptions,
            currentValue: draft.assessment.childLaborOk,
            labelBuilder: _copy.translateComplianceChoice,
            onSelected: (value) =>
                setState(() => draft.assessment.childLaborOk = value),
          ),
          const SizedBox(height: 14),
          _buildChoiceWrap<String>(
            title: _copy.humanRights,
            options: complianceOptions,
            currentValue: draft.assessment.humanRightsOk,
            labelBuilder: _copy.translateComplianceChoice,
            onSelected: (value) =>
                setState(() => draft.assessment.humanRightsOk = value),
          ),
          const SizedBox(height: 14),
          _buildChoiceWrap<String?>(
            title: _copy.personalRiskAssessment,
            options: personalRiskOptions,
            currentValue: draft.assessment.personalRiskLevel,
            labelBuilder: (value) =>
                value == null ? _copy.unset : _copy.translateRiskLevel(value),
            onSelected: (value) =>
                setState(() => draft.assessment.personalRiskLevel = value),
          ),
          const SizedBox(height: 14),
          _buildInput(
            fieldKey: 'risk_reason',
            label: _copy.why,
            value: draft.assessment.riskReason ?? '',
            onChanged: (value) => draft.assessment.riskReason = value,
            enabled: _canEdit,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildRiskRecapCard(InvoiceDetail draft, AppViewController view) {
    return WoodCard(
      tint: const Color(0xFFE5EFE8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _copy.riskBlockers,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            '${_copy.coverage}: '
            '${formatPercent(view.locale, draft.risk.coveragePercent)}',
          ),
          const SizedBox(height: 6),
          Text('${_copy.penalties}: ${draft.risk.penaltyPoints}'),
          const SizedBox(height: 12),
          if (draft.risk.blockers.isEmpty)
            Text(
              _copy.noAuditActivity,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: WoodGuardColors.pine),
            )
          else
            ...draft.risk.blockers.map((blocker) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildInsetPanel(
                  padding: const EdgeInsets.all(14),
                  tint: WoodGuardColors.danger.withValues(alpha: 0.08),
                  child: Text(
                    _copy.translateBlocker(blocker),
                    style: const TextStyle(
                      color: WoodGuardColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
          if (draft.risk.breakdown.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _copy.breakdown,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ...draft.risk.breakdown.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildInsetPanel(
                  padding: const EdgeInsets.all(14),
                  child: _buildFieldRow(
                    children: [
                      Text(_copy.translateBreakdownLabel(item.key, item.label)),
                      Text(
                        '${item.awardedPoints} / ${item.weight}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                    breakpoint: 460,
                    spacing: 10,
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildAuditCard(AppViewController view) {
    final auditItems = _audit?.items ?? const <AuditLogEntry>[];
    return WoodCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_copy.auditTrail, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (auditItems.isEmpty)
            EmptyState(
              title: _copy.auditTrail,
              description: _copy.noAuditActivity,
            )
          else
            ...auditItems.take(12).map((entry) {
              final actorRole = entry.actorRole == null
                  ? _copy.systemActor
                  : _copy.translateRole(entry.actorRole);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildInsetPanel(
                  tint: const Color(0xFFF8F4ED),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _copy.translateAuditAction(entry.action),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _copy.translateAuditSummary(entry.summary) ??
                            _copy.noSummaryProvided,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: WoodGuardColors.pine,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_copy.actor}: '
                        '${entry.actorUsername ?? _copy.systemActor} | '
                        '$actorRole | ${entry.entityType} | '
                        '${formatDateTime(view.locale, entry.createdAt)}',
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

  Widget _buildOverviewTab(InvoiceDetail draft, AppViewController view) {
    return Column(
      children: [
        ResponsiveMetricGrid(
          maxColumns: 2,
          minTileWidth: 160,
          mainAxisExtent: 136,
          children: _buildTopMetrics(draft, view).take(4).toList(),
        ),
        const SizedBox(height: 18),
        _buildMetadataCard(draft, view),
        const SizedBox(height: 18),
        _buildSellerCard(draft),
        const SizedBox(height: 18),
        _buildGeolocationCard(draft),
      ],
    );
  }

  Widget _buildEvidenceTab(InvoiceDetail draft, AppViewController view) {
    return Column(
      children: [
        ResponsiveMetricGrid(
          maxColumns: 2,
          minTileWidth: 160,
          mainAxisExtent: 136,
          children: _buildTopMetrics(draft, view).skip(2).take(4).toList(),
        ),
        const SizedBox(height: 18),
        _buildEvidenceCard(draft),
        const SizedBox(height: 18),
        _buildWoodSpecCard(draft),
        const SizedBox(height: 18),
        _buildFilesRecapCard(draft),
      ],
    );
  }

  Widget _buildAnalyticsTab(InvoiceDetail draft, AppViewController view) {
    return Column(
      children: [
        ResponsiveMetricGrid(
          maxColumns: 2,
          minTileWidth: 160,
          mainAxisExtent: 136,
          children: _buildTopMetrics(draft, view).take(4).toList(),
        ),
        const SizedBox(height: 18),
        _buildRiskInputsCard(draft),
        const SizedBox(height: 18),
        _buildRiskRecapCard(draft, view),
        const SizedBox(height: 18),
        _buildAuditCard(view),
      ],
    );
  }

  Widget _buildLoadedState(AppViewController view) {
    final draft = _draft!;
    final body = switch (_activeTab) {
      WorkspaceTab.overview => _buildOverviewTab(draft, view),
      WorkspaceTab.evidence => _buildEvidenceTab(draft, view),
      WorkspaceTab.analytics => _buildAnalyticsTab(draft, view),
    };

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
        children: [
          _buildHeader(draft),
          const SizedBox(height: 18),
          _buildSummaryCard(draft, view),
          if (_message != null) ...[
            const SizedBox(height: 18),
            InlineStatusBanner(message: _message!, isError: _messageIsError),
          ],
          const SizedBox(height: 18),
          _buildTabBar(),
          const SizedBox(height: 18),
          body,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = context.watch<AppViewController>();

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
              ? BusyState(label: _copy.loadingDossier)
              : _draft == null
              ? EmptyState(
                  title: _copy.invoiceUnavailable,
                  description: _message ?? _copy.invoiceUnavailableHint,
                )
              : _buildLoadedState(view),
        ),
      ),
    );
  }
}
