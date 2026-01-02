import 'package:flutter/material.dart';
import '../services/export_service.dart';
import '../core/utils/date_utils.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  final _export = ExportService();

  bool _loading = false;
  String? _path;

  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();

  String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _from,
    );
    if (picked == null) return;
    setState(() => _from = picked);
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _to,
    );
    if (picked == null) return;
    setState(() => _to = picked);
  }

  Future<void> _exportRange() async {
    setState(() {
      _loading = true;
      _path = null;
    });

    try {
      final fromKey = _fmt(_from);
      final toKey = _fmt(_to);

      final path = await _export.exportVisitsCsv(
        fromDateKey: fromKey,
        toDateKey: toKey,
      );

      if (!mounted) return;
      setState(() => _path = path);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export complete (CSV saved).')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportToday() async {
    final todayKey = DateUtilsX.todayKey();
    final now = DateTime.now();
    setState(() {
      _from = now;
      _to = now;
    });

    setState(() {
      _loading = true;
      _path = null;
    });

    try {
      final path = await _export.exportVisitsCsv(
        fromDateKey: todayKey,
        toDateKey: todayKey,
      );

      if (!mounted) return;
      setState(() => _path = path);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Today export complete (CSV saved).')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup / Export')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Export visits to CSV',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This creates a CSV file you can open in Excel and share as backup.',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.today),
                              label: const Text('Export Today'),
                              onPressed: _loading ? null : _exportToday,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              icon: _loading
                                  ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : const Icon(Icons.download),
                              label: const Text('Export Range'),
                              onPressed: _loading ? null : _exportRange,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('From'),
                              subtitle: Text(_fmt(_from)),
                              trailing: IconButton(
                                icon: const Icon(Icons.calendar_month),
                                onPressed: _loading ? null : _pickFrom,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('To'),
                              subtitle: Text(_fmt(_to)),
                              trailing: IconButton(
                                icon: const Icon(Icons.calendar_month),
                                onPressed: _loading ? null : _pickTo,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_path != null) ...[
                        const Divider(height: 24),
                        const Text('Saved file path:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        SelectableText(_path!),
                      ],
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
