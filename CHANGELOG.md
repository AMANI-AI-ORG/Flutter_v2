# Changelog

## Unreleased — security hardening

- All: `server` must be `https` (plain `http` only in debug builds), validated in Dart and in both native bridges. A bare host is still accepted.
- All: JWT payload parsing no longer throws a raw `FormatException`; whitespace-only `sharedSecret` is rejected in Dart too.
- All: logs no longer include document ids or MRZ-derived data, and native logging is silent in release builds (Android: non-debuggable host apps; iOS: non-DEBUG builds).
- Android: native errors no longer echo SDK exception messages; settings JSON is parsed null-safely; every channel call is wrapped so malformed arguments become a `BRIDGE_ERROR` instead of a crash.
- Android: host activity must be a `FragmentActivity` (checked up front instead of a `ClassCastException`).
- Android NFC: removed the mutable `PendingIntent` foreground dispatch (it targeted a non-Activity class), clear MRZ values after read/disable, no `!!` on MRZ/exception values.
- Android DocumentCapture: fixed a double reply / NPE when no image is returned, and unchecked casts in `setFiles`.
- Android Gradle: `gson` 2.8.6 -> 2.10.1; the speech-verifier Maven repo is restricted to `ai.amani.android`.
- iOS: removed force unwraps (`as!`, `try!`, `!`) on channel arguments, images and view controllers; invalid input now returns a `FlutterError` instead of crashing the host app.
- iOS: presenting view controller comes from the active window scene instead of `windows.last`; `initAmani` can no longer leave the Dart future pending when the SDK returns neither a customer nor an error.
- Example: no cloud backup, cleartext traffic disabled, `NFC` permission fixed, storage permissions limited to the SDK levels that need them.
- Repo: `.gitignore` now excludes keystores, certificates, provisioning profiles and `.env` files.

## 2.2.5

- Android: re-attach AmaniEvent listener after configure/startSession.
- iOS: upload source support.
