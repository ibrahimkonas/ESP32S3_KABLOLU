import 'package:flutter/material.dart';
import 'pin_dump_page.dart';

class TechnicianMenuExtra extends StatelessWidget {
  final String deviceIp;
  const TechnicianMenuExtra({super.key, required this.deviceIp});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PinDumpPage(deviceIp: deviceIp),
            ));
          },
          child: const Text('ESP32 Pin Dökümünü Gör'),
        ),
      ],
    );
  }
}
