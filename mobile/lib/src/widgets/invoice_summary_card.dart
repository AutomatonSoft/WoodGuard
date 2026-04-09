import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/domain.dart';
import 'app_widgets.dart';

class InvoiceSummaryCard extends StatelessWidget {
  const InvoiceSummaryCard({
    super.key,
    required this.invoice,
    this.factoryName,
    this.showFactoryName = false,
    this.onTap,
  });

  final InvoiceSummary invoice;
  final String? factoryName;
  final bool showFactoryName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title =
        invoice.sellerName ??
        invoice.companyName ??
        factoryName ??
        'Unassigned supplier';

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
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        invoice.invoiceNumber,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: WoodGuardColors.pine,
                        ),
                      ),
                      if (showFactoryName && factoryName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          factoryName!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: WoodGuardColors.ember,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                StatusPill(
                  label: translateRiskLevel(invoice.risk.riskLevel),
                  tone: _pillToneForRisk(invoice.risk.riskLevel),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetaBadge(
                  icon: Icons.inventory_2_outlined,
                  label: translateInvoiceStatus(invoice.status),
                ),
                _MetaBadge(
                  icon: Icons.schedule_outlined,
                  label: formatDate(invoice.dueDate),
                ),
                _MetaBadge(
                  icon: Icons.location_on_outlined,
                  label:
                      invoice.companyCountryName ??
                      invoice.companyCountry ??
                      'Country unset',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatCurrency(invoice.amount),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 22),
                ),
                Text(
                  '${formatCurrency(invoice.remainingAmount)} open',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: WoodGuardColors.ember,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

PillTone _pillToneForRisk(String? riskLevel) {
  switch (riskLevel) {
    case 'high':
      return PillTone.high;
    case 'medium':
      return PillTone.medium;
    case 'low':
      return PillTone.low;
    default:
      return PillTone.neutral;
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.icon, required this.label});

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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: WoodGuardColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
