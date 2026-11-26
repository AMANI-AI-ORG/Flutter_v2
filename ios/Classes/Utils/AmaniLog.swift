//
//  AmaniLog.swift
//  flutter_amanisdk
//

import Foundation

/// Debug-only logging for the bridge.
///
/// Release builds must not write to the device log: console output is readable by
/// anyone with physical access (Console.app / sysdiagnose) and may end up in crash
/// and analytics tooling. Never pass tokens, secrets, MRZ data or document ids here.
enum AmaniLog {
  static func d(_ message: @autoclosure () -> String) {
    #if DEBUG
    print(message())
    #endif
  }
}
