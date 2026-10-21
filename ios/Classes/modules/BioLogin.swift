//
//  BioLogin.swift
//  flutter_amanisdk
//

import AmaniSDK
import Flutter
import UIKit

/// Flutter bridge for the Core SDK's BioLogin module, built on `BioLoginBuilder`.
///
/// `initBioLogin` stores the session values; each `startWith...` call builds a
/// BioLogin module of the matching type and presents its capture view.
class BioLoginCapture {
  static let shared = BioLoginCapture()

  private var server: String?
  private var token: String?
  private var source = 3
  private var comparisonAdapter = 2

  private var module: AmaniSDK.BioLogin?
  private var sdkView: SDKView?

  private init() {}

  func initBioLogin(
    server: String,
    token: String,
    source: Int?,
    comparisonAdapter: Int?,
    result: @escaping FlutterResult
  ) {
    self.server = server
    self.token = token
    self.source = source ?? 3
    self.comparisonAdapter = comparisonAdapter ?? 2
    result(nil)
  }

  // MARK: - Start

  func startWithAutoSelfie(settings: AutoSelfieSettings, result: @escaping FlutterResult) {
    guard let builder = makeBuilder(type: .autoSelfie, result: result) else { return }
    builder
      .setSelfieMessages(key: .faceIsOk, value: settings.faceIsOk)
      .setSelfieMessages(key: .notInArea, value: settings.notInArea)
      .setSelfieMessages(key: .faceTooSmall, value: settings.faceTooSmall)
      .setSelfieMessages(key: .faceTooBig, value: settings.faceTooBig)
      .setSelfieMessages(key: .completed, value: settings.completed)
      .setSelfieColor(key: .appBackgroundColor, value: settings.appBackgroundColor)
      .setSelfieColor(key: .appFontColor, value: settings.appFontColor)
      .setSelfieColor(key: .primaryButtonBackgroundColor, value: settings.primaryButtonBackgroundColor)
      .setSelfieColor(key: .ovalBorderSuccessColor, value: settings.ovalBorderSuccessColor)
      .setSelfieColor(key: .ovalBorderColor, value: settings.ovalBorderColor)
      .setSelfieColor(key: .countTimer, value: settings.countTimer)
    startModule(builder: builder, result: result)
  }

  func startWithPoseEstimation(settings: PoseEstimationSettings, result: @escaping FlutterResult) {
    guard let builder = makeBuilder(type: .poseEstimation, result: result) else { return }
    builder
      .setPoseEstimationColors(screenConfig: [
        .appBackgroundColor: settings.appBackgroundColor,
        .appFontColor: settings.appFontColor,
        .primaryButtonBackgroundColor: settings.primaryButtonBackgroundColor,
        .primaryButtonTextColor: settings.primaryButtonTextColor,
        .ovalBorderColor: settings.ovalBorderColor,
        .ovalBorderSuccessColor: settings.ovalBorderSuccessColor,
        .poseCount: settings.poseCount,
        .mainGuideVisibility: settings.mainGuideVisibility,
        .secondaryGuideVisibility: settings.secondaryGuideVisibility,
        .buttonRadius: settings.buttonRadious,
      ])
      .setPoseEstimationMessages(infoMessages: [
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
        .tryAgain: settings.tryAgain,
        .errorTitle: settings.errorTitle,
        .confirm: settings.confirm,
        .next: settings.next,
        .holdPhoneVertically: settings.holdPhoneVertically,
        .informationScreenDesc1: settings.informationScreenDesc1,
        .informationScreenDesc2: settings.informationScreenDesc2,
        .informationScreenTitle: settings.informationScreenTitle,
        .wrongPose: settings.wrongPose,
        .descriptionHeader: settings.descriptionHeader,
      ])

    // Guide images are optional; the SDK uses its own defaults when they are not given.
    if let up = image(settings.mainGuideUp), let down = image(settings.mainGuideDown),
       let left = image(settings.mainGuideLeft), let right = image(settings.mainGuideRight),
       let straight = image(settings.mainGuideStraight) {
      builder.setPoseEstimationMainGuideImages(guideImages: [
        .mainGuideUp: up, .mainGuideDown: down, .mainGuideLeft: left,
        .mainGuideRight: right, .mainGuideStraight: straight,
      ])
    }
    if let up = image(settings.secondaryGuideUp), let down = image(settings.secondaryGuideDown),
       let left = image(settings.secondaryGuideLeft), let right = image(settings.secondaryGuideRight) {
      builder.setPoseEstimationSecondaryImages(guideImages: [
        .secondaryGuideUp: up, .secondaryGuideDown: down,
        .secondaryGuideLeft: left, .secondaryGuideRight: right,
      ])
    }
    startModule(builder: builder, result: result)
  }

