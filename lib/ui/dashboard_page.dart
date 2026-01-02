// NOTE: This is your full file with only the reporting fields updated.
// Paste the whole thing to avoid missing imports / class changes.

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

  Widget _statCard(String title, String? value, IconData icon, {Color? cardColor, Color? textColor}) {
    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: cardColor != null
                    ? Colors.white.withOpacity(0.2)
                    : Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Icon(
                icon,
                color: cardColor != null ? Colors.white : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                  if (value != null) ...[
                    const SizedBox(height: 6),
                    Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandRow() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/dma_clinic.png',
            height: 50,
            width: 50,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Icon(
                Icons.local_hospital,
                size: 28,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
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
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(child: _brandRow()),
                    const SizedBox(width: 10),
                    Text(
                      'Signed in role: ${widget.role}',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade800,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PatientSearchPage(role: widget.role)),
                        );
                        _loadToday();
                      },
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Patient Search and Register',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (_canCloseAll)
                  Expanded(
                    child: SizedBox(
                      height: 80,
                      child: InkWell(
                        onTap: _closeAllOpenToday,
                        child: _statCard(
                          'Close All Open Visits (Today)',
                          null,
                          Icons.lock,
                          cardColor: Colors.purple.shade700,
                          textColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              runSpacing: 10,
              spacing: 10,
              children: [
                SizedBox(width: 260, child: _statCard('Patients seen', '${_today!.patientsSeen}', Icons.groups)),
                SizedBox(width: 260, child: _statCard('New patients', '${_today!.newPatients}', Icons.person_add)),
                SizedBox(width: 260, child: _statCard('Old patients', '${_today!.oldPatients}', Icons.history)),
                SizedBox(width: 260, child: _statCard('Consultation Fees', '${_today!.consultationTotal}', Icons.medical_services)),
                SizedBox(width: 260, child: _statCard('Lab', '${_today!.labTotal}', Icons.science)),
                SizedBox(width: 260, child: _statCard('Pharmacy', '${_today!.pharmacyTotal}', Icons.local_pharmacy)),
                SizedBox(width: 260, child: _statCard('Pharmacy (other)', '${_today!.pharmacyOtherTotal}', Icons.local_pharmacy_outlined)),
                SizedBox(width: 260, child: _statCard('In-patients', '${_today!.inpatientTotal}', Icons.hotel)),
                SizedBox(width: 260, child: _statCard('Procedures', '${_today!.proceduresTotal}', Icons.healing)),
                SizedBox(
                  width: 260,
                  child: _statCard(
                    'Grand total',
                    '${_today!.grandTotal}',
                    Icons.payments,
                    cardColor: Colors.orange.shade800,
                    textColor: Colors.white,
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyReportPage()));
                      _loadToday();
                    },
                    child: _statCard('Daily Report', null, Icons.analytics, cardColor: Colors.teal.shade700, textColor: Colors.white),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const TrendsPage()));
                    },
                    child: _statCard('Trends', null, Icons.show_chart, cardColor: Colors.indigo.shade700, textColor: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Developer: ${AppConstants.developer}',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
