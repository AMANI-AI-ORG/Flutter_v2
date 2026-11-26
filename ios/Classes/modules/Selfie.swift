//
//  Selfie.swift
//  flutter_amanisdk_v2
//
//  Created by Deniz Can on 14.11.2022.
//

import AmaniSDK
import UIKit
import Flutter

class Selfie {
  private let module = Amani.sharedInstance.selfie()
  private var sdkView: SDKView!
  
  public func start(result: @escaping FlutterResult) {
    guard let vc = BridgeSecurity.topViewController() else {
      result(FlutterError(code: "30007", message: "No active view controller to present the capture UI", details: nil))
      return
    }
    do {
      let moduleView = try module.start { image in
        guard let payload = BridgeSecurity.pngResponse(image) else {
          result(FlutterError(code: "30007", message: "Captured image could not be encoded", details: nil))
          return
        }
        result(payload)
        DispatchQueue.main.async {
          self.sdkView.removeFromSuperview()
        }
      }
     
      guard let captureView = moduleView else {
        result(FlutterError(code: "30032", message: "The SDK did not return a capture view", details: nil))
        return
      }
      sdkView = SDKView(sdkView: captureView)
      sdkView.start(on: vc)
      sdkView.setupBackButton(on: captureView)
    } catch let err {
      result(FlutterError(code: "30007", message: err.localizedDescription, details: nil))
    }
  }
  
  public func setType(type: String, result: @escaping FlutterResult) {
    module.setType(type: type)
    result(nil)
  }
  
  public func upload(result: @escaping FlutterResult) {
    module.upload { isSuccess in
      result(isSuccess)
    }
  }

  /// Uploads the selfie and returns {"isSuccess": Bool, "documentId": String?}.
  public func upload(result: @escaping FlutterResult, returnDocumentId: Bool) {
    guard returnDocumentId else { upload(result: result); return }
    module.upload { (isSuccess: Bool?, documentId: String?) in
      UploadResultPayload.send(isSuccess: isSuccess, documentId: documentId, module: "Selfie", to: result)
    }
  }
  
}
