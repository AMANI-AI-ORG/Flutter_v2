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
    guard let vc = BridgeSecurity.topViewController() else {
      result(FlutterError(code: "30007", message: "No active view controller to present the capture UI", details: nil))
      return
    }
    AmaniLog.d("[AmaniBridge][IDCapture] start stepID=\(stepID)")
    do {
       let moduleView = try module.start(stepId: stepID) { image in
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
  
  @available(iOS 13, *)
 public func startNFC(nvi: AmaniSDK.NviModel?, enablePACE: Bool? = nil) async -> Bool {
  AmaniLog.d("[AmaniBridge][IDCapture] startNFC called")
  if let nvi = nvi {
    do {
       let result = await module.startNFC(nvi: nvi, enablePACE: enablePACE)
      AmaniLog.d("[AmaniBridge][IDCapture] startNFC finished success=\(result)")
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
    AmaniLog.d("[AmaniBridge][IDCapture] upload called")
    module.upload { isSuccess in
      result(isSuccess)
    }
  }
  
  /// Uploads the captured ID and returns both the result and the created documentId.
  /// Flutter receives: {"isSuccess": Bool, "documentId": String?}
  public func upload(result: @escaping FlutterResult, returnDocumentId: Bool) {
    guard returnDocumentId else { upload(result: result); return }
    AmaniLog.d("[AmaniBridge][IDCapture] upload with documentId called")
    module.upload { (isSuccess: Bool?, documentId: String?) in
      UploadResultPayload.send(isSuccess: isSuccess, documentId: documentId, module: "IDCapture", to: result)
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
    AmaniLog.d("[AmaniBridge][IDCapture] getMrz called")
  
    self.module.getMrz { mrzData in 
        AmaniLog.d("[AmaniBridge][IDCapture] getMrz completed")
            result(mrzData)
    }
    }
  }


