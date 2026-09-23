//
//  IdCapture.swift
//  flutter_amanisdk_v2
//
//  Created by Deniz Can on 14.11.2022.
//

import AmaniSDK
import Flutter
import UIKit

class IdCapture {
  private let module = Amani.sharedInstance.IdCapture()
  private var sdkView: SDKView!

  public func start(stepID: Int, result: @escaping FlutterResult) {
    let vc = UIApplication.shared.windows.last?.rootViewController
    print("[AmaniBridge][IDCapture] start stepID=\(stepID)")
    do {
       let moduleView = try module.start(stepId: stepID) { image in
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
  
  @available(iOS 13, *)
 public func startNFC(nvi: AmaniSDK.NviModel?, enablePACE: Bool? = nil) async -> Bool {
  print("[AmaniBridge][IDCapture] startNFC called")
  if let nvi = nvi {
    do {
       let result = await module.startNFC(nvi: nvi, enablePACE: enablePACE)
      print("IDCAPTURE SWIFT TARAFINDA STARTNFC BASARIYLA TAMAMLANDI: \(result)")
      return result
    } catch(let error) {
     return false
    }
  }
  return false

  }
  
  public func setType(type: String, result: @escaping FlutterResult) {
    module.setType(type: type)
    result(nil)
  }
  
  public func upload(result: @escaping FlutterResult) {
    print("[AmaniBridge][IDCapture] upload called")
    module.upload { isSuccess in
      result(isSuccess)
    }
  }
  
  /// Uploads the captured ID and returns both the result and the created documentId.
  /// Flutter receives: {"isSuccess": Bool, "documentId": String?}
  public func uploadWithDocumentId(result: @escaping FlutterResult) {
    print("[AmaniBridge][IDCapture] uploadWithDocumentId called")
    module.uploadWithDocumentId { isSuccess, documentId in
      print("[AmaniBridge][IDCapture] uploadWithDocumentId result isSuccess=\(String(describing: isSuccess)) documentId=\(String(describing: documentId))")
      let payload: [String: Any] = [
        "isSuccess": isSuccess ?? false,
        "documentId": documentId ?? NSNull()
      ]
      DispatchQueue.main.async {
        result(payload)
      }
    }
  }
  
  public func setManualCaptureButtonTimeout(timeout: Int, result: @escaping FlutterResult) {
    module.setManualCropTimeout(Timeout: timeout)
    result(nil)
  }
  
  public func setVideoRecording(enabled: Bool, result: @escaping FlutterResult) {
    module.setVideoRecording(enabled: enabled)
    result(nil)
  }
  
  public func setHologramDetection(enabled: Bool, result: @escaping FlutterResult) {
    module.setIdHologramDetection(enabled: enabled)
    result(nil)
  }
  // Requests MRZ data for the captured ID; the MRZ itself arrives via mrzInfoDelegate.
  public func getMrz(result: @escaping FlutterResult) {
    print("[AmaniBridge][IDCapture] getMrz called")
  
    self.module.getMrz { mrzData in 
        print("[AmaniBridge][IDCapture] getMrz completed documentId=\(String(describing: mrzData))")
            result(mrzData)
    }
    }
  }


