import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../core/utils/date_utils.dart';
import '../models/clinic_settings.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../services/visit_service.dart';

import 'patient_search_page.dart';
import 'daily_report_page.dart';
import 'trends_page.dart';
import 'account_page.dart';
import 'user_management_page.dart';
import 'export_page.dart';
import 'settings_page.dart';

class DashboardPage extends StatefulWidget {
  final String role;
  final ClinicSettings settings;

  const DashboardPage({
    super.key,
    required this.role,
    required this.settings,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _auth = AuthService();
  final _reports = ReportService();
  final _visits = VisitService();

  bool _loading = true;
  DailyReport? _today;

  bool get _canCloseAll => widget.role == 'admin' || widget.role == 'reception';
  bool get _canManageUsers => widget.role == 'ceo' || widget.role == 'admin';
  bool get _canEditSettings => widget.role == 'ceo' || widget.role == 'admin';

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

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
        updatedByEmail: user.email ?? '',
        updatedByRole: widget.role,
      );

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Closed $closedCount open visit(s) for $todayKey.')),
      );

      await _loadToday();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to close visits: $e')),
      );
    }
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandRow() {
    final logo = widget.settings.logoUrl.trim();
    return Row(
      children: [
        if (logo.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              logo,
              height: 34,
              width: 34,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(height: 34, width: 34),
            ),
          )
        else
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Icon(
              Icons.local_hospital,
              size: 20,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            widget.settings.clinicName,
            style: const TextStyle(fontWeight: FontWeight.w800),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          AppConstants.versionLabel,
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _footer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      alignment: Alignment.center,
      child: Text(
        'Developed by ${AppConstants.developer} • ${AppConstants.versionLabel}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
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
            tooltip: 'Backup/Export',
            icon: const Icon(Icons.download),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportPage()));
            },
          ),
          if (_canEditSettings)
            IconButton(
              tooltip: 'Clinic Settings',
              icon: const Icon(Icons.settings),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
              },
            ),
          if (_canManageUsers)
            IconButton(
              tooltip: 'Users',
              icon: const Icon(Icons.group),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserManagementPage(currentRole: widget.role)),
                );
              },
            ),
          IconButton(
            tooltip: 'Account',
            icon: const Icon(Icons.person),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => AccountPage(role: widget.role)));
            },
          ),
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
          // ✅ add bottom padding so last content doesn't hide behind footer
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 70),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _brandRow(),
                    const SizedBox(height: 10),
                    Text(
                      'Signed in role: ${widget.role}',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              runSpacing: 10,
              spacing: 10,
              children: [
                SizedBox(width: 260, child: _statCard('Patients seen', '${_today!.patientsSeen}', Icons.groups)),
                SizedBox(width: 260, child: _statCard('New patients', '${_today!.newPatients}', Icons.person_add)),
                SizedBox(width: 260, child: _statCard('Old patients', '${_today!.oldPatients}', Icons.history)),
                SizedBox(
                  width: 260,
                  child: _statCard('Consultation', '${_today!.consultationTotal}', Icons.medical_services),
                ),
                SizedBox(width: 260, child: _statCard('Lab', '${_today!.labTotal}', Icons.science)),
                SizedBox(width: 260, child: _statCard('Pharmacy', '${_today!.pharmacyTotal}', Icons.local_pharmacy)),
                SizedBox(width: 260, child: _statCard('Procedures', '${_today!.proceduresTotal}', Icons.healing)),
                SizedBox(width: 260, child: _statCard('Grand total', '${_today!.grandTotal}', Icons.payments)),
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
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyReportPage()));
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
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const TrendsPage()));
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (_canCloseAll)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.lock),
                  label: const Text('Close All Open Visits (Today)'),
                  onPressed: _closeAllOpenToday,
                ),
              ),

            if (_canCloseAll) const SizedBox(height: 8),

            if (_canCloseAll)
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

      // ✅ Footer at bottom of screen
      bottomNavigationBar: _footer(context),
    );
  }
}
