import 'package:flutter/material.dart';

import '../core/utils/date_utils.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../services/visit_service.dart';

import 'patient_search_page.dart';
import 'daily_report_page.dart';
import 'trends_page.dart';

class DashboardPage extends StatefulWidget {
  final String role;
  const DashboardPage({super.key, required this.role});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _auth = AuthService();
  final _reports = ReportService();
  final _visits = VisitService();

  bool _loading = true;
  DailyReport? _today;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  bool _canCloseAll() => widget.role == 'admin' || widget.role == 'reception';

  Future<void> _loadToday() async {
    setState(() => _loading = true);
    final todayKey = DateUtilsX.todayKey();
    final rep = await _reports.getDailyReport(todayKey);
    if (!mounted) return;
    setState(() {
      _today = rep;
      _loading = false;
    });
  }

  Future<bool> _confirm(String title, String message) async {
    return (await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    )) ??
        false;
  }

  Future<void> _closeAllOpenToday() async {
    final user = _auth.user;
    if (user == null) return;

    final todayKey = DateUtilsX.todayKey();

    final ok = await _confirm(
      'Close all open visits?',
      'This will close ALL visits for $todayKey that are still OPEN.\n\n'
          'After closing, fees will be locked unless a visit is reopened.',
    );
    if (!ok) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Expanded(child: Text('Closing open visits...')),
          ],
        ),
      ),
    );

    try {
      final closedCount = await _visits.closeAllOpenVisitsForDate(
        dateKey: todayKey,
        updatedByUid: user.uid,
      );

      if (!mounted) return;
      Navigator.pop(context); // close loader

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Closed $closedCount open visit(s) for $todayKey.')),
      );

      await _loadToday();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to close visits: $e')),
      );
    }
  }

  Widget _statCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayKey = DateUtilsX.todayKey();

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard • $todayKey'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadToday,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async => _auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadToday,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              child: ListTile(
                title: Text('Signed in role: ${widget.role}'),
                subtitle: const Text('Search patients, open today visit, update fees, then close out the day.'),
                trailing: const Icon(Icons.verified_user),
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              runSpacing: 10,
              spacing: 10,
              children: [
                SizedBox(width: 220, child: _statCard('Patients seen', '${_today!.patientsSeen}')),
                SizedBox(width: 220, child: _statCard('New patients', '${_today!.newPatients}')),
                SizedBox(width: 220, child: _statCard('Old patients', '${_today!.oldPatients}')),
                SizedBox(width: 220, child: _statCard('Consultation', '${_today!.consultationTotal}')),
                SizedBox(width: 220, child: _statCard('Lab', '${_today!.labTotal}')),
                SizedBox(width: 220, child: _statCard('Pharmacy', '${_today!.pharmacyTotal}')),
                SizedBox(width: 220, child: _statCard('Procedures', '${_today!.proceduresTotal}')),
                SizedBox(width: 220, child: _statCard('Grand total', '${_today!.grandTotal}')),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('Patient Search'),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PatientSearchPage(role: widget.role)),
                      );
                      _loadToday();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.analytics),
                    label: const Text('Daily Report'),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DailyReportPage()),
                      );
                      _loadToday();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.show_chart),
                    label: const Text('Trends'),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TrendsPage()),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (_canCloseAll())
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.lock),
                  label: const Text('Close All Open Visits (Today)'),
                  onPressed: _closeAllOpenToday,
                ),
              ),

            if (_canCloseAll()) const SizedBox(height: 8),

            if (_canCloseAll())
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'End-of-day closeout: closes all OPEN visits for today and locks fees to prevent later edits.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
