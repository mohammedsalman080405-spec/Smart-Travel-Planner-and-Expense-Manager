import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../config/theme.dart';

class ModelViewerWidget extends StatefulWidget {
  final String? modelUrl;
  final String title;
  final String? fallbackImageUrl;
  final double height;

  const ModelViewerWidget({
    super.key,
    required this.modelUrl,
    required this.title,
    this.fallbackImageUrl,
    this.height = 450,
  });

  @override
  State<ModelViewerWidget> createState() => _ModelViewerWidgetState();
}

class _ModelViewerWidgetState extends State<ModelViewerWidget> {
  bool _autoRotate = true;

  @override
  Widget build(BuildContext context) {
    final hasValidModel = widget.modelUrl != null &&
        widget.modelUrl!.trim().isNotEmpty &&
        (widget.modelUrl!.endsWith('.glb') || widget.modelUrl!.endsWith('.gltf') || widget.modelUrl!.contains('raw.githubusercontent.com'));

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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  Icon(Icons.view_in_ar_outlined, color: AppTheme.textMuted, size: 24),
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
          )
        ],
      ),
      child: Stack(
        children: [
          // Real interactive 3D GLB model viewer
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ModelViewer(
              backgroundColor: const Color(0xFF070D1B),
              src: widget.modelUrl!,
              alt: '3D model of ${widget.title}',
              ar: false,
              autoRotate: _autoRotate,
              autoRotateDelay: 1000,
              cameraControls: true,
              shadowIntensity: 1.0,
              shadowSoftness: 0.8,
              exposure: 1.2,
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardNavy.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentCyan.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.view_in_ar, color: AppTheme.accentCyan, size: 18),
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
                      IconButton(
                        icon: Icon(
                          _autoRotate ? Icons.pause : Icons.play_arrow,
                          color: _autoRotate ? AppTheme.accentCyan : Colors.white70,
                          size: 20,
                        ),
                        tooltip: _autoRotate ? 'Pause Rotation' : 'Auto Rotate',
                        onPressed: () {
                          setState(() {
                            _autoRotate = !_autoRotate;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.touch_app, color: Colors.white70, size: 18),
                        tooltip: 'Drag with mouse or touch to rotate 360°',
                        onPressed: () {},
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
                    'Drag to rotate • Pinch/Scroll to zoom • Inspect space angles',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
