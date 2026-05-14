import 'package:flutter/foundation.dart';

class GuestSession extends ChangeNotifier {
  GuestSession._();
  static final GuestSession instance = GuestSession._();

  bool _isGuest = false;
  bool get isGuest => _isGuest;

  void enterGuestMode() {
    if (_isGuest) return;
    _isGuest = true;
    notifyListeners();
  }

  void exitGuestMode() {
    if (!_isGuest) return;
    _isGuest = false;
    notifyListeners();
  }
}
