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
    let vc = UIApplication.shared.windows.last?.rootViewController
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
      module.setMainGuideImages(guideImages: [
        .mainGuideUp: UIImage(named: mainGuideUp)!,
        .mainGuideDown: UIImage(named: mainGuideDown)!,
        .mainGuideLeft: UIImage(named: mainGuideLeft)!,
        .mainGuideRight: UIImage(named: mainGuideRight)!,
        .mainGuideStraight: UIImage(named: mainGuideStraight)!,
      ])
    }
    
    if
    let secondaryGuideUp = settings.secondaryGuideUp,
    let secondaryGuideDown = settings.secondaryGuideDown,
    let secondaryGuideLeft = settings.secondaryGuideLeft,
    let secondaryGuideRight = settings.secondaryGuideRight
    {
      module.setSecondaryGuideImages(guideImages: [
        .secondaryGuideUp: UIImage(named: secondaryGuideUp)!,
        .secondaryGuideDown: UIImage(named: secondaryGuideDown)!,
        .secondaryGuideLeft: UIImage(named: secondaryGuideLeft)!,
        .secondaryGuideRight: UIImage(named: secondaryGuideRight)!,
      ])
    }

    module.setManualCropTimeout(timeout: settings.manualCropTimeout)

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
    poseEstimation.upload { isSuccess in
      result(isSuccess)
    }
  }

  /// Uploads the pose estimation images and returns {"isSuccess": Bool, "documentId": String?}.
  public func uploadWithDocumentId(result: @escaping FlutterResult) {
    poseEstimation.upload { (isSuccess: Bool?, documentId: String?) in
      UploadResultPayload.send(isSuccess: isSuccess, documentId: documentId, module: "PoseEstimation", to: result)
    }
  }
  
  public func setVideoRecording(enabled: Bool, result: @escaping FlutterResult) {
    module.setVideoRecording(enabled: enabled)
    result(nil)
  }
}
