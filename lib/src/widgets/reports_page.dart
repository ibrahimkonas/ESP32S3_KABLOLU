import '../models/machine_event.dart';
import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  final List<ProductionReport> reports;
  final List<MachineEvent> events;
  final VoidCallback? onExport;

  const ReportsPage(
      {Key? key, required this.reports, required this.events, this.onExport})
      : super(key: key);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _showDetail(BuildContext context, String title, List<Widget> children) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (children.isEmpty)
                const ListTile(title: Text('Kayıt yok'))
              else
                SizedBox(
                  height: 320,
                  child: ListView(children: children),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryTile({
    required BuildContext context,
    required String title,
    required String value,
    required VoidCallback? onDetail,
    IconData icon = Icons.info,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
        trailing: TextButton.icon(
          onPressed: onDetail,
          icon: const Icon(Icons.list_alt),
          label: const Text('Detay'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todaysReports = reports.where((r) => _isSameDay(r.time, now)).toList();
    final dailyProduction = todaysReports.isNotEmpty ? todaysReports.last.count : 0;
    final todaysFaults =
        events.where((e) => e.type == 'ariza' && _isSameDay(e.time, now)).toList();

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
          _summaryTile(
            context: context,
            title: 'Günlük Üretim',
            value: '$dailyProduction adet',
            onDetail: () => _showDetail(
              context,
              'Günlük Üretim Detayı',
              todaysReports
                  .map((r) => ListTile(
                        title: Text('${r.count} adet'),
                        subtitle: Text(r.timeString),
                      ))
                  .toList(),
            ),
            icon: Icons.factory_outlined,
          ),
          _summaryTile(
            context: context,
            title: 'Günlük Arıza',
            value: '${todaysFaults.length} kayıt',
            onDetail: () => _showDetail(
              context,
              'Günlük Arıza Detayı',
              todaysFaults
                  .map((e) => ListTile(
                        title: Text(e.reason),
                        subtitle: Text(e.timeString),
                      ))
                  .toList(),
            ),
            icon: Icons.error_outline,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Tüm Olaylar',
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