  func startWithManualSelfie(result: @escaping FlutterResult) {
    guard let builder = makeBuilder(type: .manualSelfie, result: result) else { return }
    startModule(builder: builder, result: result)
  }

  // MARK: - Upload

  func upload(result: @escaping FlutterResult) {
    guard let module = module else {
      result(FlutterError(code: "30040", message: "Start a BioLogin capture before uploading.", details: nil))
      return
    }
    module.upload { (isSuccess: Bool?) in
      DispatchQueue.main.async {
        result(isSuccess ?? false)
      }
    }
  }

  /// Uploads the BioLogin selfie and returns {"isSuccess": Bool, "documentId": String?}.
  func upload(result: @escaping FlutterResult, returnDocumentId: Bool) {
    guard returnDocumentId else { upload(result: result); return }
    guard let module = module else {
      result(FlutterError(code: "30040", message: "Start a BioLogin capture before uploading.", details: nil))
      return
    }
    module.upload { (isSuccess: Bool?, documentId: String?) in
      UploadResultPayload.send(isSuccess: isSuccess, documentId: documentId, module: "BioLogin", to: result)
    }
  }

  // MARK: - Helpers

  /// Returns a builder with the session values set, or replies with an error
  /// when `initBioLogin` was not called. The type is set first, because the
  /// builder ignores selfie / pose settings that do not match its type.
  private func makeBuilder(type: BioLoginType, result: @escaping FlutterResult) -> BioLoginBuilder? {
    guard let server = server, let token = token, !server.isEmpty, !token.isEmpty else {
      result(FlutterError(code: "30041", message: "Call initBioLogin before starting a BioLogin capture.", details: nil))
      return nil
    }
    return BioLoginBuilder()
      .setBioLoginType(type: type)
      .setUrl(url: server)
      .setToken(token: token)
      .setSource(source: source)
      .setComparisonAdaptere(comparison_adapter: comparisonAdapter)
  }

  private func startModule(builder: BioLoginBuilder, result: @escaping FlutterResult) {
    guard let module = builder.build() else {
      result(FlutterError(code: "30042", message: "BioLogin could not be built. Check the server URL and token.", details: nil))
      return
    }
    self.module = module

    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      guard let vc = UIApplication.shared.windows.last?.rootViewController else {
        result(FlutterError(code: "30050", message: "Could not find a view controller to present BioLogin.", details: nil))
        return
      }
      do {
        guard let moduleView = try module.start(completion: { [weak self] image in
          if let data = image.pngData() {
            result(FlutterStandardTypedData(bytes: data))
          } else {
            result(FlutterError(code: "30043", message: "Could not encode the BioLogin image.", details: nil))
          }
          DispatchQueue.main.async {
            self?.sdkView?.removeFromSuperview()
            self?.sdkView = nil
          }
        }) else {
          result(FlutterError(code: "30044", message: "BioLogin could not create its capture view.", details: nil))
          return
        }
        let sdkView = SDKView(sdkView: moduleView)
        sdkView.start(on: vc)
        sdkView.setupBackButton(on: moduleView)
        self.sdkView = sdkView
      } catch let err {
        result(FlutterError(code: "30007", message: err.localizedDescription, details: nil))
      }
    }
  }

  private func image(_ name: String?) -> UIImage? {
    guard let name = name else { return nil }
    return UIImage(named: name)
  }
}
