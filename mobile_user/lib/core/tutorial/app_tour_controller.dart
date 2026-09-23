import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum AppTourStep {
  idle,
  clickPreOp,
  clickFirstVideo,
  pauseVideo,
  goBackFromPlayer,
  selectVideosFromHereOnly,
}

class AppTourController extends ChangeNotifier {
  static final AppTourController instance = AppTourController._internal();
  AppTourController._internal();

  AppTourStep _currentStep = AppTourStep.idle;
  bool _isManual = false;

  AppTourStep get currentStep => _currentStep;
  bool get isActive => _currentStep != AppTourStep.idle;
  bool get isManual => _isManual;

  static const String _boxName = 'settings';
  static const String _prefKey = 'has_seen_tutorial';

  /// Checks Hive storage to determine if the first-time tour should run.
  bool get hasSeenTutorial {
    if (!Hive.isBoxOpen(_boxName)) return false;
    final box = Hive.box(_boxName);
    return box.get(_prefKey, defaultValue: false) as bool;
  }

  /// Evaluates whether the automatic onboarding tour should start on app launch.
  Future<bool> shouldShowOnStartup() async {
    final box = Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);
    final bool hasSeen = box.get(_prefKey, defaultValue: false) as bool;
    return !hasSeen;
  }

  /// Starts the interactive walkthrough from Step 1 (Pre-op).
  void startTour({bool isManual = false}) {
    _isManual = isManual;
    _currentStep = AppTourStep.clickPreOp;
    notifyListeners();
  }

  /// Advances to a specific step.
  void setStep(AppTourStep step) {
    if (_currentStep == step) return;
    _currentStep = step;
    notifyListeners();
  }

  /// Skips the tour and marks it as completed.
  Future<void> skipTour() async {
    await finishTour();
  }

  /// Completes the tour and stores completion flag in Hive.
  Future<void> finishTour() async {
    _currentStep = AppTourStep.idle;
    notifyListeners();

    try {
      final box = Hive.isBoxOpen(_boxName)
          ? Hive.box(_boxName)
          : await Hive.openBox(_boxName);
      await box.put(_prefKey, true);
    } catch (e) {
      debugPrint('[AppTourController] Error saving tutorial completion: $e');
    }
  }

  /// Resets tutorial flag for testing or replaying.
  Future<void> resetTutorial() async {
    final box = Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);
    await box.put(_prefKey, false);
    _currentStep = AppTourStep.idle;
    notifyListeners();
  }
}
