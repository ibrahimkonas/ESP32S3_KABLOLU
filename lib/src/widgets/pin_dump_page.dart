import 'package:flutter/material.dart';
import '../models/pin_info.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class PinDumpPage extends StatefulWidget {
  final String deviceIp;
  const PinDumpPage({super.key, required this.deviceIp});

  @override
  State<PinDumpPage> createState() => _PinDumpPageState();
}

class _PinDumpPageState extends State<PinDumpPage> {
  List<PinInfo>? pins;
  bool loading = true;
  String? error;
  Timer? _autoTimer;
  bool _isFetching = false;

  Future<void> fetchPins({bool fromTimer = false}) async {
    if (_isFetching) return; // ardışık talepleri yut
    _isFetching = true;
    final host = widget.deviceIp.trim();
    if (host.isEmpty) {
      setState(() {
        loading = false;
        error = 'Geçerli host/IP yok';
      });
      _isFetching = false;
      return;
    }
    if (!fromTimer) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final res = await http.get(Uri.parse('http://$host/pins'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        pins = data.map((e) => PinInfo.fromJson(e)).toList();
      } else {
        error = 'Cihazdan hata: ${res.statusCode}';
      }
    } catch (e) {
      error = e.toString();
    }
    setState(() {
      loading = false;
    });
    _isFetching = false;
  }

  @override
  void initState() {
    super.initState();
    fetchPins();
    _autoTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      fetchPins(fromTimer: true);
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP32 Pin Dökümü'),
        actions: [
          IconButton(
            onPressed: loading ? null : fetchPins,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Hata: $error'))
              : pins == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Durum')),
                          DataColumn(label: Text('No')),
                          DataColumn(label: Text('Adı')),
                          DataColumn(label: Text('Fonksiyon')),
                          DataColumn(label: Text('Mod')),
                          DataColumn(label: Text('Pull')),
                        ],
                        rows: pins!
                            .map((p) => DataRow(cells: [
                                  DataCell(_statusDot(p.active)),
                                  DataCell(Text(p.number.toString())),
                                  DataCell(Text(p.name)),
                                  DataCell(Text(p.function)),
                                  DataCell(Text(p.mode)),
                                  DataCell(Text(p.pull)),
                                ]))
                            .toList(),
                      ),
                    ),
    );
  }

  Widget _statusDot(bool? active) {
    Color c;
    String label;
    if (active == null) {
      c = Colors.grey;
      label = 'Bilinmiyor';
    } else if (active) {
      c = Colors.green;
      label = 'Aktif/Bağlı';
    } else {
      c = Colors.redAccent;
      label = 'Pasif';
    }
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
