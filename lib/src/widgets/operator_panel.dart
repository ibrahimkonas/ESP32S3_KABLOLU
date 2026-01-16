import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class OperatorPanel extends StatefulWidget {
  final int sayac;
  final double basinc;
  final double vakum;
  final double hiz;
  final double bant;
  final bool isOto;
  final String durum;
  final bool isOnline;
  final List<String> errors;
  final VoidCallback onReset;
  final int target;
  final void Function(int) onSetTarget;
  final void Function(String path) onSend;

  const OperatorPanel({
    super.key,
    required this.sayac,
    required this.basinc,
    required this.vakum,
    required this.hiz,
    required this.bant,
    required this.isOto,
    required this.durum,
    required this.isOnline,
    required this.errors,
    required this.onReset,
    required this.onSend,
    required this.target,
    required this.onSetTarget,
  });

  @override
  State<OperatorPanel> createState() => _OperatorPanelState();
}

class _OperatorPanelState extends State<OperatorPanel> {
  late final TextEditingController _targetController;

  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController(text: widget.target.toString());
  }

  @override
  void didUpdateWidget(covariant OperatorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target &&
        _targetController.text != widget.target.toString()) {
      // hedef dışarıdan değişirse kutuyu senkronize et
      _targetController.text = widget.target.toString();
    }
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Widget _saat(String t, double v, Color c) => Container(
      height: 160,
      child: SfRadialGauge(
        axes: [
          RadialAxis(
            minimum: 0,
            maximum: 10,
            ranges: [
              GaugeRange(startValue: 0, endValue: 2, color: Colors.red),
              GaugeRange(startValue: 2, endValue: 8, color: Colors.green),
              GaugeRange(startValue: 8, endValue: 10, color: Colors.orange),
            ],
            pointers: [
              NeedlePointer(value: v),
            ],
            annotations: [
              GaugeAnnotation(
                widget: Text('$t\n${v.toStringAsFixed(2)}',
                    textAlign: TextAlign.center),
                angle: 90,
                positionFactor: 0.7,
              ),
            ],
          ),
        ],
      ));

  @override
  Widget build(BuildContext context) {
    // Türkçe açıklamalar ile istenen operator paneli
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _anaKart('Sayaç', widget.sayac.toString())),
              const SizedBox(width: 10),
              Expanded(child: _durumIcon('Basınç', widget.basinc >= 5)),
              const SizedBox(width: 10),
              Expanded(child: _durumIcon('Vakum', widget.vakum >= 5)),
            ],
          ),
          const SizedBox(height: 16),
          _homeBanner(widget.errors.isNotEmpty, widget.durum, widget.onReset),
          const SizedBox(height: 8),
          _durusSebebi(widget.errors.isNotEmpty ? widget.errors.first : ''),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _anaKart('Hız', widget.hiz.toStringAsFixed(0))),
              const SizedBox(width: 10),
              Expanded(child: _anaKart('Bant', widget.bant.toStringAsFixed(0))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.isOto) return; // zaten aktifse gönderme
                    widget.onSend('cmd?op=oto');
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      widget.isOto ? Colors.green : Colors.grey,
                    ),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                  ),
                  child: const Text('Otomatik'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (!widget.isOto) return; // zaten aktifse gönderme
                    widget.onSend('cmd?op=man');
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      !widget.isOto ? Colors.green : Colors.grey,
                    ),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                  ),
                  child: const Text('Manuel'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onSend('cmd?op=stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('DURDUR'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onSend('cmd?op=start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('BAŞLAT'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Hedef Üretim',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final val = int.tryParse(_targetController.text);
                  if (val != null) {
                    widget.onSetTarget(val);
                  }
                },
                child: const Text('Ayarla'),
              ),
            ],
          ),
          // Spacer kaldırıldı, hata önlendi
        ],
      ),
    );
  }

  // Durum ikonları (yeşil tik veya sarı uyarı)
  Widget _durumIcon(String label, bool ok) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(ok ? Icons.check_circle : Icons.error,
                color: ok ? Colors.green : Colors.orange, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // HOME YAPILAMADI ve hazır durumu
  Widget _homeBanner(bool isError, String durum, VoidCallback onReset) {
    return Card(
      color: isError ? Colors.red : Colors.green,
      child: ListTile(
        title: Text(isError ? 'HOME YAPILAMADI' : 'HAZIR',
            style: const TextStyle(color: Colors.white)),
        subtitle: isError
            ? Text('HAZIR', style: TextStyle(color: Colors.white70))
            : null,
        trailing: isError
            ? ElevatedButton(onPressed: onReset, child: const Text('RESET'))
            : null,
      ),
    );
  }

  // Duruş Sebepleri kutusu
  Widget _durusSebebi(String sebep) {
    if (sebep.isEmpty) return SizedBox.shrink();
    return Card(
      color: Colors.red.shade900,
      child: ListTile(
        leading: Icon(Icons.error, color: Colors.orange),
        title: Text('Duruş Sebepleri', style: TextStyle(color: Colors.orange)),
        subtitle: Text(sebep, style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _anaKart(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }

  Widget _durumMesaji(String durum, bool isError, VoidCallback onReset) {
    return Card(
      color: isError ? Colors.red : Colors.green,
      child: ListTile(
        title: Text(durum, style: const TextStyle(color: Colors.white)),
        trailing: isError
            ? ElevatedButton(
                onPressed: onReset,
                child: const Text('Hata Sıfırla'),
              )
            : null,
      ),
    );
  }
}
