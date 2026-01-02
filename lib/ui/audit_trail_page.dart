import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuditTrailPage extends StatelessWidget {
  final String visitId;

  const AuditTrailPage({
    super.key,
    required this.visitId,
  });

  String _fmtTs(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $hh:$mm';
  }

  Widget _changeLines(Map<String, dynamic> changes) {
    final lines = <Widget>[];
    for (final e in changes.entries) {
      final field = e.key;
      final v = e.value;

      if (v is Map) {
        final oldV = v['old'];
        final newV = v['new'];
        lines.add(Text('$field: $oldV → $newV'));
      } else {
        lines.add(Text('$field: $v'));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines);
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('visits')
        .doc(visitId)
        .collection('audit')
        .orderBy('ts', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Audit Trail')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ref.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No audit logs yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final m = docs[i].data();

              final action = (m['action'] as String?) ?? '';
              final uid = (m['uid'] as String?) ?? '';
              final email = (m['email'] as String?) ?? '';
              final role = (m['role'] as String?) ?? '';
              final ts = m['ts'] as Timestamp?;

              final changes = (m['changes'] as Map<String, dynamic>?) ?? {};
              final meta = (m['meta'] as Map<String, dynamic>?) ?? {};

              final who = email.isNotEmpty ? email : uid;
              final whoLine = role.isNotEmpty ? '$who ($role)' : who;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              action,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Text(_fmtTs(ts), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('By: $whoLine', style: const TextStyle(fontSize: 12)),

                      if (changes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Text('Changes:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        _changeLines(changes),
                      ],

                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Text('Meta:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(meta.toString()),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
