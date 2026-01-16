import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/widgets/operator_panel.dart';
import 'src/widgets/reports_page.dart';
import 'src/models/machine_event.dart';
import 'src/widgets/technician_menu_extra.dart';

void main() => runApp(const SgmProHmi());

class SgmProHmi extends StatelessWidget {
  const SgmProHmi({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
      ),
      home: const AnaPanel(),
    );
  }
}

class AnaPanel extends StatefulWidget {
  const AnaPanel({super.key});
  @override
  State<AnaPanel> createState() => _AnaPanelState();
}

class _AnaPanelState extends State<AnaPanel> {
  bool _pressureOk = true;
  bool _vacuumOk = true;
  final String ip = "192.168.4.1";
  Timer? _pollTimer;
  String _password = '1234';
  int _sayfaIndex = 0;
  List<ProductionReport> _reports = [];
  List<MachineEvent> _events = [];
  int sayac = 0;
  int _targetProduction = 0;
  bool _targetReached = false;
  bool _stoppedForError = false;
  bool _pendingReset = false;
  final List<Map<String, String>> _pinDump = const [
    {'code': 'STEP', 'pin': 'GPIO12', 'desc': 'Stepper adim'},
    {'code': 'DIR', 'pin': 'GPIO13', 'desc': 'Stepper yon'},
    {'code': 'APS 0.1', 'pin': 'GPIO8', 'desc': 'Ana piston asagi'},
    {'code': 'APS 0.2', 'pin': 'GPIO9', 'desc': 'Ana piston yukari'},
    {'code': 'RPS 0.1', 'pin': 'GPIO10', 'desc': 'Ragle piston asagi'},
    {'code': 'RPS 0.2', 'pin': 'GPIO11', 'desc': 'Ragle piston yukari'},
    {'code': 'XL 0.1', 'pin': 'GPIO17', 'desc': 'X sol limit'},
    {'code': 'XR 0.1', 'pin': 'GPIO18', 'desc': 'X sag limit'},
    {'code': 'RXS', 'pin': 'GPIO21', 'desc': 'Ragle X konum sensoru'},
    {'code': 'UBS 0.1', 'pin': 'GPIO16', 'desc': 'Urun band sensoru'},
    {'code': 'TB 0.1', 'pin': 'GPIO26', 'desc': 'Transfer band motor surucu'},
    {'code': 'Basinc ADC', 'pin': 'GPIO6', 'desc': 'Hava basinc sensoru'},
    {'code': 'Vakum ADC', 'pin': 'GPIO4', 'desc': 'Vakum sensoru'},
  ];
  double basinc = 0,
      vakum = 0,
      hiz = 850,
      bant = 1000,
      anaP = 500,
      ragP = 400,
      xBand = 0;
  bool isOnline = false, isOto = true;
  String durum = "BEKLENIYOR";
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 1),
      (t) => _verileriGetir(),
    );
    _loadPassword();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<http.Response> _gonder(String path) =>
      http.get(Uri.parse('http://$ip/$path'));

  Future<void> _handleSend(String path) async {
    // Start komutu öncesinde hedef değiştiyse sayaç sıfırlamayı dene
    if (path.contains('start')) {
      if (_pendingReset || _targetProduction > 0) {
        await _tryResetCounter();
        _pendingReset = false;
      }
    }
    await _gonder(path);
  }

  Future<void> _tryResetCounter() async {
    try {
      await _gonder('cmd?op=reset_counter&pw=$_password');
      setState(() {
        sayac = 0;
        _pendingReset = false;
      });
    } catch (_) {
      // isteğin başarısız olması durumunda sessiz geçilir; bir sonraki poll gerçek değeri getirecek
    }
  }

  Future<void> _loadPassword() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _password = prefs.getString('password') ?? '1234';
    });
  }

  Future<void> _savePassword(String newPass) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password', newPass);
    setState(() => _password = newPass);
  }

  Future<void> _verileriGetir() async {
    try {
      final res = await http
          .get(Uri.parse('http://$ip/status'))
          .timeout(const Duration(milliseconds: 900));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        setState(() {
          void _addReport(int count) {
            final now = DateTime.now();
            _reports.add(ProductionReport(count: count, time: now));
            _reports = _reports
                .where(
                  (r) =>
                      r.time.day == now.day &&
                      r.time.month == now.month &&
                      r.time.year == now.year,
                )
                .toList();
          }

          if (_targetProduction > 0) {
            if (_targetReached) {
              sayac = _targetProduction;
            } else if (d['sayac'] == 0) {
              sayac = 0;
            } else if (d['sayac'] > 0 && sayac == 0) {
              sayac = 1;
              _addReport(1);
            } else if (d['sayac'] > 0 && sayac > 0) {
              if (d['sayac'] > sayac) {
                for (int i = sayac + 1; i <= d['sayac']; i++) {
                  _addReport(i);
                }
              }
              sayac = d['sayac'];
            }
          } else {
            sayac = d['sayac'] ?? 0;
          }
            hiz = (d['hiz'] ?? 850).toDouble();
            bant = (d['bant'] ?? 1000).toDouble();
            anaP = (d['anaP'] ?? 500).toDouble();
            ragP = (d['ragP'] ?? 400).toDouble();
            xBand = (d['xBand'] ?? d['xb'] ?? xBand).toDouble();
          durum = d['durum'] ?? "HAZIR";
          isOto = d['isOto'] ?? true;
          basinc = ((d['basinc'] ?? 0) / 4095) * 10;
          vakum = ((d['vakum'] ?? 0) / 4095) * 10;
          isOnline = true;
          _pressureOk = (d['pressure'] ?? 1) == 1;
          _vacuumOk = (d['vacuum'] ?? 1) == 1;
          String? detectedError;
          String sensorCode = '';
          if (d['error_msg'] != null && (d['error_msg'] as String).isNotEmpty) {
            detectedError = (d['error_msg'] as String).toUpperCase();
          } else {
            if (basinc < 2.0) {
              detectedError = 'HAVA BASINCI YOK';
              sensorCode = 'HBK_SENSOR (GPIO6)';
            } else if (vakum < 1.5) {
              detectedError = 'VAKUM DÜŞÜK';
              sensorCode = 'VK_SENSOR (GPIO4)';
            } else if ((d['durum'] ?? '').toString().toLowerCase().contains(
                  'ana piston',
                )) {
              detectedError = 'ANA PİSTON AŞAĞIYA İNMEDİ';
              sensorCode = 'APS (GPIO8/9)';
            } else if ((d['durum'] ?? '').toString().toLowerCase().contains(
                  'ragle',
                )) {
              detectedError = 'RAGLE PİSTON YERİNE ULAŞMADI';
              sensorCode = 'RPS (GPIO10/11)';
            }
          }
          if (detectedError != null && detectedError.isNotEmpty) {
            if (sensorCode.isNotEmpty) {
              detectedError = '$detectedError (Sensör: $sensorCode)';
            }
            if (_errorMessage != detectedError) {
              _errorMessage = detectedError;
            }
            if (_events.isEmpty || _events.last.reason != detectedError) {
              _events.add(
                MachineEvent(
                  time: DateTime.now(),
                  type: 'ariza',
                  reason: detectedError,
                ),
              );
            }
          }
        });
        if (mounted) {
          if (_errorMessage.isNotEmpty && !_stoppedForError) {
            _events.add(
              MachineEvent(
                time: DateTime.now(),
                type: 'duruş',
                reason: _errorMessage,
              ),
            );
            try {
              await _gonder('cmd?op=stp');
            } catch (_) {}
            setState(() => _stoppedForError = true);
            if (mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Makine hata nedeniyle durduruldu'),
                ),
              );
          } else if (_errorMessage.isEmpty && _stoppedForError) {
            setState(() => _stoppedForError = false);
          }
          if (_targetProduction > 0 &&
              sayac >= _targetProduction &&
              !_targetReached) {
            try {
              await _gonder('cmd?op=stp');
            } catch (_) {}
            setState(() => _targetReached = true);
            if (mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('HEDEFE ULAŞILDI - MAKİNE DURDURULDU'),
                ),
              );
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => isOnline = false);
    }
  }

  void _showChangePasswordDialog() {
    final TextEditingController cur = TextEditingController();
    final TextEditingController np = TextEditingController();
    final TextEditingController np2 = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Şifre Değiştir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cur,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mevcut Şifre'),
            ),
            TextField(
              controller: np,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Yeni Şifre'),
            ),
            TextField(
              controller: np2,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre (Tekrar)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (cur.text != _password) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mevcut şifre yanlış')),
                );
                return;
              }
              if (np.text.isEmpty || np.text != np2.text) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Yeni şifreler uyuşmuyor')),
                );
                return;
              }
              await _savePassword(np.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Şifre değiştirildi')),
              );
            },
            child: const Text('Kaydet'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _performFactoryReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Üretim Sayacı Sıfırlama'),
        content: const Text(
          'Bu işlem yalnızca üretim sayacını sıfırlayacaktır. Program ve uygulama şifresi etkilenmeyecektir. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hayır'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    String message = 'İstek gönderiliyor...';
    try {
      final resp = await _gonder('cmd?op=reset_counter&pw=$_password');
      final body = resp.body;
      if (resp.statusCode == 200) {
        setState(() {
          sayac = 0;
        });
        await Future.delayed(const Duration(milliseconds: 700));
        await _verileriGetir();
        if (sayac == 0) {
          message = 'Üretim sayacı başarıyla sıfırlandı.';
        } else {
          message =
              'Cihaz sayaçı sıfırlamadı. Cihaz cevabı: ${body.isNotEmpty ? body : resp.statusCode.toString()}';
        }
      } else {
        message =
            'Cihazdan hata: ${resp.statusCode} ${body.isNotEmpty ? '- $body' : ''}';
      }
    } catch (e) {
      message = 'Sıfırlama isteği gönderilemedi: $e';
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveSettings() async {
    final params = {
      'bant': bant.toInt(),
      'ap': anaP.toInt(),
      'rp': ragP.toInt(),
      'xb': xBand.toInt(),
    };
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    try {
      await _gonder('set?$query');
      await _verileriGetir();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayarlar kaydedildi')),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ayar kaydedilemedi: $e')),
        );
    }
  }

  void _resetError() async {
    String message = 'İstek gönderiliyor...';
    try {
      final resp = await _gonder('cmd?op=reset_error&pw=$_password');
      if (resp.statusCode == 200) {
        setState(() {
          durum = 'HAZIR';
          _errorMessage = '';
        });
        await _verileriGetir();
        message = 'Hata başarıyla sıfırlandı.';
      } else {
        message = 'Cihazdan hata: ${resp.statusCode}';
      }
    } catch (e) {
      message = 'Hata sıfırlama isteği gönderilemedi: $e';
    }
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setTarget(int v) async {
    final nt = v < 0 ? 0 : v;
    setState(() {
      _targetProduction = nt;
      _targetReached = false;
      _stoppedForError = false;
      sayac = 0; // yeni üretim için ekranda sıfırdan başla
      _pendingReset = true; // cihazda sıfırlamayı beklet
    });
    try {
      // hedefi cihaza yaz
      await _gonder('set?target=$nt');
      // sayaç sıfırlama denemesi
      await _tryResetCounter();
      await _verileriGetir();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hedef $nt kaydedildi')),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hedef kaydedilemedi: $e')),
        );
    }
  }

  void _sifreSorgula() {
    final TextEditingController c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Teknisyen Girişi'),
        content: TextField(
          controller: c,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Şifre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              if (c.text == _password) setState(() => _sayfaIndex = 2);
              Navigator.pop(ctx);
            },
            child: const Text('Giriş'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportReports() async {
    final buffer = StringBuffer();
    buffer.writeln('TÜR;ADET/SEBEP;TARİH-SAAT');
    for (final r in _reports) {
      buffer.writeln('Üretim;${r.count};${r.timeString}');
    }
    for (final e in _events) {
      buffer.writeln(
        '${e.type == 'ariza' ? 'Arıza' : 'Duruş'};${e.reason};${e.timeString}',
      );
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rapor Dışa Aktar'),
        content: SingleChildScrollView(child: Text(buffer.toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _operatorBody() {
    // Sadece klasik hata mesajı ile klasik panel
    List<String> errors = [];
    if (_errorMessage.isNotEmpty) {
      errors.add(_errorMessage);
    } else if (durum.toLowerCase().contains('home') &&
        !durum.toLowerCase().contains('hazir')) {
      errors.add('HOME YAPILAMADI');
    }
    // Kaydırılabilir yapı ile küçük ekranlarda taşmayı engelle
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _uyariBanner(),
        if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: _resetError,
              icon: const Icon(Icons.refresh),
              label: const Text('Hata Reset'),
            ),
          ),
        OperatorPanel(
          sayac: sayac,
          basinc: basinc,
          vakum: vakum,
          hiz: hiz,
          bant: bant,
          isOto: isOto,
          durum: durum,
          isOnline: isOnline,
          errors: errors,
          onReset: _resetError,
          onSend: (p) => _handleSend(p),
          target: _targetProduction,
          onSetTarget: _setTarget,
        ),
      ],
    );
  }

  Widget _uyariBanner() {
    if (_pressureOk && _vacuumOk) return const SizedBox.shrink();
    String msg = '';
    if (!_pressureOk) msg += 'BASINÇLI HAVA YOK! ';
    if (!_vacuumOk) msg += 'VAKUM MOTORU ÇALIŞMIYOR!';
    return Container(
      width: double.infinity,
      color: (_pressureOk && _vacuumOk) ? Colors.green : Colors.red,
      padding: const EdgeInsets.all(12),
      child: Text(
        msg,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _teknisyenBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: const Text('Bant Süresi'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(height: 4),
              Text('Min 100 ms - Max 10000 ms'),
            ],
          ),
          trailing: _ayarS(
            'Bant Suresi',
            bant,
            100,
            10000,
            'bant',
            (nv) => bant = nv,
            unit: ' ms',
          ),
        ),
        ListTile(
          title: const Text('X Bandı Mesafesi'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(height: 4),
              Text('Min 0 mm - Max 1000 mm'),
            ],
          ),
          trailing: _ayarS(
            'X Bandı Mesafesi',
            xBand,
            0,
            1000,
            'xb',
            (nv) => xBand = nv,
            unit: ' mm',
          ),
        ),
        ListTile(
          title: const Text('Ana Piston Süresi'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(height: 4),
              Text('Min 100 ms - Max 5000 ms'),
            ],
          ),
          trailing:
              _ayarS(
            'Ana Piston Suresi',
            anaP,
            100,
            5000,
            'ap',
            (nv) => anaP = nv,
            unit: ' ms',
          ),
        ),
        ListTile(
          title: const Text('Ragle Piston Süresi'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(height: 4),
              Text('Min 100 ms - Max 5000 ms'),
            ],
          ),
          trailing: _ayarS(
            'Ragle Piston Suresi',
            ragP,
            100,
            5000,
            'rp',
            (nv) => ragP = nv,
            unit: ' ms',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
          child: ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('Ayarları Kaydet'),
          ),
        ),
        const Divider(),
        ListTile(
          title: const Text('Şifre Değiştir'),
          trailing: ElevatedButton(
            onPressed: _showChangePasswordDialog,
            child: const Text('Değiştir'),
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PinDumpPage(pinDump: _pinDump),
                ),
              );
            },
            child: const Text('ESP32 Pin Dökümünü Gör'),
          ),
        ),
      ],
    );
  }

  Widget _ayarS(
    String t,
    double v,
    double min,
    double max,
    String p,
    void Function(double) updateValue, {
    String unit = '',
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () {
            final nv = (v - 10).clamp(min, max);
            setState(() => updateValue(nv));
            _gonder("set?$p=${nv.toInt()}");
          },
        ),
        Text('${v.toInt()}$unit'),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            final nv = (v + 10).clamp(min, max);
            setState(() => updateValue(nv));
            _gonder("set?$p=${nv.toInt()}");
          },
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _sayfaIndex == 0
              ? "OPERATOR"
              : _sayfaIndex == 1
                  ? "RAPORLAR"
                  : "TEKNISYEN",
        ),
        actions: [
          Icon(Icons.wifi, color: isOnline ? Colors.green : Colors.red),
          const SizedBox(width: 15),
        ],
      ),
      body: _sayfaIndex == 0
          ? _operatorBody()
          : _sayfaIndex == 1
              ? ReportsPage(
                  reports: _reports,
                  events: _events,
                  onExport: _exportReports,
                )
              : _teknisyenBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _sayfaIndex,
        onTap: (i) {
          if (i == 2) {
            _sifreSorgula();
          } else {
            setState(() => _sayfaIndex = i);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Panel"),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Raporlar",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Ayarlar"),
        ],
      ),
    );
  }
}

class PinDumpPage extends StatelessWidget {
  const PinDumpPage({super.key, required this.pinDump});
  final List<Map<String, String>> pinDump;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ESP32 Pin Dökümü')),
      body: ListView(
        children: pinDump
            .map(
              (p) => ListTile(
                dense: true,
                title: Text(p['code'] ?? ''),
                subtitle: Text(p['desc'] ?? ''),
                trailing: Text(p['pin'] ?? ''),
              ),
            )
            .toList(),
      ),
    );
  }
}
