import AmaniSDK
import Flutter

public class SwiftFlutterAmanisdkPlugin: NSObject, FlutterPlugin {
  var methodChannel: FlutterMethodChannel!
  var delegateChannel: FlutterEventChannel!
  private var speechVerifierInstance: SpeechVerifier?
  private var signatureInstance: SignatureCapture?
  static var eventHandler = DelegateEventHandler()
  /// Token session of the last initAmani call, reused by the standalone Speech Verifier SDK.
  static var sessionServerURL: String?
  static var sessionToken: String?
 
  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(name: "amanisdk_method_channel", binaryMessenger: registrar.messenger())
    let delegateChannel = FlutterEventChannel(name: "amanisdk_delegate_channel", binaryMessenger: registrar.messenger())
    
    let instance = SwiftFlutterAmanisdkPlugin()
    instance.methodChannel = methodChannel
    instance.delegateChannel = delegateChannel
    instance.delegateChannel.setStreamHandler(SwiftFlutterAmanisdkPlugin.eventHandler)
    
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any]
    // Upload calls return {"isSuccess", "documentId"} instead of a Bool when this is true.
    let returnDocumentId = arguments?["returnDocumentId"] as? Bool ?? false
    switch call.method {
    case "initAmani":
      // Optional: nil means "not set", but a provided value must not be empty or blank.
      let sharedSecret = arguments?["sharedSecret"] as? String
      if let secret = sharedSecret, secret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        result(FlutterError(code: "30009", message: "sharedSecret must not be empty when provided", details: nil))
        return
      }
      guard let server = BridgeSecurity.validatedServer(arguments?["server"] as? String) else {
        result(BridgeSecurity.invalidArgument("server must be a valid https URL"))
        return
      }
      guard let customerIdCardNumber = arguments?["customerIdCardNumber"] as? String, !customerIdCardNumber.isEmpty,
            let customerToken = arguments?["customerToken"] as? String, !customerToken.isEmpty,
            let lang = arguments?["lang"] as? String else {
        result(BridgeSecurity.invalidArgument("customerIdCardNumber, customerToken and lang are required"))
        return
      }
      let useLocation = arguments?["useLocation"] as? Bool ?? false
      let apiVersion = arguments?["apiVersion"] as? String ?? "v2"
      let uploadSource = arguments?["uploadSource"] as? String ?? "KYC"
      initAmani(server: server, customerIdCardNumber: customerIdCardNumber, customerToken: customerToken, useLocation: useLocation, lang: lang , sharedSecret: sharedSecret, version: apiVersion, uploadSource: uploadSource, result: result)
    case "initAmaniWithEmail":
      // Optional: nil means "not set", but a provided value must not be empty or blank.
      let sharedSecret = arguments?["sharedSecret"] as? String
      if let secret = sharedSecret, secret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        result(FlutterError(code: "30009", message: "sharedSecret must not be empty when provided", details: nil))
        return
      }
      guard let server = BridgeSecurity.validatedServer(arguments?["server"] as? String) else {
        result(BridgeSecurity.invalidArgument("server must be a valid https URL"))
        return
      }
      guard let customerIdCardNumber = arguments?["customerIdCardNumber"] as? String, !customerIdCardNumber.isEmpty,
            let email = arguments?["email"] as? String, !email.isEmpty,
            let password = arguments?["password"] as? String, !password.isEmpty,
            let lang = arguments?["lang"] as? String else {
        result(BridgeSecurity.invalidArgument("customerIdCardNumber, email, password and lang are required"))
        return
      }
      let useLocation = arguments?["useLocation"] as? Bool ?? false
      let apiVersion = arguments?["apiVersion"] as? String ?? "v2"
      let uploadSource = arguments?["uploadSource"] as? String ?? "KYC"
      initAmaniWithEmail(server: server, customerIdCardNumber: customerIdCardNumber, email: email, password: password, useLocation: useLocation, lang: lang, sharedSecret: sharedSecret, version: apiVersion, uploadSource: uploadSource, result: result)
    case "setUploadSource":
      guard let uploadSource = arguments?["uploadSource"] as? String,
            let source = UploadSource(rawValue: uploadSource) else {
        result(FlutterError(code: "30009", message: "Invalid uploadSource", details: nil))
        return
      }
      Amani.sharedInstance.setUploadSource(uploadSource: source)
      result(nil)
    case "setUploadSourceString":
      guard let uploadSource = arguments?["uploadSource"] as? String, !uploadSource.isEmpty else {
        result(FlutterError(code: "30009", message: "uploadSource must not be empty", details: nil))
        return
      }
      Amani.sharedInstance.setUploadSource(uploadSource: uploadSource)
      result(nil)
    // ID Capture
    case "setIDCaptureType":
      let idCapture = IdCapture()
      guard let type = arguments?["type"] as? String, !type.isEmpty else {
        result(BridgeSecurity.invalidArgument("type is required"))
        return
      }
      idCapture.setType(type: type, result: result)
    case "startIDCapture":
      let idCapture = IdCapture()
      let stepID = arguments?["stepID"] as? Int
      idCapture.start(stepID: stepID ?? 0, result: result)
    case "setIDCaptureManualButtonTimeout":
      let idCapture = IdCapture()
      guard let timeout = arguments?["timeout"] as? Int else {
        result(BridgeSecurity.invalidArgument("timeout is required"))
        return
      }
      idCapture.setManualCaptureButtonTimeout(timeout: timeout, result: result)
    case "iosIDCaptureNFC":
    
        if let arguments = call.arguments as? [String: Any], 
           let birthDate = arguments["birthDate"] as? String,
           let expireDate = arguments["expireDate"] as? String,
           let documentNo = arguments["documentNo"] as? String,
           !birthDate.isEmpty, !expireDate.isEmpty, !documentNo.isEmpty {
            AmaniLog.d("[AmaniBridge][IDCapture] Starting NFC scan")
            
            let idCapture = IdCapture()
            Task {
                let nviModel = NviModel(documentNo: documentNo, dateOfBirth: birthDate, dateOfExpire: expireDate)
                let isDone = await idCapture.startNFC(nvi: nviModel)
                
                result(isDone)
            }
        } else {
            result(FlutterError(code: "30009", message: "Invalid arguments", details: nil))
        }

            
    case "setIDCaptureVideoRecordingEnabled":
      let idCapture = IdCapture()
      let enabled = arguments?["enabled"] as? Bool
      idCapture.setVideoRecording(enabled: enabled ?? true, result: result)
   case "setIDCaptureHologramDetection":
      let idCapture = IdCapture()
      let enabled = arguments?["enabled"] as? Bool
      // defaults to false as this feature only supported for TUR_ID
      idCapture.setHologramDetection(enabled: enabled ?? false, result: result)
    case "uploadIDCapture":
      let idCapture = IdCapture()
      idCapture.upload(result: result, returnDocumentId: returnDocumentId)
      // get Mrz Data
    case "getMrz":
    let idCapture = IdCapture()
     idCapture.getMrz(result: result)
    // Selfie
    case "setSelfieType":
      let selfie = Selfie()
      guard let type = arguments?["type"] as? String, !type.isEmpty else {
        result(BridgeSecurity.invalidArgument("type is required"))
        return
      }
      selfie.setType(type: type, result: result)
    case "startSelfie":
      let selfie = Selfie()
      selfie.start(result: result)
    case "uploadSelfie":
      let selfie = Selfie()
      selfie.upload(result: result, returnDocumentId: returnDocumentId)
    // AutoSelfie
    case "startAutoSelfie":
      let autoSelfie = AutoSelfie()
      guard let iosArgs = arguments?["iosSettings"] as? String,
            let autoSelfieSettings = try? JSONDecoder().decode(AutoSelfieSettings.self, from: Data(iosArgs.utf8)) else {
        result(BridgeSecurity.invalidArgument("Invalid iosSettings for auto selfie"))
        return
      }
      autoSelfie.start(settings: autoSelfieSettings, result: result)
    case "setAutoSelfieType":
      let autoSelfie = AutoSelfie()
      guard let type = arguments?["type"] as? String, !type.isEmpty else {
        result(BridgeSecurity.invalidArgument("type is required"))
        return
      }
      autoSelfie.setType(type: type, result: result)
    case "uploadAutoSelfie":
      let autoSelfie = AutoSelfie()
      autoSelfie.upload(result: result, returnDocumentId: returnDocumentId)
    // Pose Estimation
    case "startPoseEstimation":
      let poseEstimation = PoseEstimation()
      guard let iosArgs = arguments?["iosSettings"] as? String,
            let poseEstimationSettings = try? JSONDecoder().decode(PoseEstimationSettings.self, from: Data(iosArgs.utf8)) else {
        result(BridgeSecurity.invalidArgument("Invalid iosSettings for pose estimation"))
        return
      }
      poseEstimation.start(settings: poseEstimationSettings, result: result)
    case "setPoseEstimationType":
        let poseEstimation = PoseEstimation()
        guard let type = arguments?["type"] as? String, !type.isEmpty else {
          result(BridgeSecurity.invalidArgument("type is required"))
          return
        }
        poseEstimation.setType(type: type, result: result)
    case "setPoseEstimationVideoRecording":
      let poseEstimation = PoseEstimation()
      let enabled = arguments?["enabled"] as? Bool
      poseEstimation.setVideoRecording(enabled: enabled ?? true, result: result)
    case "uploadPoseEstimation":
        let poseEstimation = PoseEstimation()
        poseEstimation.upload(result: result, returnDocumentId: returnDocumentId)

    // Speech Verifier
    case "startSpeechVerifier":
      let speechVerifier = SpeechVerifier()
      // Keep the instance alive: the upload call needs the verifier built in start.
      self.speechVerifierInstance = speechVerifier
      guard let iosArgs = arguments?["iosSettings"] as? String else {
        result(BridgeSecurity.invalidArgument("iosSettings is required"))
        return
      }
      speechVerifier.start(settingsJSON: iosArgs, result: result)
    case "uploadSpeechVerifier":
        guard let speechVerifier = speechVerifierInstance else {
          if returnDocumentId {
            UploadResultPayload.send(isSuccess: false, documentId: nil, module: "SpeechVerifier", to: result)
          } else {
            result(false)
          }
          return
        }
        speechVerifier.upload(result: { [weak self] value in
          result(value)
          self?.speechVerifierInstance = nil
        }, returnDocumentId: returnDocumentId)
    // Signature
    case "startSignature":
      let signature = SignatureCapture()
      self.signatureInstance = signature
      signature.start(arguments: arguments, result: result)
    case "uploadSignature":
      let signature = signatureInstance ?? SignatureCapture()
      signature.upload(result: result, returnDocumentId: returnDocumentId)
    // NFC
    case "iOSstartNFCWithNviModel":
        Task {
            do {
                let nfc = NFC()
                guard let nviModel = Self.nviModel(from: arguments) else {
                    result(FlutterError(code: "400", message: "Invalid arguments", details: nil))
                    return
                }
                try await nfc.start(nviData: nviModel, result: result)
            } catch {
                result(FlutterError(code: "500", message: "Internal error", details: nil))
            }
        }
    case "iOSstartNFCWithMRZCapture":
            if #available(iOS 13, *) {
        Task {
            do {
                let nfc = NFC()
                guard let nviModel = Self.nviModel(from: arguments) else {
                    result(FlutterError(code: "400", message: "Invalid arguments", details: nil))
                    return
                }
                try await nfc.start(nviData: nviModel, result: result)  
                
            } catch let err {
                result(FlutterError(code: "30007", message: err.localizedDescription, details: nil))
            }
        }
    } else {
        result(FlutterError(code: "30008", message: "NFC Requires iOS 13 or newer", details: nil))
    }
    case "iOSsetNFCType":
        let nfc = NFC()
        guard let type = arguments?["type"] as? String, !type.isEmpty else {
          result(BridgeSecurity.invalidArgument("type is required"))
          return
        }
        nfc.setType(type: type, result: result)
    case "iOSuploadNFC":
        let nfc = NFC()
        nfc.upload(result: result, returnDocumentId: returnDocumentId)
    // BioLogin
    case "initBioLogin":
      guard let server = BridgeSecurity.validatedServer(arguments?["server"] as? String),
            let token = arguments?["token"] as? String, !token.isEmpty else {
        result(FlutterError(code: "30009", message: "a valid https server and token are required", details: nil))
        return
      }
      // Optional: nil means "not set", but a provided value must not be empty or blank.
      if let sharedSecret = arguments?["sharedSecret"] as? String,
         sharedSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        result(FlutterError(code: "30009", message: "sharedSecret must not be empty when provided", details: nil))
        return
      }
      BioLoginCapture.shared.initBioLogin(
        server: server,
        token: token,
        source: arguments?["source"] as? Int,
        comparisonAdapter: arguments?["comparisonAdapter"] as? Int,
        result: result)
    case "startBioLoginWithAutoSelfie":
      guard let iosArgs = arguments?["iosSettings"] as? String,
            let settings = try? JSONDecoder().decode(AutoSelfieSettings.self, from: Data(iosArgs.utf8)) else {
        result(FlutterError(code: "30009", message: "Invalid iosSettings for BioLogin auto selfie", details: nil))
        return
      }
      BioLoginCapture.shared.startWithAutoSelfie(settings: settings, result: result)
    case "iOSStartBioLoginWithPoseEstimation":
      guard let iosArgs = arguments?["iosSettings"] as? String,
            let settings = try? JSONDecoder().decode(PoseEstimationSettings.self, from: Data(iosArgs.utf8)) else {
        result(FlutterError(code: "30009", message: "Invalid iosSettings for BioLogin pose estimation", details: nil))
        return
      }
      BioLoginCapture.shared.startWithPoseEstimation(settings: settings, result: result)
    case "startBioLoginWithManualSelfie":
      BioLoginCapture.shared.startWithManualSelfie(result: result)
    case "uploadBioLogin":
      BioLoginCapture.shared.upload(result: result, returnDocumentId: returnDocumentId)
    case "getCustomerInfo":
        getCustomerInfo(result: result)
    // MARK: Document Capture
    case "startDocumentCapture":
      let documentCount = arguments?["documentCount"] as? Int ?? 1
      let documentCapture = DocumentCapture()
      documentCapture.start(documentCount: documentCount, result: result)
    case "setDocumentCaptureType":
      let documentCapture = DocumentCapture()
      guard let documentType = arguments?["type"] as? String, !documentType.isEmpty else {
        result(BridgeSecurity.invalidArgument("type is required"))
        return
      }
      documentCapture.setType(type: documentType, result: result)
    case "documentCaptureUpload":
      let documentCapture = DocumentCapture()
      documentCapture.upload(files: documentFiles(from: arguments), result: result, returnDocumentId: returnDocumentId)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Builds an NviModel from the "nviData" argument; nil when a field is missing or empty.
  private static func nviModel(from arguments: [String: Any]?) -> NviModel? {
    guard let nviData = arguments?["nviData"] as? [String: String],
          let documentNo = nviData["documentNo"], !documentNo.isEmpty,
          let dateOfBirth = nviData["dateOfBirth"], !dateOfBirth.isEmpty,
          let dateOfExpire = nviData["dateOfExpire"], !dateOfExpire.isEmpty else {
      return nil
    }
    return NviModel(documentNo: documentNo, dateOfBirth: dateOfBirth, dateOfExpire: dateOfExpire)
  }

  /// Maps the optional "files" argument (list of {data, dataType}) to Core SDK files.
  /// Returns nil when no files are given, so the captured document is uploaded instead.
  private func documentFiles(from arguments: [String: Any]?) -> [FileWithType]? {
    guard let files = arguments?["files"] as? [[String: Any]] else { return nil }
    let filesData: [FileWithType] = files.compactMap { mappedData in
      guard
        let fileData = mappedData["data"] as? FlutterStandardTypedData,
        let fileType = mappedData["dataType"] as? String
      else { return nil }
      return FileWithType(data: fileData.data, dataType: fileType)
    }
    return filesData.isEmpty ? nil : filesData
  }

  private func initAmani(server: String,
                         customerIdCardNumber: String,
                         customerToken: String,
                         useLocation: Bool,
                         lang: String,
                         sharedSecret: String?,
                         version: String = "v2",
                         uploadSource: String = "KYC",
                         result: @escaping FlutterResult) {
    let customer = CustomerRequestModel(name: nil, email: nil, phone: nil, idCardNumber: customerIdCardNumber)
    let apiVersion = version == "v2" ? ApiVersions.v2 : ApiVersions.v1
    
    SwiftFlutterAmanisdkPlugin.sessionServerURL = server
    SwiftFlutterAmanisdkPlugin.sessionToken = customerToken
    Amani.sharedInstance.setDelegate(delegate: SwiftFlutterAmanisdkPlugin.eventHandler)
    Amani.sharedInstance.setMRZDelegate(delegate: SwiftFlutterAmanisdkPlugin.eventHandler)
    Amani.sharedInstance.initAmani(server: server, token: customerToken, sharedSecret: sharedSecret, customer: customer, language: lang, uploadSource: uploadSource, apiVersion: apiVersion) { (customerRes, err) in
      if customerRes != nil {
        result(true)
      } else if let err = err {
        result(FlutterError(code: String(err.error_code), message: "Couldn't login to Amani server", details: err.error_message))
      } else {
        result(FlutterError(code: "30010", message: "Couldn't login to Amani server", details: nil))
      }
    }
  }
  private func initAmaniWithEmail(
                        server: String,
                        customerIdCardNumber: String,
                        email: String,
                        password: String,
                        useLocation: Bool,
                        lang: String,
                        sharedSecret: String?,
                        version: String = "v2",
                        uploadSource: String = "KYC",
                        result: @escaping FlutterResult) {
    let customer = CustomerRequestModel(name: nil, email: nil, phone: nil, idCardNumber: customerIdCardNumber)
    let apiVersion: ApiVersions = version == "v2" ? .v2 : .v1
    Amani.sharedInstance.setDelegate(delegate: SwiftFlutterAmanisdkPlugin.eventHandler)
    Amani.sharedInstance.setMRZDelegate(delegate: SwiftFlutterAmanisdkPlugin.eventHandler)
    Amani.sharedInstance.initAmani(server: server, userName: email, password: password, sharedSecret: sharedSecret, customer: customer, language: lang, uploadSource: uploadSource, apiVersion: apiVersion) { customerRes, err in
      if customerRes != nil {
        result(true)
      } else if let err = err {
        result(FlutterError(code: String(err.error_code), message: "Couldn't login to Amani server", details: err.error_message))
      } else {
        result(FlutterError(code: "30010", message: "Couldn't login to Amani server", details: nil))
      }
    }
  }
    private func getCustomerInfo(result: @escaping FlutterResult) {
        // Use the customer data cached by the SDK instead of getCustomer(forceUpdateCallback:).
        // The forced fetch runs on CustomerInfo's own service instance, and a successful
        // getCustomer makes that instance the SSE listener (ServiceManager.shared.delegate).
        // That instance has no AmaniServiceDelegate, so mrz_result / step_results events
        // stop reaching Amani and mrzInfoDelegate never fires. initAmani already caches a
        // fresh customer, and step_results SSE events keep its rule statuses up to date.
        let customerInfo = Amani.sharedInstance.customerInfo().getCustomer()
        var rulesArray: [[String: Any]] = []
        if let rules = customerInfo.rules {
            for rule in rules {
                rulesArray.append(["id": rule.id as Any, "title": rule.title as Any, "documentClasses": rule.documentClasses as Any, "status": rule.status as Any])
            }
        }
        
        var missingRulesArray: [[String: Any]] = []
        if let missingRules = customerInfo.missingRules {
            for rule in missingRules {
                missingRulesArray.append(["id": rule.id as Any, "title": rule.title as Any, "documentClasses": rule.documentClasses as Any, "status": rule.status as Any])
            }
        }
        
        let customerInfoDict: [String: Any] = [
            "id": customerInfo.id as Any,
            "name": customerInfo.name as Any,
            "email": customerInfo.email as Any,
            "phone": customerInfo.phone as Any,
            "companyID": customerInfo.companyID as Any,
            "status": customerInfo.status as Any,
            "occupation": customerInfo.occupation as Any,
            "city": customerInfo.address?.city as Any,
            "address": customerInfo.address?.address as Any,
            "province": customerInfo.address?.province as Any,
            "rules": rulesArray,
            "missingRules": missingRulesArray,
        ]
        
        result(customerInfoDict)
  }
  
}
