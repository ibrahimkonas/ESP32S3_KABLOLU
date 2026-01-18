import 'package:flutter/material.dart';

class OperatorPanel extends StatefulWidget {
  final int sayac;
  final double basinc;
  final double vakum;
  final double hiz;
  final double bant;
  final bool isOto;
  final String durum;
  final bool isOnline;
  final bool pressureOk;
  final bool vacuumOk;
  final List<String> errors;
  final int dailyTotal;
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
    required this.pressureOk,
    required this.vacuumOk,
    required this.errors,
    required this.dailyTotal,
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

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.errors.isNotEmpty;
    const Color panelTop = Color(0xFF0D1117);
    const Color panelMid = Color(0xFF121826);
    const Color accent = Color(0xFF4CC2FF);

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [panelTop, panelMid],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _statusHeader(hasError, accent),
              const SizedBox(height: 12),
              _metricGrid(accent),
              const SizedBox(height: 12),
              _pressureVacuumRow(),
              const SizedBox(height: 12),
              _speedPanel(),
              const SizedBox(height: 12),
              _targetInput(),
              const SizedBox(height: 12),
              _alarmList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusHeader(bool hasError, Color accent) {
    final Color banner = hasError ? Colors.red.shade700 : Colors.green.shade600;
    final String title = hasError ? 'SERVİS STOP' : 'MAKİNE HAZIR';
    final String subtitle = widget.durum;
    final bool online = widget.isOnline;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [banner.withOpacity(0.9), banner.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasError ? Icons.warning_amber_rounded : Icons.check_circle,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Chip(
            backgroundColor: online ? accent : Colors.redAccent,
            label: Text(
              online ? 'ONLINE' : 'OFFLINE',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricGrid(Color accent) {
    final cards = [
      _metricBlock('Üretim', widget.sayac.toString(), Colors.greenAccent),
      _metricBlock('Hedef', widget.target.toString(), accent),
      _metricBlock('Mod', widget.isOto ? 'AUTO' : 'MANUAL', widget.isOto ? Colors.blueAccent : Colors.orange),
      _metricBlock('Günlük Üretim', widget.dailyTotal.toString(), Colors.greenAccent, small: true),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        if (isNarrow) {
          return Column(
            children: [
              Row(children: [Expanded(child: cards[0]), const SizedBox(width: 8), Expanded(child: cards[1])]),
              const SizedBox(height: 8),
              Row(children: [Expanded(child: cards[2]), const SizedBox(width: 8), Expanded(child: cards[3])]),
            ],
          );
        }
        return Row(
          children: cards
              .map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c)))
              .toList(),
        );
      },
    );
  }

  Widget _metricBlock(String title, String value, Color accent, {bool small = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161C2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: small ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: small ? 18 : 26,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pressureVacuumRow() {
    final items = [
      _ledStatus('Basınç', widget.pressureOk || widget.basinc >= 2.0, widget.basinc, widget.isOnline),
      _ledStatus('Vakum', widget.vacuumOk || widget.vakum >= 1.5, widget.vakum, widget.isOnline),
    ];
    return Row(
      children: [
        Expanded(child: items[0]),
        const SizedBox(width: 10),
        Expanded(child: items[1]),
      ],
    );
  }

  Widget _speedPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161C2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade800),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.speed, color: Colors.cyanAccent),
              SizedBox(width: 8),
              Text(
                'Hız & Bant',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  'Makine Hızı',
                  widget.hiz.toStringAsFixed(0),
                  Colors.cyanAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _linearGauge(
                  'Bant Hızı',
                  widget.bant,
                  max: 2000,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _targetInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Hedef Üretim'),
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
      ),
    );
  }

  Widget _alarmList() {
    if (widget.errors.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Uyarılar', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...widget.errors.map(
              (e) => ListTile(
                dense: true,
                leading: const Icon(Icons.warning, color: Colors.orange),
                title: Text(e),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, Color color, {bool small = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B2334),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: small ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: small ? 16 : 24, color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _linearGauge(String title, double value, {double max = 2000}) {
    final double v = value.clamp(0, max).toDouble();
    final double pct = (v / max * 100).clamp(0, 100);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B2334),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.35)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title (${pct.toStringAsFixed(0)}%)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: v / max,
              minHeight: 12,
              backgroundColor: Colors.grey.shade800,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
          ),
          const SizedBox(height: 6),
          Text('${v.toStringAsFixed(0)} / ${max.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Chip(
      backgroundColor: color,
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _ledStatus(String label, bool ok, double val, bool online) {
    final bool showOk = ok && online;
    final Color c = showOk ? Colors.green : Colors.red;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B2334),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.45)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: c.withOpacity(0.5), blurRadius: 12, spreadRadius: 1),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Text(
                  showOk ? val.toStringAsFixed(2) : 'YOK',
                  style: TextStyle(color: showOk ? Colors.white70 : Colors.red.shade200),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
