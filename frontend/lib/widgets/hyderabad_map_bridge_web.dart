import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

Widget buildMapWidget({
  required void Function(Map<String, dynamic> msg) onMessageReceived,
  required void Function(void Function(Map<String, dynamic> msg) sender) onSenderReady,
}) {
  return _WebHyderabadMapWidget(
    onMessageReceived: onMessageReceived,
    onSenderReady: onSenderReady,
  );
}

class _WebHyderabadMapWidget extends StatefulWidget {
  final void Function(Map<String, dynamic> msg) onMessageReceived;
  final void Function(void Function(Map<String, dynamic> msg) sender) onSenderReady;

  const _WebHyderabadMapWidget({
    required this.onMessageReceived,
    required this.onSenderReady,
  });

  @override
  State<_WebHyderabadMapWidget> createState() => _WebHyderabadMapWidgetState();
}

class _WebHyderabadMapWidgetState extends State<_WebHyderabadMapWidget> {
  static bool _viewRegistered = false;
  static web.HTMLIFrameElement? _iframeElement;
  static const String viewType = 'hyderabad-discovery-map-view';

  JSFunction? _messageListener;

  @override
  void initState() {
    super.initState();
    _registerViewFactory();
    _setupMessageListener();
    widget.onSenderReady(_sendMessageToMap);
  }

  void _registerViewFactory() {
    if (_viewRegistered) return;
    _viewRegistered = true;

    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..id = 'hyderabad-map-iframe'
        ..src = 'map/hyderabad_map.html'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = '#000000'
        ..allow = 'accelerometer; gyroscope';

      _iframeElement = iframe;
      return iframe;
    });
  }

  void _setupMessageListener() {
    _messageListener = ((web.MessageEvent event) {
      final rawData = event.data;
      if (rawData == null) return;

      try {
        final dartVal = rawData.dartify();
        Map<String, dynamic> msg = {};

        if (dartVal is String) {
          msg = jsonDecode(dartVal) as Map<String, dynamic>;
        } else if (dartVal is Map) {
          msg = Map<String, dynamic>.from(dartVal);
        }

        widget.onMessageReceived(msg);
      } catch (_) {}
    }).toJS;

    web.window.addEventListener('message', _messageListener!);
  }

  void _sendMessageToMap(Map<String, dynamic> message) {
    final iframe = _iframeElement ?? (web.document.getElementById('hyderabad-map-iframe') as web.HTMLIFrameElement?);
    if (message['type'] == 'SET_BLUR') {
      final blurred = message['blurred'] == true;
      if (iframe != null) {
        iframe.style.filter = blurred ? 'blur(10px)' : 'none';
        iframe.style.transition = 'filter 0.3s ease';
      }
    }
    if (iframe?.contentWindow != null) {
      final jsonStr = jsonEncode(message);
      iframe!.contentWindow!.postMessage(jsonStr.toJS, '*'.toJS);
    }
  }

  @override
  void dispose() {
    if (_messageListener != null) {
      web.window.removeEventListener('message', _messageListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(
      child: HtmlElementView(viewType: viewType),
    );
  }
}
