//
//  BridgeSecurity.swift
//  flutter_amanisdk
//

import Flutter
import UIKit

/// Argument validation and UI helpers shared by the bridge modules.
enum BridgeSecurity {

  /// Error code used for rejected arguments (kept in line with the existing "30009").
  static let invalidArgumentCode = "30009"

  /// Returns the server URL when it is safe to talk to, otherwise nil.
  ///
  /// Credentials and KYC data must never travel over cleartext HTTP, so only `https`
  /// is accepted. `http` is tolerated in DEBUG builds only. A bare host (no scheme) is
  /// left to the Core SDK, which prepends https itself.
  static func validatedServer(_ server: String?) -> String? {
    guard let raw = server?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
      return nil
    }
    guard raw.contains("://") else { return raw }
    guard let url = URL(string: raw), let scheme = url.scheme?.lowercased(),
          let host = url.host, !host.isEmpty else {
      return nil
    }
    if scheme == "https" { return raw }
    #if DEBUG
    if scheme == "http" { return raw }
    #endif
    return nil
  }

  static func invalidArgument(_ message: String) -> FlutterError {
    FlutterError(code: invalidArgumentCode, message: message, details: nil)
  }

  /// The view controller of the foreground, active window scene.
  ///
  /// `UIApplication.windows.last` is deprecated and can be a keyboard, alert or
  /// other system window, which would host the capture UI in the wrong place.
  static func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
    let window = scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first
    var top = window?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }

  static func pngResponse(_ image: UIImage) -> FlutterStandardTypedData? {
    guard let data = image.pngData() else { return nil }
    return FlutterStandardTypedData(bytes: data)
  }
}
