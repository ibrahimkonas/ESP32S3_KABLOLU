import '../models/machine_event.dart';
import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  final List<ProductionReport> reports;
  final List<MachineEvent> events;
  final VoidCallback? onExport;

  const ReportsPage(
      {Key? key, required this.reports, required this.events, this.onExport})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlar'),
        actions: [
          if (onExport != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: onExport,
              tooltip: 'Raporları Dışa Aktar',
            ),
        ],
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Günlük Üretim',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          if (reports.isEmpty) const ListTile(title: Text('Kayıt yok')),
          ...reports.map((r) => ListTile(
                title: Text('Üretim: ${r.count}'),
                subtitle: Text(r.timeString),
              )),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Olaylar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          if (events.isEmpty) const ListTile(title: Text('Kayıt yok')),
          ...events.map((e) => ListTile(
                title: Text(
                    '${e.type == 'ariza' ? 'Arıza' : 'Duruş'}: ${e.reason}'),
                subtitle: Text(e.timeString),
              )),
        ],
      ),
    );
  }
}
