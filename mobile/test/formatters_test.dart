import 'package:flutter_test/flutter_test.dart';
import 'package:woodguard_mobile/src/core/formatters.dart';
import 'package:woodguard_mobile/src/models/domain.dart';

void main() {
  test('translates known invoice statuses', () {
    expect(translateInvoiceStatus('pending'), 'Pending');
    expect(translateInvoiceStatus('paid'), 'Paid');
    expect(translateInvoiceStatus('unexpected'), 'Unknown');
  });

  test('builds a current location label with stable precision', () {
    expect(
      buildCurrentLocationLabel(51.1234567, 10.7654321),
      'Mobile geolocation 51.12346, 10.76543',
    );
  });

  test('invoice detail clone keeps nested assessment values', () {
    final invoice = InvoiceDetail(
      id: 7,
      source: 'manual',
      invoiceNumber: 'WG-7',
      companyIsEu: false,
      amount: 1200,
      totalPaid: 400,
      remainingAmount: 800,
      status: 'pending',
      risk: RiskSummary(
        coverageScore: 10,
        coverageTotal: 20,
        coveragePercent: 50,
        penaltyPoints: 5,
        riskScore: 45,
        riskPercent: 45,
        riskLevel: 'medium',
      ),
      assessment: AssessmentPayload(
        geolocationSourceText: 'Factory gate',
        woodSpecies: ['oak'],
      ),
    );

    final clone = invoice.clone();
    clone.assessment.woodSpecies.add('pine');

    expect(invoice.assessment.woodSpecies, ['oak']);
    expect(clone.assessment.geolocationSourceText, 'Factory gate');
  });
}
