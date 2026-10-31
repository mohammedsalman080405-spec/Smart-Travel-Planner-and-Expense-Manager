import 'package:flutter/material.dart';

Widget buildMapWidget({
  required void Function(Map<String, dynamic> msg) onMessageReceived,
  required void Function(void Function(Map<String, dynamic> msg) sender) onSenderReady,
}) {
  return const SizedBox.shrink();
}
