//
//  UploadResultPayload.swift
//  flutter_amanisdk
//

import Flutter
import Foundation

/// Builds the payload every `upload...WithDocumentId` method returns to Flutter.
/// Flutter receives: {"isSuccess": Bool, "documentId": String?}
enum UploadResultPayload {
  static func send(
    isSuccess: Bool?,
    documentId: String?,
    module: String,
    to result: @escaping FlutterResult
  ) {
    print("[AmaniBridge][\(module)] uploadWithDocumentId result isSuccess=\(String(describing: isSuccess)) documentId=\(String(describing: documentId))")
    let payload: [String: Any] = [
      "isSuccess": isSuccess ?? false,
      "documentId": documentId ?? NSNull(),
    ]
    DispatchQueue.main.async {
      result(payload)
    }
  }
}
