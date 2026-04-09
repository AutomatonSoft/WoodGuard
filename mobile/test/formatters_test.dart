import 'package:flutter_test/flutter_test.dart';
import 'package:woodguard_mobile/src/core/formatters.dart';
import 'package:woodguard_mobile/src/models/domain.dart';

void main() {
  test('translates known invoice statuses', () {
    expect(translateInvoiceStatus('pending'), 'Pending');
    expect(translateInvoiceStatus('paid'), 'Paid');
    expect(translateInvoiceStatus('unexpected'), 'Unexpected');
  });

  test('builds a current location label with stable precision', () {
    expect(
      buildCurrentLocationLabel(51.1234567, 10.7654321),
      'Current location 51.12346, 10.76543',
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

  test('buildAssessmentPayload keeps slice and area metrics', () {
    final invoice = InvoiceDetail(
      id: 9,
      source: 'manual',
      invoiceNumber: 'WG-9',
      companyIsEu: false,
      amount: 500,
      totalPaid: 100,
      remainingAmount: 400,
      status: 'pending',
      risk: RiskSummary(
        coverageScore: 0,
        coverageTotal: 0,
        coveragePercent: 0,
        penaltyPoints: 0,
        riskScore: 0,
        riskPercent: 0,
        riskLevel: 'low',
      ),
      assessment: AssessmentPayload(sliceCount: 12, areaSquareMeters: 48.75),
    );

    final payload = buildAssessmentPayload(invoice);

    expect(payload['slice_count'], 12);
    expect(payload['area_square_meters'], 48.75);
  });
}
