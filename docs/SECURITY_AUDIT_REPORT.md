# Flutter Bridge Security Review (`flutter_amanisdk`)

**Branch:** `feat/v3` · **Scope:** Dart API, Android bridge (Kotlin), iOS bridge (Swift), Gradle/Podspec, example app manifests, repo hygiene
**Method:** manual static review of the bridge code. The closed-source native Amani SDKs were *not* audited.

## 0. Summary

| Severity | Found | Fixed in this change | Open |
|---|---|---|---|
| High | 2 | 2 | 0 |
| Medium | 7 | 7 | 0 |
| Low | 6 | 6 | 0 |
| Long-term / hardening | 12 | 0 | 12 |

**Trust boundary.** Dart → platform channel → native bridge → Amani Core SDK. Most findings come from the native bridges trusting whatever Dart sends (URLs, settings JSON, lists, type casts) and from sensitive data (MRZ values, document ids) reaching logs.

**Limits of this review.**
- The Android Kotlin module compiles and `flutter analyze lib` is clean.
- The Swift sources were only syntax-checked with `swiftc -parse`. They have not been built against AmaniSDK, so an iOS build is still required.
- Nothing was run on a device. In particular, the NFC change (M4) needs a test with a real ID or passport.
- The CI workflows were only grepped for secret handling, not reviewed in depth.

---

## 1. High severity

### H1. Server URL could be plain `http` (cleartext transport)
- **Where:** `lib/amani_sdk.dart` (`initAmani`, `initAmaniWithEmail`, `setConfigure`), `FlutterAmanisdkPlugin.kt`, `SwiftFlutterAmanisdkPlugin.swift`, `SpeechVerifierModule.kt`.
- **Issue:** The `server` / `serverURL` value was forwarded to the SDK without checking the scheme. A misconfigured or attacker-influenced value (remote config, deep link, QR payload as in the example app) could send the profile token, shared secret and KYC documents over HTTP, exposing them to a network attacker.
- **Fix:** A single validation rule is applied in Dart and again in both native bridges, because the bridge is the trust boundary.
  - Only `https` is accepted. `http` is allowed only in debug builds (Dart `kDebugMode`, Android `FLAG_DEBUGGABLE`, iOS `#if DEBUG`).
  - A bare host (`example.com`) is still accepted, since the Core SDK prepends `https`.
  - A missing host or an unsupported scheme is rejected with `INVALID_ARGUMENT` (Android) or `30009` (iOS).
- **Compatibility note:** internal test servers that use `http` will stop working in release builds.

### H2. MRZ-derived personal data written to logs in all build types (Dart)
- **Where:** `lib/flutter_amanisdk_method_channel.dart` (`getMrzRequest`, `iOSStartIDCaptureNFC`).
- **Issue:** `debugPrint` is **not** stripped in release builds. The MRZ result map (document number, birth date, expiry date) and the date of birth were printed to the device log. Logs are readable via `adb logcat` or Console.app/sysdiagnose and are often collected by crash tooling.
- **Fix:** The prints were removed. The data is only returned to the caller. A non-sensitive message is logged on decode failure.

---

## 2. Medium severity

### M1. iOS: forced unwraps on channel arguments crash the host app
- **Where:** `SwiftFlutterAmanisdkPlugin.swift` and the iOS modules (about 25 `as!` / `try!` plus `data!`, `moduleView!`, `vc!`, `UIImage(named:)!`, `documentCount!`).
- **Issue:** A missing or mistyped argument, malformed `iosSettings` JSON, or a missing guide-image asset terminated the whole app with a runtime trap. This is a denial of service against the host app and an uncatchable failure from Dart.
- **Fix:** Every one was replaced with `guard let` / `?` and returns a `FlutterError` (`30009` for invalid arguments, `30007` or `30032` for UI/view problems). `NviModel` construction was moved into one validated helper. Guide images load only if all assets resolve.

### M2. Android: unchecked casts and `!!` could crash or reply twice
- **Where:** `FlutterAmanisdkPlugin.kt`, `modules/*.kt`.
- **Issue:**
  - `activity as FragmentActivity` threw `ClassCastException` if the host did not use a `FlutterFragmentActivity`.
  - `closeButton!!`, `frag!!`, `birthDate!!`, `exception!!` and `setFiles` casts (`as ByteArray`, `as ArrayList`) could throw `NullPointerException` or `ClassCastException`.
  - `toObject<T>()` threw on malformed JSON, or returned null for the string `"null"`.
  - **`DocumentCapture`:** when no image was returned, the code replied with an error and then continued, hitting an NPE and risking a second reply to the same `Result`.
