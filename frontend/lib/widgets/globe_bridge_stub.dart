import 'package:flutter/material.dart';

Widget buildGlobeWidget({
  required void Function(Map<String, dynamic> msg) onMessageReceived,
  required void Function(void Function(Map<String, dynamic> msg) sender) onSenderReady,
}) {
  return Container(
    color: const Color(0xFF080E1E),
    alignment: Alignment.center,
    child: const Text(
      'Realistic 3D Earth Globe (WebGL)',
      style: TextStyle(color: Colors.white70),
    ),
  );
}
