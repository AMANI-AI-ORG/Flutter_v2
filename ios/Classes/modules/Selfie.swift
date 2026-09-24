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
    let vc = UIApplication.shared.windows.last?.rootViewController
    do {
      let moduleView = try module.start { image in
        let data = image.pngData()
        result(FlutterStandardTypedData(bytes: data!))
        DispatchQueue.main.async {
          self.sdkView.removeFromSuperview()
        }
      }
     
      sdkView = SDKView(sdkView: moduleView!)
      sdkView.start(on: vc!)
      sdkView.setupBackButton(on: moduleView!)
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
  public func uploadWithDocumentId(result: @escaping FlutterResult) {
    module.upload { (isSuccess: Bool?, documentId: String?) in
      UploadResultPayload.send(isSuccess: isSuccess, documentId: documentId, module: "Selfie", to: result)
    }
  }
  
}