- **Fix:**
  - The activity is resolved once as a `FragmentActivity` (`NO_ACTIVITY` if not).
  - All `!!` were removed.
  - `toObject` is now null-safe and returns `INVALID_ARGUMENT`.
  - `setFiles` skips malformed entries.
  - The `DocumentCapture` callback replies exactly once.
  - `onMethodCall` is wrapped so any unexpected exception becomes `BRIDGE_ERROR` instead of crashing the host.

### M3. Sensitive identifiers in native logs
- **Where:** Android `Log.d/e` calls (document ids, MRZ presence flags, NFC state), iOS `print` calls (document ids, raw MRZ model results), `AmaniDelegateEventHandler` event dump (`print(events)`).
- **Issue:** Unconditional logging in release builds.
- **Fix:**
  - **Android:** a `BridgeLog` wrapper logs only when the host app is debuggable. In release it logs only a generic message and the exception class.
  - **iOS:** `AmaniLog.d` compiles to nothing outside `DEBUG`.
  - Document ids and MRZ-derived values were removed from log messages entirely.

### M4. Android NFC: mutable `PendingIntent` pointing at a non-Activity, MRZ kept in memory
- **Where:** `modules/NFC.kt`.
- **Issue:**
  - A foreground dispatch used a `PendingIntent` created with `FLAG_MUTABLE` (`1 shl 25`) for an intent targeting the helper `NFC` class, which is not an Activity. It could never deliver anything useful, and mutable PendingIntents are a known hijacking surface.
  - Birth date, expiry date and document number stayed in a process-wide singleton indefinitely.
- **Fix:** The foreground dispatch was removed, because `enableReaderMode` already delivers tags. MRZ fields are cleared after a successful read and in `disableNFC`. The `NFCModule` reference is now lazy, so it no longer resolves the SDK singleton before the SDK is configured.
- **Needs validation** on real hardware, since this changes the NFC session setup.

### M5. Verbose exception text returned over the channel
- **Where:** `Amani.configure` / `initAmani` / `startSession` error paths, `SpeechVerifierModule` JSON parsing.
- **Issue:** `e.message` was returned to Dart (and possibly shown in UI or crash reports). `org.json` error messages can echo parts of the input, and the speech-verifier settings JSON contains a token.
- **Fix:** Errors now return the exception class only, with details visible in debug logs.

### M6. Outdated Gson with known deserialization DoS (CVE-2022-25647)
- **Where:** `android/build.gradle` (`gson:2.8.6`).
- **Issue:** The bridge uses Gson on data coming from Dart.
- **Fix:** Upgraded to `2.10.1`.

### M7. Maven dependency-confusion exposure
- **Where:** `android/build.gradle`.
- **Issue:** The JFrog speech-verifier repository had no content filter, so it could be asked for any group/artifact.
- **Fix:** Restricted with `content { includeGroup "ai.amani.android" }`, matching the GitHub-hosted repository.
- **Open follow-up:** the `jitpack.io` repository is still declared without a filter (see L-T3).

---

## 3. Low severity

| # | Issue | Fix |
|---|---|---|
| L1 | iOS presented capture UI on `UIApplication.shared.windows.last` (deprecated, can be a keyboard or alert window). | `BridgeSecurity.topViewController()` uses the foreground-active scene's key window and follows presented controllers. |
| L2 | iOS `initAmani` / `initAmaniWithEmail` never replied when the SDK returned neither a customer nor an error, leaving the Dart future pending forever. | Replies `30010`. |
| L3 | Dart JWT parsing used raw `base64Decode` / `jsonDecode`, throwing an unhelpful `FormatException`. | `AmaniInputValidation.decodeJwtPayload` returns null and the caller throws a clean "Invalid JWT token format". |
| L4 | Dart accepted a whitespace-only `sharedSecret` and sent it to native. | Rejected in Dart as well (the value is redacted in the error). |
| L5 | Example manifest: non-existent `android.permission.ScanNFC`, unrestricted legacy storage permissions, backup enabled, cleartext not explicitly disabled. | Uses `NFC` plus an optional `uses-feature`. Storage permissions are limited with `maxSdkVersion` (28 for write, 32 for read). `allowBackup=false`, `fullBackupContent=false`, `usesCleartextTraffic=false`. |
| L6 | `.gitignore` did not exclude keystores, certificates, provisioning profiles or `.env`. | Added. `example/android/key.properties` was confirmed untracked. |

