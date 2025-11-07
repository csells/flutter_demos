import 'package:flutter/foundation.dart';

class AppStepState with ChangeNotifier {
  int _currentStep = 0;
  int get currentStep => _currentStep;

  void nextStep() {
    if (_currentStep < 4) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void reset() {
    _currentStep = 0;
    notifyListeners();
  }
}
