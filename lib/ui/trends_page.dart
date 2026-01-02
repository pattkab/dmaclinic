import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/report_service.dart';

class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  final _reports = ReportService();

  late DateTime _start;
  late DateTime _end;

  bool _loading = true;
  String? _error;

  List<TrendPoint> _points = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _end = DateTime(now.year, now.month, now.day);
    _start = _end.subtract(const Duration(days: 6)); // last 7 days
    _load();
  }

  String _key(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _short(String dateKey) {
    if (dateKey.length < 10) return dateKey;
    return '${dateKey.substring(5, 7)}/${dateKey.substring(8, 10)}'; // MM/dd
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 1),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (picked == null) return;

    setState(() {
      _start = DateTime(picked.start.year, picked.start.month, picked.start.day);
      _end = DateTime(picked.end.year, picked.end.month, picked.end.day);
    });

    await _load();
  }

  Future<void> _quickRange(int days) async {
    final now = DateTime.now();
    setState(() {
      _end = DateTime(now.year, now.month, now.day);
      _start = _end.subtract(Duration(days: days - 1));
    });
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final pts = await _reports.getTrends(_key(_start), _key(_end));
      if (!mounted) return;
      setState(() {
        _points = pts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  int _sumTotal() => _points.fold(0, (a, b) => a + b.total);

  LineChartData _lineChartTotal() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _points.length; i++) {
      spots.add(FlSpot(i.toDouble(), _points[i].total.toDouble()));
    }

    double maxY = 0;
    for (final p in _points) {
      if (p.total.toDouble() > maxY) maxY = p.total.toDouble();
    }

    return LineChartData(
      minX: 0,
      maxX: (_points.length - 1).clamp(0, 999).toDouble(),
      minY: 0,
      maxY: maxY == 0 ? 1 : maxY,
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 42),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (_points.length <= 7) ? 1 : 2,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= _points.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_short(_points[i].dateKey), style: const TextStyle(fontSize: 10)),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          isCurved: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
          spots: spots,
          barWidth: 3,
        ),
      ],
    );
  }

  Widget _summaryTile(String title, int value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              'UGX $value',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rangeText = '${_key(_start)} → ${_key(_end)}';

    final consult = _points.fold(0, (a, b) => a + b.consultation);
    final lab = _points.fold(0, (a, b) => a + b.lab);
    final pharm = _points.fold(0, (a, b) => a + b.pharmacy);
    final pharmOther = _points.fold(0, (a, b) => a + b.pharmacyOther);
    final inpatient = _points.fold(0, (a, b) => a + b.inpatient);
    final proc = _points.fold(0, (a, b) => a + b.procedures);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trends'),
        actions: [
          IconButton(
            tooltip: 'Pick range',
            icon: const Icon(Icons.date_range),
            onPressed: _pickRange,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Failed to load trends:\n\n$_error'),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              title: Text(rangeText),
              subtitle: Text('Total income in range: UGX ${_sumTotal()}'),
              trailing: Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _quickRange(7),
                    child: const Text('7D'),
                  ),
                  OutlinedButton(
                    onPressed: () => _quickRange(30),
                    child: const Text('30D'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Total (UGX)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 240,
                    child: _points.isEmpty
                        ? const Center(child: Text('No data in this range.'))
                        : LineChart(_lineChartTotal()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(width: 220, child: _summaryTile('Consultation', consult)),
              SizedBox(width: 220, child: _summaryTile('Lab', lab)),
              SizedBox(width: 220, child: _summaryTile('Pharmacy', pharm)),
              SizedBox(width: 220, child: _summaryTile('Pharmacy (Other)', pharmOther)),
              SizedBox(width: 220, child: _summaryTile('Inpatient', inpatient)),
              SizedBox(width: 220, child: _summaryTile('Procedures', proc)),
            ],
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Daily breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (_points.isEmpty)
                    const Text('No visits found in this range.')
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Consult')),
                          DataColumn(label: Text('Lab')),
                          DataColumn(label: Text('Pharm')),
                          DataColumn(label: Text('Pharm Other')),
                          DataColumn(label: Text('Inpatient')),
                          DataColumn(label: Text('Proc')),
                          DataColumn(label: Text('Total')),
                        ],
                        rows: _points
                            .map(
                              (p) => DataRow(
                            cells: [
                              DataCell(Text(p.dateKey)),
                              DataCell(Text('${p.consultation}')),
                              DataCell(Text('${p.lab}')),
                              DataCell(Text('${p.pharmacy}')),
                              DataCell(Text('${p.pharmacyOther}')),
                              DataCell(Text('${p.inpatient}')),
                              DataCell(Text('${p.procedures}')),
                              DataCell(Text('${p.total}')),
                            ],
                          ),
                        )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