---

## 4. Long-term recommendations (not done, ordered by priority)

### Priority A: do next
1. **Replace the MRZ string dump with a structured event (iOS).** `DelegateEventHandler.mrzInfo` emits `String(describing: mrz)`, and Dart recovers fields with a regex (`_parseMrzData`). This is fragile and ships PII as a debug-description string. Emit a typed map (`mrzDocumentNumber`, `mrzBirthDate`, `mrzExpiryDate`) and drop the regex.
2. **Certificate pinning guidance or support.** There is no pinning for the Amani server. At minimum document an Android `network-security-config` and an iOS ATS/`URLSession` pinning recipe. Ideally expose it through `setConfigure` if the native SDKs support it.
3. **Shared secret and token handling.**
   - Document clearly that `sharedSecret` must never ship in the app binary and must be provisioned per-session from the backend.
   - Consider deprecating `sharedSecret` on `initAmani`.
   - Avoid sending the `initAmaniWithEmail` password across the channel (it is already debug-only; consider removing it from the public API).
4. **Add automated tests.** The repo has no `test/` directory. Add unit tests for `AmaniInputValidation` and a method-channel contract test. Add native unit tests for the argument guards (`BridgeSecurity`, `validatedServer`) so regressions in these checks are caught in CI.

### Priority B
5. **Captured image lifetime.** ID, selfie and signature images are returned as full `Uint8List` through the channel and, on Android, are read from SDK temp files (`DocumentCapture` reads `listOfDocumentAbsolutePath`). Confirm with the SDK team that temp files are deleted after upload. Consider returning only a handle or a thumbnail to Dart.
6. **iOS static `sessionToken` / `sessionServerURL`.** `SwiftFlutterAmanisdkPlugin` keeps the profile token in static memory for the Speech Verifier. Clear it when the session ends or after the verifier finishes, or pass it per call.
7. **Screen-capture protection.** Consider `FLAG_SECURE` on Android and a screen-recording/screenshot observer on iOS while ID/selfie/signature screens are visible. This could be an opt-in setting.
8. **Dependency hygiene in CI.** Add Dependabot or Renovate for Gradle, CocoaPods and pub. Run `gradle dependencies` / OSV scanning, and pin the CI GitHub Actions to commit SHAs.
9. **Review the `jitpack.io` repository** (`buildscript` and `allprojects`). It is unscoped. Remove it if unused, or use `exclusiveContent` for the specific groups that need it.

### Priority C
10. **Obfuscation rules.** The example `proguard-rules.pro` keeps `-keep class ai.** {*;}` and `io.flutter.**`, which defeats obfuscation of the SDK and bridge. Ship minimal `consumer-rules.pro` from the plugin and narrow the keeps to what reflection actually needs.
11. **Permission minimization.** Re-check whether the example's `READ_PHONE_STATE`, fine location and storage permissions are really required by the SDK, and document which are optional in the README.
12. **Device integrity signals.** Optionally expose root/jailbreak/hook detection or Play Integrity / App Attest as an opt-in, since this is a KYC product. This is a product decision, not a bridge defect.

---

## 5. Behavior changes to communicate to integrators
- `http://` server URLs are rejected in release builds (debug builds are unaffected).
- Invalid or missing channel arguments now produce channel errors (`INVALID_ARGUMENT` / `30009` / `BRIDGE_ERROR`) rather than crashes.
- Android error messages from `configure` / `initAmani` / `startSession` no longer include the underlying exception message.
- `FlutterFragmentActivity` is required on Android and now fails with a clear `NO_ACTIVITY` message.

## 6. Verification checklist before release
- [ ] Build the example app for iOS and Android in release mode.
- [ ] Real-device NFC read (Android) after the foreground-dispatch removal (M4).
- [ ] Confirm no sensitive data appears in `logcat` / Console in a release build.
- [ ] Attempt `setConfigure(server: "http://…")` in release. It must fail with `INVALID_ARGUMENT` / `30009`.
- [ ] Send deliberately bad arguments from Dart (missing `type`, malformed `iosSettings`) on iOS. The app must not crash.
