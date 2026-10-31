import 'package:flutter/material.dart';
import 'globe_bridge_stub.dart'
    if (dart.library.js_interop) 'globe_bridge_web.dart';

Widget buildEarthGlobe({
  required void Function(Map<String, dynamic> msg) onMessageReceived,
  required void Function(void Function(Map<String, dynamic> msg) sender) onSenderReady,
}) {
  return buildGlobeWidget(
    onMessageReceived: onMessageReceived,
    onSenderReady: onSenderReady,
  );
}
