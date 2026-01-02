import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/patient.dart';
import '../models/visit.dart';

class ReceiptPage extends StatelessWidget {
  final Patient patient;
  final Visit visit;

  const ReceiptPage({
    super.key,
    required this.patient,
    required this.visit,
  });

  pw.Document _buildPdf() {
    final doc = pw.Document();
    final isClosed = visit.status == 'closed';

    pw.Widget row(String label, String value, {bool bold = false}) {
      final style = pw.TextStyle(
        fontSize: 12,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      );
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: style),
            pw.Text(value, style: style),
          ],
        ),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'DMA Clinic',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                isClosed ? 'RECEIPT (CLOSED)' : 'INVOICE (OPEN)',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 16),

            row('Patient', patient.fullName, bold: true),
            row('Patient ID', patient.patientId),
            row('Phone', patient.phone),
            row('Visit Date', visit.visitDate),

            pw.Divider(height: 24),

            row('Consultation', 'UGX ${visit.consultationFee}'),
            row('Lab', 'UGX ${visit.labFee}'),
            row('Pharmacy', 'UGX ${visit.pharmacyFee}'),
            row('Procedures', 'UGX ${visit.proceduresFee}'),

            pw.Divider(height: 24),
            row('TOTAL', 'UGX ${visit.total}', bold: true),

            pw.SizedBox(height: 18),
            pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Thank you for visiting DMA Clinic.', style: const pw.TextStyle(fontSize: 11)),

            pw.SizedBox(height: 18),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text('Cashier / Reception Signature: ____________________'),
            pw.SizedBox(height: 8),
            pw.Text('Date: ____________________'),
          ],
        ),
      ),
    );

    return doc;
  }

  Future<void> _print(BuildContext context) async {
    final doc = _buildPdf();
    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'DMA_Receipt_${patient.patientId}_${visit.visitDate}.pdf',
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: 14,
      fontWeight: bold ? FontWeight.bold : FontWeight.w400,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = visit.total;
    final isClosed = visit.status == 'closed';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        actions: [
          IconButton(
            tooltip: 'Print / Save PDF',
            icon: const Icon(Icons.print),
            onPressed: () => _print(context),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'DMA Clinic',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          isClosed ? 'RECEIPT (CLOSED)' : 'INVOICE (OPEN)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isClosed ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      _row('Patient', patient.fullName, bold: true),
                      _row('Patient ID', patient.patientId),
                      _row('Phone', patient.phone),
                      _row('Visit Date', visit.visitDate),

                      const Divider(height: 24),

                      _row('Consultation', 'UGX ${visit.consultationFee}'),
                      _row('Lab', 'UGX ${visit.labFee}'),
                      _row('Pharmacy', 'UGX ${visit.pharmacyFee}'),
                      _row('Procedures', 'UGX ${visit.proceduresFee}'),

                      const Divider(height: 24),
                      _row('TOTAL', 'UGX $total', bold: true),

                      const SizedBox(height: 14),
                      const Text(
                        'Use the print button (top right) to print or save as PDF.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
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
