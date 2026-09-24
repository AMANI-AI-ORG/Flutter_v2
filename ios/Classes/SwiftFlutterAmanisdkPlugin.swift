import AmaniSDK
import Flutter

public class SwiftFlutterAmanisdkPlugin: NSObject, FlutterPlugin {
  var methodChannel: FlutterMethodChannel!
  var delegateChannel: FlutterEventChannel!
  private var speechVerifierInstance: SpeechVerifier?
  private var signatureInstance: SignatureCapture?
  static var eventHandler = DelegateEventHandler()
 
  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(name: "amanisdk_method_channel", binaryMessenger: registrar.messenger())
    let delegateChannel = FlutterEventChannel(name: "amanisdk_delegate_channel", binaryMessenger: registrar.messenger())
    
    let instance = SwiftFlutterAmanisdkPlugin()
    instance.methodChannel = methodChannel
    instance.methodChannel = methodChannel
    instance.delegateChannel = delegateChannel
    instance.delegateChannel.setStreamHandler(SwiftFlutterAmanisdkPlugin.eventHandler)
    
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any]
    switch call.method {
    case "initAmani":
      let server = arguments?["server"] as! String
      let customerIdCardNumber = arguments?["customerIdCardNumber"] as! String
      let customerToken = arguments?["customerToken"] as! String
      let lang = arguments?["lang"] as! String
      let useLocation = arguments?["useLocation"] as! Bool
      let sharedSecret = arguments?["sharedSecret"] as? String
      let apiVersion = arguments?["apiVersion"] as? String ?? "v2"
      initAmani(server: server, customerIdCardNumber: customerIdCardNumber, customerToken: customerToken, useLocation: useLocation, lang: lang , sharedSecret: sharedSecret, version: apiVersion, result: result)
    case "initAmaniWithEmail":
      let server = arguments?["server"] as! String
      let customerIdCardNumber = arguments?["customerIdCardNumber"] as! String
      let email = arguments?["email"] as! String
      let password = arguments?["password"] as! String
      let lang = arguments?["lang"] as! String
      let useLocation = arguments?["useLocation"] as! Bool
      let sharedSecret = arguments?["sharedSecret"] as? String
      let apiVersion = arguments?["apiVersion"] as? String ?? "v2"
      initAmaniWithEmail(server: server, customerIdCardNumber: customerIdCardNumber, email: email, password: password, useLocation: useLocation, lang: lang, sharedSecret: sharedSecret, version: apiVersion, result: result)
    // ID Capture
    case "setIDCaptureType":
      let idCapture = IdCapture()
      let type = arguments?["type"] as! String
      idCapture.setType(type: type, result: result)
    case "startIDCapture":
      let idCapture = IdCapture()
      let stepID = arguments?["stepID"] as? Int
      idCapture.start(stepID: stepID ?? 0, result: result)
    case "setIDCaptureManualButtonTimeout":
      let idCapture = IdCapture()
      let timeout = arguments?["timeout"] as! Int
      idCapture.setManualCaptureButtonTimeout(timeout: timeout, result: result)
    case "iosIDCaptureNFC":
    
        if let arguments = call.arguments as? [String: Any], 
           let birthDate = arguments["birthDate"] as? String,
           let expireDate = arguments["expireDate"] as? String,
           let documentNo = arguments["documentNo"] as? String {
            print("[AmaniBridge][IDCapture] Starting NFC scan")
            
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
      idCapture.upload(result: result)
    case "uploadIDCaptureWithDocumentId":
      let idCapture = IdCapture()
      idCapture.uploadWithDocumentId(result: result)
      // get Mrz Data
    case "getMrz":
    let idCapture = IdCapture()
     idCapture.getMrz(result: result)
    // Selfie
    case "setSelfieType":
      let selfie = Selfie()
      let type = arguments?["type"] as! String
      selfie.setType(type: type, result: result)
    case "startSelfie":
      let selfie = Selfie()
      selfie.start(result: result)
    case "uploadSelfie":
      let selfie = Selfie()
      selfie.upload(result: result)
    case "uploadSelfieWithDocumentId":
      let selfie = Selfie()
      selfie.uploadWithDocumentId(result: result)
    // AutoSelfie
    case "startAutoSelfie":
      let autoSelfie = AutoSelfie()
      let decoder = JSONDecoder()
      let iosArgs = arguments?["iosSettings"] as! String
      let autoSelfieSettings = try! decoder.decode(AutoSelfieSettings.self, from: Data(iosArgs.utf8))
      autoSelfie.start(settings: autoSelfieSettings, result: result)
    case "setAutoSelfieType":
      let autoSelfie = AutoSelfie()
      let type = arguments?["type"] as! String
      autoSelfie.setType(type: type, result: result)
    case "uploadAutoSelfie":
      let autoSelfie = AutoSelfie()
      autoSelfie.upload(result: result)
    case "uploadAutoSelfieWithDocumentId":
      let autoSelfie = AutoSelfie()
      autoSelfie.uploadWithDocumentId(result: result)
    // Pose Estimation
    case "startPoseEstimation":
      let poseEstimation = PoseEstimation()
      let iosArgs = arguments?["iosSettings"] as! String
      let decoder = JSONDecoder()
      let poseEstimationSettings = try! decoder.decode(PoseEstimationSettings.self, from: Data(iosArgs.utf8))
      poseEstimation.start(settings: poseEstimationSettings, result: result)
    case "setPoseEstimationType":
        let poseEstimation = PoseEstimation()
        let type = arguments?["type"] as! String
        poseEstimation.setType(type: type, result: result)
    case "setPoseEstimationVideoRecording":
      let poseEstimation = PoseEstimation()
      let enabled = arguments?["enabled"] as? Bool
      poseEstimation.setVideoRecording(enabled: enabled ?? true, result: result)
    case "uploadPoseEstimation":
        let poseEstimation = PoseEstimation()
        poseEstimation.upload(result: result)
    case "uploadPoseEstimationWithDocumentId":
        let poseEstimation = PoseEstimation()
        poseEstimation.uploadWithDocumentId(result: result)

    // Speech Verifier
    case "startSpeechVerifier":
      let speechVerifier = SpeechVerifier()
      // Keep the instance alive: the upload call needs the verifier built in start.
      self.speechVerifierInstance = speechVerifier
      let iosArgs = arguments?["iosSettings"] as! String
      speechVerifier.start(settingsJSON: iosArgs, result: result)
    case "uploadSpeechVerifier":
        speechVerifierInstance?.upload { [weak self] isSuccess in
          result(isSuccess)
          self?.speechVerifierInstance = nil
        }
    case "uploadSpeechVerifierWithDocumentId":
        guard let speechVerifier = speechVerifierInstance else {
          UploadResultPayload.send(isSuccess: false, documentId: nil, module: "SpeechVerifier", to: result)
          return
        }
        speechVerifier.uploadWithDocumentId { [weak self] payload in
          result(payload)
          self?.speechVerifierInstance = nil
        }
    // Signature
    case "startSignature":
      let signature = SignatureCapture()
      self.signatureInstance = signature
      signature.start(arguments: arguments, result: result)
    case "uploadSignature":
      let signature = signatureInstance ?? SignatureCapture()
      signature.upload(result: result)
    case "uploadSignatureWithDocumentId":
      let signature = signatureInstance ?? SignatureCapture()
      signature.uploadWithDocumentId(result: result)
    // NFC
    /*
    case "iOSstartNFCWithImageData":
        let nfc = NFC()
        let imageData = arguments?["imageData"] as! FlutterStandardTypedData
        nfc.start(imageData: imageData, result: result)
      */
    case "iOSstartNFCWithNviModel":
        Task {
            do {
                let nfc = NFC()
                guard let nviData = arguments?["nviData"] as? [String: String] else {
                    result(FlutterError(code: "400", message: "Invalid arguments", details: nil))
                    return
                }
                let nviModel = NviModel(
                    documentNo: nviData["documentNo"]!,
                    dateOfBirth: nviData["dateOfBirth"]!,
                    dateOfExpire: nviData["dateOfExpire"]!
                )
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
                 let nviData = arguments?["nviData"] as! [String: String]
                 let nviModel = NviModel(documentNo: nviData["documentNo"]!, dateOfBirth: nviData["dateOfBirth"]!, dateOfExpire: nviData["dateOfExpire"]!)
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
        let type = arguments?["type"] as! String
        nfc.setType(type: type, result: result)
    case "iOSuploadNFC":
        let nfc = NFC()
        nfc.upload(result: result)
    case "iOSuploadNFCWithDocumentId":
        let nfc = NFC()
        nfc.uploadWithDocumentId(result: result)
    case "initBioLogin":
      print("initBioLogin")
        // let bioLogin = BioLogin.shared
        // bioLogin.initBioLogin(server: arguments!["server"] as! String,
        //                       token: arguments!["token"] as! String,
        //                       customerId: arguments!["customerId"] as! String,
        //                       attemptId: arguments!["attemptId"] as! String,
        //                       source: arguments!["source"] as? Int,
        //                       comparisonAdapter: arguments!["comparisonAdapter"] as? Int,
        //                       result: result)
    case "startBioLoginWithAutoSelfie":
      print("startBioLoginWithAutoSelfie")
        // let bioLogin = BioLogin.shared
        // let decoder = JSONDecoder()
        // let iosArgs = arguments?["iosSettings"] as! String
        // let autoSelfieSettings = try! decoder.decode(AutoSelfieSettings.self, from: Data(iosArgs.utf8))
        // bioLogin.startWithAutoSelfie(settings: autoSelfieSettings, result: result)
    case "startBioLoginWithPoseEstimation":
      print("startBioLoginWithPoseEstimation")
        // let bioLogin = BioLogin.shared
        // let decoder = JSONDecoder()
        // let iosArgs = arguments!["iosSettings"] as! String
        // let poseEstimationSettings = try! decoder.decode(PoseEstimationSettings.self, from: Data(iosArgs.utf8))
        // bioLogin.startWithPoseEstimation(settings: poseEstimationSettings, result: result)
    case "startBioLoginWithManualSelfie":
      print("startBioLoginWithManualSelfie")
        // let bioLogin = BioLogin.shared
        // bioLogin.startWithManualSelfie(result: result)
    case "uploadBioLogin":
      print("uploadBioLogin")
        // let bioLogin = BioLogin.shared
        // bioLogin.upload(result: result)
    case "getCustomerInfo":
        getCustomerInfo(result: result)
    // MARK: Document Capture
    case "startDocumentCapture":
      let documentCount = arguments!["documentCount"] as! Int? ?? 1
      let documentCapture = DocumentCapture()
      documentCapture.start(documentCount: documentCount, result: result)
    case "setDocumentCaptureType":
      let documentCapture = DocumentCapture()
      let documentType = arguments!["type"] as! String
      documentCapture.setType(type: documentType, result: result)
    case "documentCaptureUpload":
      let documentCapture = DocumentCapture()
      documentCapture.upload(files: documentFiles(from: arguments), result: result)
    case "documentCaptureUploadWithDocumentId":
      let documentCapture = DocumentCapture()
      documentCapture.uploadWithDocumentId(files: documentFiles(from: arguments), result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
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
                         result: @escaping FlutterResult) {
    let customer = CustomerRequestModel(name: nil, email: nil, phone: nil, idCardNumber: customerIdCardNumber)
    let apiVersion = version == "v2" ? ApiVersions.v2 : ApiVersions.v1
    
    Amani.sharedInstance.setDelegate(delegate: SwiftFlutterAmanisdkPlugin.eventHandler)
    Amani.sharedInstance.setMRZDelegate(delegate: SwiftFlutterAmanisdkPlugin.eventHandler)
    Amani.sharedInstance.initAmani(server: server, token: customerToken, sharedSecret: sharedSecret, customer: customer, language: lang, apiVersion: apiVersion) { (customerRes, err) in
      if customerRes != nil {
        result(true)
      } else if let err = err {
        result(FlutterError(code: String(err.error_code), message: "Couldn't login to Amani server", details: err.error_message))
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
                        result: @escaping FlutterResult) {
    let customer = CustomerRequestModel(name: nil, email: nil, phone: nil, idCardNumber: customerIdCardNumber)
    let apiVersion: ApiVersions = version == "v2" ? .v2 : .v1
    Amani.sharedInstance.setDelegate(delegate: SwiftFlutterAmanisdkPlugin.eventHandler)
    Amani.sharedInstance.setMRZDelegate(delegate: SwiftFlutterAmanisdkPlugin.eventHandler)
    Amani.sharedInstance.initAmani(server: server, userName: email, password: password, sharedSecret: sharedSecret, customer: customer, language: lang, apiVersion: apiVersion) { customerRes, err in
      if customerRes != nil {
        result(true)
      } else if let err = err {
        result(FlutterError(code: String(err.error_code), message: "Couldn't login to Amani server", details: err.error_message))
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

