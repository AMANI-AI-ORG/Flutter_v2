//
//  DocumentCapture.swift
//  flutter_amanisdk
//
//  Created by Deniz Can on 27.02.2024.
//

import AmaniSDK
import Flutter
import Foundation

class DocumentCapture {
  private let module = Amani.sharedInstance.document()
  private var sdkView: SDKView!

  func start(documentCount: Int? = 1, result: @escaping FlutterResult) {
    let vc = UIApplication.shared.windows.last?.rootViewController

    do {
      if let moduleView = try module.start(stepId: documentCount!-1, completion: { image in
        if let data = image.pngData() {
          result(FlutterStandardTypedData(bytes: data))
        }
        DispatchQueue.main.async {
          self.sdkView.removeFromSuperview()
        }
      }) {
        sdkView = SDKView(sdkView: moduleView)
        sdkView.start(on: vc!)
        sdkView.setupBackButton(on: moduleView)
      }
    } catch {
      result(FlutterError(code: "30007", message: error.localizedDescription, details: nil))
    }
  }

  func setType(type: String, result: @escaping FlutterResult) {
    module.setType(type: type)
    result(nil)
  }

  func upload(files: [FileWithType]?, result: @escaping FlutterResult) {
    if let files = files {
      module.upload(location: nil, files: files) { (uploadRes: Bool?, _: [String: Any]?) in
        result(uploadRes)
      }
    } else {
      module.upload(completion: { uploadRes in
        result(uploadRes)
      })
    }
  }

  /// Uploads the captured document (or the given files) and returns
  /// {"isSuccess": Bool, "documentId": String?}.
  func uploadWithDocumentId(files: [FileWithType]?, result: @escaping FlutterResult) {
    if let files = files {
      module.upload(location: nil, files: files) { (isSuccess: Bool?, documentId: String?) in
        UploadResultPayload.send(isSuccess: isSuccess, documentId: documentId, module: "DocumentCapture", to: result)
      }
    } else {
      module.upload { (isSuccess: Bool?, documentId: String?) in
        UploadResultPayload.send(isSuccess: isSuccess, documentId: documentId, module: "DocumentCapture", to: result)
      }
    }
  }
}
