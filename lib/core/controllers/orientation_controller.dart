import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Controla o bloqueio/desbloqueio de orientação do dispositivo.
/// Migrado de `ChangeNotifier`/Provider para `GetxController` (estado unificado).
class OrientationController extends GetxController {
  Orientation _currentOrientation = Orientation.portrait;
  bool _isLocked = false;

  Orientation get currentOrientation => _currentOrientation;
  bool get isLocked => _isLocked;

  void setOrientation(Orientation orientation) {
    if (_currentOrientation != orientation) {
      _currentOrientation = orientation;
      update();
    }
  }

  Future<void> lockOrientation(Orientation orientation) async {
    _isLocked = true;
    List<DeviceOrientation> orientations;

    if (orientation == Orientation.portrait) {
      orientations = [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ];
    } else {
      orientations = [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ];
    }

    await SystemChrome.setPreferredOrientations(orientations);
    setOrientation(orientation);
  }

  Future<void> unlockOrientation() async {
    _isLocked = false;
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    update();
  }
}
