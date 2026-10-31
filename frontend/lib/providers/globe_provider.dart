import 'package:flutter/material.dart';

class GlobeProvider extends ChangeNotifier {
  // Current focal coordinates
  double _targetLatitude = 20.0;
  double _targetLongitude = 20.0;
  double _currentLatitude = 20.0;
  double _currentLongitude = 20.0;

  double _zoomLevel = 1.0;
  double _targetCameraDistance = 15.8;
  bool _isAutoRotating = true;
  bool _isAnimatingToTarget = false;

  double get targetLatitude => _targetLatitude;
  double get targetLongitude => _targetLongitude;
  double get currentLatitude => _currentLatitude;
  double get currentLongitude => _currentLongitude;
  double get zoomLevel => _zoomLevel;
  double get targetCameraDistance => _targetCameraDistance;
  bool get isAutoRotating => _isAutoRotating;
  bool get isAnimatingToTarget => _isAnimatingToTarget;

  void setCoordinates(
    double lat,
    double lng, {
    bool animate = true,
    double cameraDistance = 17.0,
  }) {
    _targetLatitude = lat;
    _targetLongitude = lng;
    _targetCameraDistance = cameraDistance;
    _isAutoRotating = false;

    if (animate) {
      _isAnimatingToTarget = true;
      _zoomLevel = 1.6; // Zoom into region
    } else {
      _currentLatitude = lat;
      _currentLongitude = lng;
    }
    notifyListeners();
  }

  void updateCurrentRotation(double lat, double lng) {
    _currentLatitude = lat;
    _currentLongitude = lng;
    notifyListeners();
  }

  void stopAnimation() {
    _isAnimatingToTarget = false;
    _currentLatitude = _targetLatitude;
    _currentLongitude = _targetLongitude;
    notifyListeners();
  }

  void setZoom(double zoom) {
    _zoomLevel = zoom.clamp(0.8, 2.5);
    notifyListeners();
  }

  void toggleAutoRotate(bool enabled) {
    _isAutoRotating = enabled;
    notifyListeners();
  }

  void resetView() {
    _targetLatitude = 20.0;
    _targetLongitude = 20.0;
    _currentLatitude = 20.0;
    _currentLongitude = 20.0;
    _zoomLevel = 1.0;
    _targetCameraDistance = 15.8;
    _isAutoRotating = true;
    _isAnimatingToTarget = true;
    notifyListeners();
  }
}
