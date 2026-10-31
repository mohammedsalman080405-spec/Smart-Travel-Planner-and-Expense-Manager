import 'package:flutter/material.dart';
import 'hyderabad_map_bridge_stub.dart'
    if (dart.library.js_interop) 'hyderabad_map_bridge_web.dart';

Widget buildHyderabadMap({
  required void Function(Map<String, dynamic> msg) onMessageReceived,
  required void Function(void Function(Map<String, dynamic> msg) sender) onSenderReady,
}) {
  return buildMapWidget(
    onMessageReceived: onMessageReceived,
    onSenderReady: onSenderReady,
  );
}
