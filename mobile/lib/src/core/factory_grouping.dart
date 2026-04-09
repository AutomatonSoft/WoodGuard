import '../models/domain.dart';

String invoiceFactoryName(InvoiceSummary invoice) {
  final sellerName = invoice.sellerName?.trim();
  if (sellerName != null && sellerName.isNotEmpty) {
    return sellerName;
  }

  final companyName = invoice.companyName?.trim();
  if (companyName != null && companyName.isNotEmpty) {
    return companyName;
  }

  return 'Unassigned supplier';
}

String? invoiceFactoryCountry(InvoiceSummary invoice) {
  final country = invoice.companyCountryName?.trim();
  if (country != null && country.isNotEmpty) {
    return country;
  }

  final countryCode = invoice.companyCountry?.trim();
  return (countryCode == null || countryCode.isEmpty) ? null : countryCode;
}

FactoryListResponse buildFactoryListResponse(List<InvoiceSummary> invoices) {
  final factories = <String, FactorySummary>{};

  for (final invoice in invoices) {
    final name = invoiceFactoryName(invoice);
    final key = name.toLowerCase();
    final existing = factories[key];

    if (existing == null) {
      factories[key] = FactorySummary(
        name: name,
        country: invoiceFactoryCountry(invoice),
        invoiceCount: 1,
        highRiskCount: invoice.risk.riskLevel == 'high' ? 1 : 0,
        totalAmount: invoice.amount,
        remainingAmount: invoice.remainingAmount,
        invoices: [invoice],
      );
      continue;
    }

    factories[key] = FactorySummary(
      name: existing.name,
      country: existing.country ?? invoiceFactoryCountry(invoice),
      invoiceCount: existing.invoiceCount + 1,
      highRiskCount:
          existing.highRiskCount + (invoice.risk.riskLevel == 'high' ? 1 : 0),
      totalAmount: existing.totalAmount + invoice.amount,
      remainingAmount: existing.remainingAmount + invoice.remainingAmount,
      invoices: [...existing.invoices, invoice],
    );
  }

  final items = factories.values.toList()
    ..sort((left, right) {
      if (right.highRiskCount != left.highRiskCount) {
        return right.highRiskCount.compareTo(left.highRiskCount);
      }
      if (right.invoiceCount != left.invoiceCount) {
        return right.invoiceCount.compareTo(left.invoiceCount);
      }
      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });

  return FactoryListResponse(
    items: items,
    total: items.length,
    invoiceTotal: invoices.length,
  );
}
