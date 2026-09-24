import AmaniSDK
import Flutter
import UIKit

class SpeechVerifier {
  private var module: AmaniSDK.SpeechVerifier?
  private var sdkView: SDKView!

  public func start(settingsJSON: String, result: @escaping FlutterResult) {
    guard #available(iOS 13, *) else {
      result(FlutterError(
        code: "30008",
        message: "Speech Verifier requires iOS 13 or newer",
        details: nil
      ))
      return
    }

    guard let data = settingsJSON.data(using: .utf8) else {
      result(FlutterError(
        code: "30030",
        message: "Invalid speech verifier settings payload",
        details: nil
      ))
      return
    }

    let decoder = JSONDecoder()
    let settings: SpeechVerifierFlutterSettings
    do {
      settings = try decoder.decode(SpeechVerifierFlutterSettings.self, from: data)
    } catch let err {
      result(FlutterError(
        code: "30031",
        message: "Failed to decode speech verifier settings: \(err.localizedDescription)",
        details: nil
      ))
      return
    }

    let vc = UIApplication.shared.windows.last?.rootViewController

    // Build the Core SDK verifier from the decoded settings.
    let verifier = Amani.sharedInstance.speechVerifier()
      .documentType(settings.type)
      .setVideoRecording(enabled: settings.videoRecording)
      .setTimeout(seconds: settings.timeoutSeconds)

    // Steps (spokenText + identityQuestion), preserving order.
    let stepConfigurations = settings.steps.compactMap { $0.toCoreConfiguration() }
    verifier.verificationSteps(stepConfigurations)

    // Manual identity answers (optional).
    if let answers = settings.identityAnswers {
      verifier.identityAnswers(
        idNumber: answers.idNumber,
        motherName: answers.motherName,
        fatherName: answers.fatherName,
        documentNumber: answers.documentNumber
      )
    }

    // Appearance (optional).
    if let appearance = settings.appearance?.toCoreAppearance() {
      verifier.setAppearance(appearance)
    }

    var didReturn = false

  verifier
   .onSuccess { [weak self] success in
    print("SV bridge onSuccess fired, success =", success)
    guard success == true, !didReturn else {
      print("SV bridge onSuccess skipped — success:\(success) didReturn:\(didReturn)")
      return
    }
    didReturn = true
    print("SV bridge returning result to Flutter")
    result(FlutterStandardTypedData(bytes: Data()))
    DispatchQueue.main.async {
      self?.sdkView?.removeFromSuperview()
    }
  }
      .onFailure { reason, currentAttempt in
        print("Speech Verifier failure:", reason.rawValue, "attempt:", currentAttempt)
        // Failures are surfaced via the delegate/onError channel; we keep
        // the view up so the user can retry, matching the native example.
      }

    print("SV verifier instance after handlers:", ObjectIdentifier(verifier))
    self.module = verifier


    do {
      print("SV about to call start on:", ObjectIdentifier(verifier))
      guard let moduleView = try verifier.start() else {
        result(FlutterError(
          code: "30032",
          message: "Speech Verifier could not create its capture view.",
          details: nil
        ))
        return
      }

      sdkView = SDKView(sdkView: moduleView)
      sdkView.start(on: vc!)
      sdkView.setupBackButton(on: moduleView)
    } catch let err {
      result(FlutterError(code: "30007", message: err.localizedDescription, details: nil))
    }
  }

  public func upload(result: @escaping FlutterResult) {
    guard let module = module else {
      result(false)
      return
    }
    module.upload(location: nil) { isSuccess in
      result(isSuccess ?? false)
    }
  }

  /// Uploads the speech verification and returns {"isSuccess": Bool, "documentId": String?}.
  public func uploadWithDocumentId(result: @escaping FlutterResult) {
    guard let module = module else {
      UploadResultPayload.send(isSuccess: false, documentId: nil, module: "SpeechVerifier", to: result)
      return
    }
    module.upload(location: nil) { (isSuccess: Bool?, documentId: String?) in
      UploadResultPayload.send(isSuccess: isSuccess, documentId: documentId, module: "SpeechVerifier", to: result)
    }
  }
}

// MARK: - Flutter-side settings decoding

private struct SpeechVerifierFlutterSettings: Decodable {
  let type: String
  let videoRecording: Bool
  let timeoutSeconds: Int
  let steps: [Step]
  let identityAnswers: IdentityAnswers?
  let appearance: Appearance?

  struct TextItem: Decodable {
    let text: String
    let matchThresholdPercent: Int
  }

  struct QuestionItem: Decodable {
    let type: String
    let matchThresholdPercent: Int
  }

  struct Step: Decodable {
    let type: String                 // "spokenText" | "identityQuestion"
    let textItems: [TextItem]?
    let questionItems: [QuestionItem]?

    private enum CodingKeys: String, CodingKey {
      case type, items
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      type = try container.decode(String.self, forKey: .type)

      switch type {
      case "spokenText":
        textItems = try container.decode([TextItem].self, forKey: .items)
        questionItems = nil
      case "identityQuestion":
        questionItems = try container.decode([QuestionItem].self, forKey: .items)
        textItems = nil
      default:
        textItems = nil
        questionItems = nil
      }
    }

    @available(iOS 13, *)
    func toCoreConfiguration() -> SpeechVerifierStepConfiguration? {
      switch type {
      case "spokenText":
        let configs = (textItems ?? []).map {
          SpeechVerifierTextConfiguration(
            text: $0.text,
            matchThresholdPercent: $0.matchThresholdPercent
          )
        }
        guard !configs.isEmpty else { return nil }
        return .spokenText(configs)

      case "identityQuestion":
        let configs = (questionItems ?? []).compactMap { item -> SpeechVerifierIdentityQuestionConfiguration? in
          guard let qType = SpeechVerifier.mapQuestionType(item.type) else { return nil }
          return SpeechVerifierIdentityQuestionConfiguration(
            type: qType,
            matchThresholdPercent: item.matchThresholdPercent
          )
        }
        guard !configs.isEmpty else { return nil }
        return .identityQuestion(configs)

      default:
        return nil
      }
    }
  }

  struct IdentityAnswers: Decodable {
    let idNumber: String?
    let motherName: String?
    let fatherName: String?
    let documentNumber: String?
  }

  struct Appearance: Decodable {
    let highlightedTextColor: String?

    @available(iOS 13, *)
    func toCoreAppearance() -> SpeechVerifierAppearance {
      SpeechVerifierAppearance(
        highlightedTextColor: UIColor(hex: highlightedTextColor) ?? .systemGreen
      )
    }
  }
}

@available(iOS 13, *)
private extension SpeechVerifier {
  static func mapQuestionType(_ raw: String) -> SpeechVerifierIdentityQuestionType? {
    switch raw {
    case "idNumber":       return .idNumber
    case "motherName":     return .motherName
    case "fatherName":     return .fatherName
    case "documentNumber": return .documentNumber
    default:               return nil
    }
  }
}

// MARK: - Hex color helper

private extension UIColor {
  convenience init?(hex: String?) {
    guard var hex = hex else { return nil }
    hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if hex.hasPrefix("#") { hex.removeFirst() }
    guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return nil }
    self.init(
      red: CGFloat((value & 0xFF0000) >> 16) / 255.0,
      green: CGFloat((value & 0x00FF00) >> 8) / 255.0,
      blue: CGFloat(value & 0x0000FF) / 255.0,
      alpha: 1.0
    )
  }
}