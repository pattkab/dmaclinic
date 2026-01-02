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

  Widget _row(String label, int value) {
    return ListTile(
      title: Text(label),
      trailing: Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
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
          Card(
            child: Column(
              children: [
                _row('Patients seen', _rep!.patientsSeen),
                _row('New patients', _rep!.newPatients),
                _row('Old patients', _rep!.oldPatients),
                const Divider(height: 1),
                _row('Consultation total', _rep!.consultationTotal),
                _row('Lab total', _rep!.labTotal),
                _row('Pharmacy total', _rep!.pharmacyTotal),
                _row('Procedures total', _rep!.proceduresTotal),
                const Divider(height: 1),
                _row('Grand total', _rep!.grandTotal),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
