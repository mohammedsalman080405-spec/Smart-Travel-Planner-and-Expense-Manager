import 'package:flutter/material.dart';

class GlobeProvider extends ChangeNotifier {
  // Current focal coordinates
  double _targetLatitude = 17.385044; // Default Hyderabad / Central
  double _targetLongitude = 78.486671;
  double _currentLatitude = 17.385044;
  double _currentLongitude = 78.486671;

  double _zoomLevel = 1.0;
  bool _isAutoRotating = true;
  bool _isAnimatingToTarget = false;

  double get targetLatitude => _targetLatitude;
  double get targetLongitude => _targetLongitude;
  double get currentLatitude => _currentLatitude;
  double get currentLongitude => _currentLongitude;
  double get zoomLevel => _zoomLevel;
  bool get isAutoRotating => _isAutoRotating;
  bool get isAnimatingToTarget => _isAnimatingToTarget;

  void setCoordinates(double lat, double lng, {bool animate = true}) {
    _targetLatitude = lat;
    _targetLongitude = lng;
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
    _zoomLevel = 1.0;
    _isAutoRotating = true;
    _isAnimatingToTarget = false;
    notifyListeners();
  }
}
