import 'package:flutter_test/flutter_test.dart';
import 'package:shifushotlocal/state/guest_session.dart';

void main() {
  group('GuestSession', () {
    // Singleton: reset between tests by calling exitGuestMode.
    tearDown(() => GuestSession.instance.exitGuestMode());

    test('starts non-guest by default', () {
      expect(GuestSession.instance.isGuest, isFalse);
    });

    test('enterGuestMode flips the flag and notifies listeners', () {
      var notified = 0;
      void listener() => notified++;
      GuestSession.instance.addListener(listener);
      addTearDown(() => GuestSession.instance.removeListener(listener));

      GuestSession.instance.enterGuestMode();

      expect(GuestSession.instance.isGuest, isTrue);
      expect(notified, 1);
    });

    test('enterGuestMode is idempotent (no duplicate notifications)', () {
      var notified = 0;
      void listener() => notified++;
      GuestSession.instance.enterGuestMode();
      GuestSession.instance.addListener(listener);
      addTearDown(() => GuestSession.instance.removeListener(listener));

      GuestSession.instance.enterGuestMode();
      GuestSession.instance.enterGuestMode();

      expect(notified, 0);
    });

    test('exitGuestMode returns to non-guest and notifies', () {
      GuestSession.instance.enterGuestMode();
      var notified = 0;
      void listener() => notified++;
      GuestSession.instance.addListener(listener);
      addTearDown(() => GuestSession.instance.removeListener(listener));

      GuestSession.instance.exitGuestMode();

      expect(GuestSession.instance.isGuest, isFalse);
      expect(notified, 1);
    });
  });
}
