import 'package:flutter/material.dart';
import '../core/utils/date_utils.dart';
import '../services/report_service.dart';

class DailyReportPage extends StatefulWidget {
  const DailyReportPage({super.key});

  @override
  State<DailyReportPage> createState() => _DailyReportPageState();
}

class _DailyReportPageState extends State<DailyReportPage> {
  final _reports = ReportService();
  String _dateKey = DateUtilsX.todayKey();
  bool _loading = true;
  DailyReport? _rep;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDate: now,
    );
    if (picked == null) return;
    setState(() {
      _dateKey = DateUtilsX.dateKey(picked);
    });
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rep = await _reports.getDailyReport(_dateKey);
    if (!mounted) return;
    setState(() {
      _rep = rep;
      _loading = false;
    });
  }

  String _fmt(int v) {
    final s = v.toString();
    if (s.length <= 3) return s;
    final b = StringBuffer();
    int c = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      b.write(s[i]);
      c++;
      if (c == 3 && i != 0) {
        b.write(',');
        c = 0;
      }
    }
    return b.toString().split('').reversed.join();
  }

  Widget _metricTile(String label, int value, {IconData? icon}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              'UGX ${_fmt(value)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countTile(String label, int value, {IconData? icon}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Theme.of(context).colorScheme.secondaryContainer,
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              _fmt(value),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grandTotalCard(int total) {
    return Card(
      color: Colors.orange.shade800,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withOpacity(0.18),
              ),
              child: const Icon(Icons.payments, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'GRAND TOTAL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Text(
              'UGX ${_fmt(total)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Report • $_dateKey'),
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: _pickDate),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Patient counts
          _countTile('Patients seen', _rep!.patientsSeen, icon: Icons.groups),
          _countTile('New patients', _rep!.newPatients, icon: Icons.person_add),
          _countTile('Old patients', _rep!.oldPatients, icon: Icons.history),
          const SizedBox(height: 6),

          // Fee totals (bigger)
          _metricTile('Consultation total', _rep!.consultationTotal, icon: Icons.medical_services),
          _metricTile('Lab total', _rep!.labTotal, icon: Icons.science),
          _metricTile('Pharmacy total', _rep!.pharmacyTotal, icon: Icons.local_pharmacy),
          _metricTile('Pharmacy (Other) total', _rep!.pharmacyOtherTotal, icon: Icons.local_pharmacy_outlined),
          _metricTile('Inpatient total', _rep!.inpatientTotal, icon: Icons.hotel),
          _metricTile('Procedures total', _rep!.proceduresTotal, icon: Icons.healing),

          const SizedBox(height: 6),

          // Grand total (bold + large)
          _grandTotalCard(_rep!.grandTotal),
        ],
      ),
    );
  }
}
