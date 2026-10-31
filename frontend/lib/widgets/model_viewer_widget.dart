import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../config/theme.dart';

const String bundledHotelSuiteModel =
    'assets/assets/models/hotel_guest_room.glb';

class ModelViewerWidget extends StatefulWidget {
  final String? modelUrl;
  final String title;
  final String? fallbackImageUrl;
  final double height;
  final bool useCompleteRoomModel;

  const ModelViewerWidget({
    super.key,
    required this.modelUrl,
    required this.title,
    this.fallbackImageUrl,
    this.height = 450,
    this.useCompleteRoomModel = false,
  });

  @override
  State<ModelViewerWidget> createState() => _ModelViewerWidgetState();
}

class _ModelViewerWidgetState extends State<ModelViewerWidget> {
  bool _autoRotate = false;
  // The complete room includes the en-suite behind the divider. Keep the
  // initial orbit wide enough to show the bed and bathroom together.
  double _cameraDistance = 12;

  void _zoom(double delta) {
    setState(() => _cameraDistance = (_cameraDistance + delta).clamp(5, 24));
  }

  void _resetCamera() {
    setState(() {
      _cameraDistance = 12;
      _autoRotate = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final resolvedModelUrl = widget.useCompleteRoomModel
        ? bundledHotelSuiteModel
        : widget.modelUrl;
    final hasValidModel =
        resolvedModelUrl != null &&
        resolvedModelUrl.trim().isNotEmpty &&
        (resolvedModelUrl.endsWith('.glb') ||
            resolvedModelUrl.endsWith('.gltf'));

    if (!hasValidModel) {
      return Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.cardNavy,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderNavy),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.fallbackImageUrl != null)
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.network(
                    widget.fallbackImageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(20),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.view_in_ar_outlined,
                    color: AppTheme.textMuted,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Interactive 3D Model currently unavailable for this space.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF070D1B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderNavy, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Real interactive 3D GLB model viewer
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ModelViewer(
              backgroundColor: const Color(0xFF070D1B),
              key: ValueKey('$_cameraDistance-$_autoRotate-$resolvedModelUrl'),
              src: resolvedModelUrl,
              alt: '3D model of ${widget.title}',
              ar: false,
              autoRotate: _autoRotate,
              autoRotateDelay: 1000,
              rotationPerSecond: '7deg',
              cameraControls: true,
              disablePan: false,
              disableZoom: false,
              cameraOrbit: '45deg 70deg ${_cameraDistance.toStringAsFixed(1)}m',
              minCameraOrbit: 'auto 15deg 5m',
              maxCameraOrbit: 'auto 105deg 24m',
              fieldOfView: '40deg',
              shadowIntensity: 1.0,
              shadowSoftness: 0.8,
              exposure: 1.0,
              loading: Loading.eager,
            ),
          ),

          // Top Info Banner & Model Controls
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardNavy.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentCyan.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.view_in_ar,
                        color: AppTheme.accentCyan,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Interactive 3D: ${widget.title}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardNavy.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderNavy),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _viewerControl(
                        Icons.center_focus_strong,
                        'Reset camera',
                        _resetCamera,
                      ),
                      _viewerControl(Icons.add, 'Zoom in', () => _zoom(-1.5)),
                      _viewerControl(
                        Icons.remove,
                        'Zoom out',
                        () => _zoom(1.5),
                      ),
                      _viewerControl(Icons.fullscreen, 'Open fullscreen', () {
                        showDialog<void>(
                          context: context,
                          builder: (context) => Dialog.fullscreen(
                            backgroundColor: const Color(0xFF03070D),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ModelViewer(
                                    key: ValueKey(
                                      'fullscreen-$resolvedModelUrl',
                                    ),
                                    src: resolvedModelUrl,
                                    alt: '3D model of ${widget.title}',
                                    ar: false,
                                    cameraControls: true,
                                    disablePan: false,
                                    disableZoom: false,
                                    autoRotate: _autoRotate,
                                    autoRotateDelay: 1000,
                                    rotationPerSecond: '7deg',
                                    cameraOrbit:
                                        '45deg 70deg ${_cameraDistance.toStringAsFixed(1)}m',
                                    minCameraOrbit: 'auto 15deg 5m',
                                    maxCameraOrbit: 'auto 105deg 24m',
                                    fieldOfView: '40deg',
                                    shadowIntensity: 1.0,
                                    shadowSoftness: 0.8,
                                    exposure: 1.0,
                                    loading: Loading.eager,
                                    backgroundColor: const Color(0xFF070D1B),
                                  ),
                                ),
                                Positioned(
                                  top: 18,
                                  right: 18,
                                  child: IconButton.filledTonal(
                                    tooltip: 'Exit fullscreen',
                                    onPressed: () => Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop(),
                                    icon: const Icon(Icons.fullscreen_exit),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      _viewerControl(
                        _autoRotate ? Icons.pause : Icons.play_arrow,
                        _autoRotate ? 'Pause rotation' : 'Resume rotation',
                        () => setState(() => _autoRotate = !_autoRotate),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom interaction guide
          Positioned(
            bottom: 14,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swipe, color: AppTheme.accentCyan, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Drag to rotate • Scroll to zoom • Right-drag to pan',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewerControl(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) => IconButton(
    icon: Icon(icon, color: Colors.white, size: 19),
    tooltip: tooltip,
    onPressed: onPressed,
    visualDensity: VisualDensity.compact,
  );
}
