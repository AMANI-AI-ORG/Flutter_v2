//
//  PoseEstimation.swift
//  flutter_amanisdk_v2
//
//  Created by Deniz Can on 14.11.2022.
//

import AmaniSDK
import Flutter
import UIKit

class PoseEstimation {
  private let poseEstimation = Amani.sharedInstance.poseEstimation()
  private lazy var module = poseEstimation.v1
  private var sdkView: SDKView!

  public func start(settings: PoseEstimationSettings, result: @escaping FlutterResult) {
    guard let vc = BridgeSecurity.topViewController() else {
      result(FlutterError(code: "30007", message: "No active view controller to present the capture UI", details: nil))
      return
    }
    module.setScreenConfig(screenConfig: [
      .appBackgroundColor: settings.appBackgroundColor,
      .appFontColor: settings.appFontColor,
      .primaryButtonBackgroundColor: settings.primaryButtonBackgroundColor,
      .primaryButtonTextColor: settings.primaryButtonTextColor,
      .ovalBorderColor: settings.ovalBorderColor,
      .ovalBorderSuccessColor: settings.ovalBorderSuccessColor,
      .poseCount: settings.poseCount,
      .mainGuideVisibility: settings.mainGuideVisibility,
      .secondaryGuideVisibility: settings.secondaryGuideVisibility,
    ])

    module.setInfoMessages(infoMessages: [
      .faceIsOk: settings.faceIsOk,
      .notInArea: settings.notInArea,
      .faceTooSmall: settings.faceTooSmall,
      .faceTooBig: settings.faceTooBig,
      .completed: settings.completed,
      .turnRight: settings.turnRight,
      .turnLeft: settings.turnLeft,
      .turnUp: settings.turnUp,
      .turnDown: settings.turnDown,
      .lookStraight: settings.lookStraight,
      .errorMessage: settings.errorMessage,
      .next: settings.next,
      .tryAgain: settings.tryAgain,
      .errorTitle: settings.errorTitle,
      .holdPhoneVertically: settings.holdPhoneVertically,
      .informationScreenDesc1: settings.informationScreenDesc1,
      .informationScreenDesc2: settings.informationScreenDesc2,
      .informationScreenTitle: settings.informationScreenTitle,
      .wrongPose: settings.wrongPose,
      .descriptionHeader: settings.descriptionHeader,
    ])

    if
    let mainGuideUp = settings.mainGuideUp,
    let mainGuideDown = settings.mainGuideDown,
    let mainGuideLeft = settings.mainGuideLeft,
    let mainGuideRight = settings.mainGuideRight,
    let mainGuideStraight = settings.mainGuideStraight {
      // Asset names come from Dart; a missing asset must not crash the host app.
      if let up = UIImage(named: mainGuideUp), let down = UIImage(named: mainGuideDown),
         let left = UIImage(named: mainGuideLeft), let right = UIImage(named: mainGuideRight),
         let straight = UIImage(named: mainGuideStraight) {
        module.setMainGuideImages(guideImages: [
          .mainGuideUp: up,
          .mainGuideDown: down,
          .mainGuideLeft: left,
          .mainGuideRight: right,
          .mainGuideStraight: straight,
        ])
      }
    }
    
    if
    let secondaryGuideUp = settings.secondaryGuideUp,
    let secondaryGuideDown = settings.secondaryGuideDown,
    let secondaryGuideLeft = settings.secondaryGuideLeft,
    let secondaryGuideRight = settings.secondaryGuideRight
    {
      if let up = UIImage(named: secondaryGuideUp), let down = UIImage(named: secondaryGuideDown),
         let left = UIImage(named: secondaryGuideLeft), let right = UIImage(named: secondaryGuideRight) {
        module.setSecondaryGuideImages(guideImages: [
          .secondaryGuideUp: up,
          .secondaryGuideDown: down,
          .secondaryGuideLeft: left,
          .secondaryGuideRight: right,
        ])
      }
    }

    module.setManualCropTimeout(timeout: settings.manualCropTimeout)

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
    poseEstimation.upload { isSuccess in
      result(isSuccess)
    }
  }

  /// Uploads the pose estimation images and returns {"isSuccess": Bool, "documentId": String?}.
  public func upload(result: @escaping FlutterResult, returnDocumentId: Bool) {
    guard returnDocumentId else { upload(result: result); return }
    poseEstimation.upload { (isSuccess: Bool?, documentId: String?) in
      UploadResultPayload.send(isSuccess: isSuccess, documentId: documentId, module: "PoseEstimation", to: result)
    }
  }
  
  public func setVideoRecording(enabled: Bool, result: @escaping FlutterResult) {
    module.setVideoRecording(enabled: enabled)
    result(nil)
  }
}
