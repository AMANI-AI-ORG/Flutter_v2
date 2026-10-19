//
//  UploadResultPayload.swift
//  flutter_amanisdk
//

import Flutter
import Foundation

/// Builds the payload an upload call made with `returnDocumentId: true` returns to Flutter.
/// Flutter receives: {"isSuccess": Bool, "documentId": String?}
enum UploadResultPayload {
  static func send(
    isSuccess: Bool?,
    documentId: String?,
    module: String,
    to result: @escaping FlutterResult
  ) {
    print("[AmaniBridge][\(module)] upload result isSuccess=\(String(describing: isSuccess)) documentId=\(String(describing: documentId))")
    let payload: [String: Any] = [
      "isSuccess": isSuccess ?? false,
      "documentId": documentId ?? NSNull(),
    ]
    DispatchQueue.main.async {
      result(payload)
    }
  }
}
