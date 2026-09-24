package ai.amani.flutter_amanisdk

import android.app.Activity
import android.content.Context
import ai.amani.base.utility.AmaniVersion
import ai.amani.flutter_amanisdk.modules.*
import ai.amani.flutter_amanisdk.modules.config_models.AutoSelfieSettings
import ai.amani.flutter_amanisdk.modules.config_models.PoseEstimationSettings
import ai.amani.flutter_amanisdk.modules.SpeechVerifierModule
import ai.amani.sdk.Amani
import ai.amani.sdk.DynamicFeature
import ai.amani.sdk.UploadSource
import ai.amani.sdk.model.customer.CustomerDetailResult
import ai.amani.sdk.modules.customer.detail.CustomerDetailObserver
import io.flutter.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** FlutterAmanisdkPlugin */
class FlutterAmanisdkPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

  private lateinit var channel: MethodChannel
  private lateinit var nfcChannel: MethodChannel
  private lateinit var bioLoginChannel: MethodChannel
  private lateinit var delegateChannel: EventChannel

  private var activity: Activity? = null
  private var appContext: Context? = null
  private var isConfigured: Boolean = false
  private var speechVerifierModule: SpeechVerifierModule? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    appContext = binding.applicationContext

    channel = MethodChannel(binding.binaryMessenger, "amanisdk_method_channel")
    channel.setMethodCallHandler(this)

    nfcChannel = MethodChannel(binding.binaryMessenger, "amanisdk_nfc_channel")
    bioLoginChannel = MethodChannel(binding.binaryMessenger, "amanisdk_biologin_channel")

    delegateChannel = EventChannel(binding.binaryMessenger, "amanisdk_delegate_channel")
    delegateChannel.setStreamHandler(AmaniDelegateEventHandler())
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    appContext = null
    activity = null
    isConfigured = false
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {

      // -------------------------
      // Legacy init (token)
      // -------------------------
      "initAmani" -> {
        val server = call.argument<String>("server")
        val customerIdCardNumber = call.argument<String>("customerIdCardNumber")
        val customerToken = call.argument<String>("customerToken")
        val lang = call.argument<String>("lang") ?: "tr"
        val useLocation = call.argument<Boolean>("useLocation") ?: false
        val sharedSecret = call.argument<String>("sharedSecret")
        val version = call.argument<String>("apiVersion") ?: "v2"

        val ctx = appContext
        val act = activity

        if (server.isNullOrBlank() || customerIdCardNumber.isNullOrBlank() || customerToken.isNullOrBlank()) {
          result.error("INVALID_ARGUMENT", "server/customerIdCardNumber/customerToken must not be null or empty.", null)
          return
        }
        if (ctx == null) {
          result.error("NO_CONTEXT", "Plugin is not attached to engine (context is null).", null)
          return
        }
        if (act == null) {
          result.error("NO_ACTIVITY", "Plugin is not attached to activity (activity is null).", null)
          return
        }

        act.runOnUiThread {
          initAmani(
            context = ctx,
            activity = act,
            server = server,
            customerToken = customerToken,
            customerIdCardNumber = customerIdCardNumber,
            lang = lang,
            useLocation = useLocation,
            sharedSecret = sharedSecret,
            version = version,
            result = result
          )
        }
      }

      // -------------------------
      // Legacy init (email/pass)
      // -------------------------
      // "initAmaniWithEmail" -> {
      //   val server = call.argument<String>("server")
      //   val customerIdCardNumber = call.argument<String>("customerIdCardNumber")
      //   val email = call.argument<String>("email")
      //   val password = call.argument<String>("password")
      //   val lang = call.argument<String>("lang") ?: "tr"
      //   val useLocation = call.argument<Boolean>("useLocation") ?: false
      //   val sharedSecret = call.argument<String>("sharedSecret")
      //   val version = call.argument<String>("apiVersion") ?: "v2"

      //   val ctx = appContext
      //   val act = activity

      //   if (server.isNullOrBlank() || customerIdCardNumber.isNullOrBlank() || email.isNullOrBlank() || password.isNullOrBlank()) {
      //     result.error("INVALID_ARGUMENT", "server/customerIdCardNumber/email/password must not be null or empty.", null)
      //     return
      //   }
      //   if (ctx == null) {
      //     result.error("NO_CONTEXT", "Plugin is not attached to engine (context is null).", null)
      //     return
      //   }
      //   if (act == null) {
      //     result.error("NO_ACTIVITY", "Plugin is not attached to activity (activity is null).", null)
      //     return
      //   }

      //   act.runOnUiThread {
      //     initAmaniWithEmail(
      //       context = ctx,
      //       activity = act,
      //       server = server,
      //       customerIdCardNumber = customerIdCardNumber,
      //       email = email,
      //       password = password,
      //       lang = lang,
      //       useLocation = useLocation,
      //       sharedSecret = sharedSecret,
      //       version = version,
      //       result = result
      //     )
      //   }
      // }

      // -------------------------
      // Configure + startSession (doc-uyumlu)
      // -------------------------
      "setConfigure" -> setConfigure(call, result)
      "startAmaniSDKWithConfigure" -> startAmaniSDKWithConfigure(call, result)

      // -------------------------
      // IdCapture
      // -------------------------
      "setIDCaptureType" -> {
        val type = call.argument<String>("type")
        IdCapture.instance.setType(type, result)
      }

      "startIDCapture" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        val stepID = call.argument<Int>("stepID") ?: 0
        IdCapture.instance.start(stepID, act, result)
      }

      "setIDCaptureManualButtonTimeout" -> {
        val timeout = call.argument<Int>("timeout")
        if (timeout == null) {
          result.error("INVALID_ARGUMENT", "timeout is required", null)
          return
        }
        IdCapture.instance.setManualCaptureButtonTimeout(timeout)
        result.success(true)
      }

      "setIDCaptureNFC" -> {
        val usesNFC = call.argument<Boolean>("usesNFC")
        if (usesNFC == null) {
          result.error("INVALID_ARGUMENT", "usesNFC is required", null)
          return
        }
        IdCapture.instance.setWithNFC(usesNFC)
        result.success(true)
      }

      "setIDCaptureVideoRecordingEnabled" -> {
        val isEnabled = call.argument<Boolean>("enabled") ?: false
        IdCapture.instance.setVideoRecording(isEnabled, result)
      }

      "setIDCaptureHologramDetection" -> {
        val isEnabled = call.argument<Boolean>("enabled") ?: false
        IdCapture.instance.setHologramDetection(isEnabled, result)
      }

      "uploadIDCapture" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        IdCapture.instance.upload(act, result)
      }

      "uploadIDCaptureWithDocumentId" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        IdCapture.instance.uploadWithDocumentId(act, result)
      }

      "idCaptureAndroidBackPressHandle" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        IdCapture.instance.backPressHandle(act, result)
      }

      // -------------------------
      // Selfie
      // -------------------------
      "setSelfieType" -> {
        val type = call.argument<String>("type")
        Selfie.instance.setType(type, result)
      }

      "startSelfie" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        Selfie.instance.start(0, act, result)
      }

      "selfieAndroidBackPressHandle" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        Selfie.instance.backPressHandle(act, result)
      }

      "uploadSelfie" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        Selfie.instance.upload(act, result)
      }

      "uploadSelfieWithDocumentId" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        Selfie.instance.uploadWithDocumentId(act, result)
      }

      // -------------------------
      // AutoSelfie
      // -------------------------
      "startAutoSelfie" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        val androidSettings = call.argument<String>("androidSettings")
        if (androidSettings.isNullOrBlank()) {
          result.error("Missing Settings", "androidSettings is required", null)
          return
        }
        val model = androidSettings.toObject<AutoSelfieSettings>()
        AutoSelfie.instance.setSettings(model)
        AutoSelfie.instance.start(0, act, result)
      }

      "setAutoSelfieType" -> {
        val type = call.argument<String>("type")
        AutoSelfie.instance.setType(type, result)
      }

      "autoSelfieAndroidBackPressHandle" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        AutoSelfie.instance.backPressHandle(act, result)
      }

      "uploadAutoSelfie" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        AutoSelfie.instance.upload(act, result)
      }

      "uploadAutoSelfieWithDocumentId" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        AutoSelfie.instance.uploadWithDocumentId(act, result)
      }

      // -------------------------
      // Pose Estimation
      // -------------------------
      "startPoseEstimation" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        val androidSettings = call.argument<String>("androidSettings")
        if (androidSettings.isNullOrBlank()) {
          result.error("Missing Settings", "androidSettings is required", null)
          return
        }
        val model = androidSettings.toObject<PoseEstimationSettings>()
        PoseEstimation.instance.setSettings(model)
        PoseEstimation.instance.start(0, act, result)
      }

      "setPoseEstimationType" -> {
        val type = call.argument<String>("type")
        PoseEstimation.instance.setType(type, result)
      }

      "poseEstimationAndroidBackPressHandle" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        PoseEstimation.instance.backPressHandle(act, result)
      }

      "uploadPoseEstimation" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        PoseEstimation.instance.upload(act, result)
      }

      "uploadPoseEstimationWithDocumentId" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        PoseEstimation.instance.uploadWithDocumentId(act, result)
      }

      "setPoseEstimationVideoRecording" -> {
        val isEnabled = call.argument<Boolean>("enabled") ?: false
        PoseEstimation.instance.setVideoRecording(isEnabled, result)
      }

      // -------------------------
      // Speech Verifier
      // -------------------------
    "startSpeechVerifier" -> {
      val act = activity ?: run {
        result.error("NO_ACTIVITY", "Activity is null", null)
        return
     }
    
      if (!isSpeechVerifierAvailable()) {
        result.error(
            "SPEECH_VERIFIER_UNAVAILABLE",
            "Speech Verifier module is not included. Add 'ai.amani.android:amani-speech-verifier' to your app dependencies.",
            null
        )
        return
      }
      val androidSettings = call.argument<String>("androidSettings")
      if (androidSettings.isNullOrBlank()) {
          result.error("Missing Settings", "androidSettings is required", null)
          return
      }
      val module = SpeechVerifierModule(act)
      speechVerifierModule = module
      module.start(androidSettings, result)
    }

      "uploadSpeechVerifier" -> {
        speechVerifierModule?.upload(result) ?: result.success(false)
      }

      "uploadSpeechVerifierWithDocumentId" -> {
        speechVerifierModule?.uploadWithDocumentId(result)
          ?: result.success(mapOf("isSuccess" to false, "documentId" to null))
      }

      "speechVerifierAndroidBackPressHandle" -> {
        result.success(speechVerifierModule?.handleBackPress() ?: true)
      }

      // -------------------------
      // NFC
      // -------------------------
      "androidStartNFC" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }

        val birthDate = call.argument<String>("birthDate")
        val expireDate = call.argument<String>("expireDate")
        val documentNo = call.argument<String>("documentNo")

        if (!IdCapture.instance.usesNFC) {
          if (birthDate.isNullOrBlank() || expireDate.isNullOrBlank() || documentNo.isNullOrBlank()) {
            result.error("Missing Params", "birthDate/expireDate/documentNo required when NFC is used as a document.", null)
            return
          }
        }

        NFC.instance.start(birthDate, expireDate, documentNo, act, nfcChannel, result)
      }

      "androidDisableNFC" -> {
        val act = activity
        val fragmentAct = act as? FlutterFragmentActivity
        if (fragmentAct == null) {
          result.error("INVALID_ACTIVITY", "Activity is not a FlutterFragmentActivity", null)
          return
        }
        NFC.instance.disableNFC(fragmentAct)
        result.success(null)
      }

      "androidSetNFCType" -> {
        val type = call.argument<String>("type")
        if (type.isNullOrBlank()) {
          result.error("INVALID_ARGUMENT", "type is required", null)
          return
        }
        NFC.instance.setType(type, result)
      }

      "androidUploadNFC" -> {
        NFC.instance.upload(result)
      }

      "androidUploadNFCWithDocumentId" -> {
        NFC.instance.uploadWithDocumentId(result)
      }

      // -------------------------
      // Signature
      // -------------------------
      "startSignature" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        @Suppress("UNCHECKED_CAST")
        val settings = call.arguments as? Map<String, Any?>
        SignatureCapture.instance.start(settings, act, result)
      }

      "uploadSignature" -> {
        SignatureCapture.instance.upload(result)
      }

      "uploadSignatureWithDocumentId" -> {
        SignatureCapture.instance.uploadWithDocumentId(result)
      }

      "signatureAndroidBackPressHandle" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        SignatureCapture.instance.backPressHandle(act, result)
      }

      // -------------------------
      // BioLogin
      // -------------------------
      "initBioLogin" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }

        val server = call.argument<String>("server")
        val token = call.argument<String>("token")
        val customerId = call.argument<String>("customerId")
        val attemptId = call.argument<String>("attemptId")
        val source = call.argument<Int>("source")
        val comparisonAdapter = call.argument<Int>("comparisonAdapter")
        val sharedSecret = call.argument<String>("sharedSecret")

        if (server.isNullOrBlank() || token.isNullOrBlank() || customerId.isNullOrBlank() || attemptId.isNullOrBlank()) {
          result.error("INVALID_ARGUMENT", "server/token/customerId/attemptId must not be null or empty.", null)
          return
        }

        BioLogin.instance.initBioLogin(
          server,
          sharedSecret,
          token,
          customerId.toInt(),
          comparisonAdapter,
          source,
          attemptId,
          act,
          result
        )
      }

      "startBioLoginWithAutoSelfie" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        val androidSettings = call.argument<String>("androidSettings")
        if (androidSettings.isNullOrBlank()) {
          result.error("Missing Settings", "androidSettings is required", null)
          return
        }
        val model = androidSettings.toObject<AutoSelfieSettings>()
        BioLogin.instance.startWithAutoSelfie(model, act, result)
      }

      "androidStartBioLoginWithPoseEstimation" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        val androidSettings = call.argument<String>("androidSettings")
        if (androidSettings.isNullOrBlank()) {
          result.error("Missing Settings", "androidSettings is required", null)
          return
        }
        val model = androidSettings.toObject<PoseEstimationSettings>()
        BioLogin.instance.startWithPoseEstimation(model, act, result, bioLoginChannel)
      }

      "startBioLoginWithManualSelfie" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        val selfieDescriptionText = call.argument<String>("androidSelfieDescriptionText")
        if (selfieDescriptionText.isNullOrBlank()) {
          result.error("INVALID_ARGUMENT", "androidSelfieDescriptionText is required", null)
          return
        }
        BioLogin.instance.startWithManualSelfie(selfieDescriptionText, act, result)
      }

      "bioLoginAndroidBackPressHandle" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        BioLogin.instance.backPressHandle(act, result)
      }

      "uploadBioLogin" -> {
        BioLogin.instance.upload(result)
      }

      // -------------------------
      // Customer info
      // -------------------------
      "getCustomerInfo" -> getCustomerInfo(result)

      // -------------------------
      // Document capture
      // -------------------------
      "startDocumentCapture" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        val docCountParam = call.argument<Int>("documentCount") ?: 1
        DocumentCapture.instance.start(docCountParam, act, result)
      }

      "setDocumentCaptureType" -> {
        val type = call.argument<String>("type")
        DocumentCapture.instance.setType(type, result)
      }

      "documentCaptureUpload" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        val files = call.argument<List<Map<String, Any>>>("files")
        if (files != null) {
          DocumentCapture.instance.setFiles(files)
        }
        DocumentCapture.instance.upload(act, result)
      }

      "documentCaptureUploadWithDocumentId" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        val files = call.argument<List<Map<String, Any>>>("files")
        if (files.isNullOrEmpty()) {
          DocumentCapture.instance.clearFiles()
        } else {
          DocumentCapture.instance.setFiles(files)
        }
        DocumentCapture.instance.uploadWithDocumentId(act, result)
      }

      "documentCaptureBackPressHandle" -> {
        val act = activity ?: run {
          result.error("NO_ACTIVITY", "Activity is null", null)
          return
        }
        DocumentCapture.instance.backPressHandle(act, result)
      }

      else -> result.notImplemented()
    }
  }

  private fun setConfigure(call: MethodCall, result: MethodChannel.Result) {
    val context = appContext
    if (context == null) {
      result.error("NO_CONTEXT", "Plugin is not attached to engine (context is null).", null)
      return
    }

    val server = call.argument<String>("server")
    if (server.isNullOrBlank()) {
      result.error("INVALID_ARGUMENT", "Argument 'server' must not be null or empty.", null)
      return
    }

    val features = call.argument<List<String>>("enabledFeatures") ?: emptyList()
    val dynamicFeatures = features.mapNotNull { featureName ->
      when (featureName) {
        "idCapture" -> DynamicFeature.ID_CAPTURE
        "idHologramDetection" -> DynamicFeature.ID_HOLOGRAM_DETECTION
        "nfcScan" -> DynamicFeature.NFC_SCAN
        "selfieAuto" -> DynamicFeature.SELFIE_AUTO
        "selfiePoseEstimation" -> DynamicFeature.SELFIE_POSE_ESTIMATION
        else -> null
      }
    }

    val sharedSecret = call.argument<String>("sharedSecret")

    val uploadSourceString = call.argument<String>("uploadSource")
    val uploadSource = when (uploadSourceString) {
      "VIDEO" -> UploadSource.VIDEO
      "PASSWORD" -> UploadSource.PASSWORD
      "KYC", null -> UploadSource.KYC
      else -> UploadSource.KYC
    }

    val apiVersionString = call.argument<String>("apiVersion")
    val amaniVersion = when (apiVersionString) {
      "v1" -> AmaniVersion.V1
      "v2", null -> AmaniVersion.V2
      else -> AmaniVersion.V2
    }

    try {
      // Dokümana uygun parametre isimleri: context/server/version
      Amani.configure(
        context = context,
        server = server,
        sharedSecret = sharedSecret,
        version = amaniVersion,
        uploadSource = uploadSource,
        enabledFeatures = dynamicFeatures
      )
      isConfigured = true
      result.success(null)
    } catch (e: Exception) {
      result.error("CONFIGURE_FAILED", "Amani.configure failed: ${e.message}", null)
    }
  }

  private fun startAmaniSDKWithConfigure(call: MethodCall, result: MethodChannel.Result) {
    if (!isConfigured) {
        result.error(
            "NOT_CONFIGURED",
            "AmaniSDK is not configured. Call 'setConfigure' first.",
            null
        )
        return
    }

    val idNumber = call.argument<String>("id")
    val token = call.argument<String>("token")

    if (idNumber.isNullOrBlank() || token.isNullOrBlank()) {
        result.error(
            "INVALID_ARGUMENT",
            "Arguments 'id' and 'token' must not be null or empty.",
            null
        )
        return
    }

    val birthDate = call.argument<String>("birthDate")
    val expireDate = call.argument<String>("expireDate")
    val documentNo = call.argument<String>("documentNo")
    val geoLocation = call.argument<Boolean>("geoLocation") ?: false

    val lang = call.argument<String>("lang")
        ?: call.argument<String>("language")
        ?: "tr"

    val email = call.argument<String>("email")
    val phone = call.argument<String>("phone")
    val name = call.argument<String>("name")

    try {
        Amani.sharedInstance().startSession(
            id = idNumber,
            token = token,
            lang = lang,
            birthDate = birthDate,
            expireDate = expireDate,
            documentNo = documentNo,
            geoLocation = geoLocation,
            userFullName = name,
            userPhoneNumber = phone,
            userEmail = email,
            callback = { isSuccess ->
                Log.d("AmaniFlutterBridge", "startSession completed: $isSuccess, language: $lang")
                result.success(isSuccess)
            }
        )
    } catch (e: Exception) {
        Log.e("AmaniFlutterBridge", "startSession failed", e)

        result.error(
            "START_SESSION_FAILED",
            "Amani.startSession failed: ${e.message}",
            null
        )
    }
  }

  private fun initAmani(
    context: Context,
    activity: Activity,
    server: String,
    customerToken: String,
    customerIdCardNumber: String,
    lang: String,
    useLocation: Boolean,
    sharedSecret: String?,
    version: String,
    result: MethodChannel.Result
  ) {
    val amaniVersion = if (version == "v2") AmaniVersion.V2 else AmaniVersion.V1

    try {
      // Yeni yapı: configure
      Amani.configure(
        context = context,
        server = server,
        sharedSecret = sharedSecret,
        version = amaniVersion,
        uploadSource = UploadSource.KYC,
        enabledFeatures = emptyList()
      )
    } catch (e: Exception) {
      result.error("CONFIGURE_FAILED", "Amani.configure failed: ${e.message}", null)
      return
    }

    // initAmani imzası sende Kotlin görünüyor; lang/geoLocation sırasını düzeltmek için named args kullanıyoruz.
    try {
      Amani.sharedInstance().initAmani(
        activity = activity,
        id = customerIdCardNumber,
        token = customerToken,
        lang = lang,
        geoLocation = useLocation,
        callback = { loggedIn ->
          result.success(loggedIn)
        }
      )
    } catch (e: Exception) {
      result.error("INIT_FAILED", "initAmani failed: ${e.message}", null)
    }
  }

  // private fun initAmaniWithEmail(
  //   context: Context,
  //   activity: Activity,
  //   server: String,
  //   customerIdCardNumber: String,
  //   email: String,
  //   password: String,
  //   lang: String,
  //   useLocation: Boolean,
  //   sharedSecret: String?,
  //   version: String,
  //   result: MethodChannel.Result
  // ) {
  //   val amaniVersion = if (version == "v2") AmaniVersion.V2 else AmaniVersion.V1

  //   try {
  //     Amani.configure(
  //       context = context,
  //       server = server,
  //       sharedSecret = sharedSecret,
  //       version = amaniVersion,
  //       uploadSource = UploadSource.KYC,
  //       enabledFeatures = emptyList()
  //     )
  //   } catch (e: Exception) {
  //     result.error("CONFIGURE_FAILED", "Amani.configure failed: ${e.message}", null)
  //     return
  //   }

  //   // Email initAmani imzası sende farklı olabilir; en sık doğru sıra: (activity, id, email, password, lang, geoLocation, callback)
  //   try {
  //     Amani.sharedInstance().initAmani(
  //       activity,
  //       customerIdCardNumber,
  //       email,
  //       password,
  //       lang,
  //       useLocation
  //     ) { loggedIn ->
  //       result.success(loggedIn)
  //     }
  //   } catch (e: Exception) {
  //     result.error("INIT_FAILED", "initAmaniWithEmail failed: ${e.message}", null)
  //   }
  // }

  private fun getCustomerInfo(result: MethodChannel.Result) {
    Amani.sharedInstance().CustomerDetail().getCustomerDetail(object : CustomerDetailObserver {
      override fun result(customerDetail: CustomerDetailResult?, throwable: Throwable?) {
        if (throwable != null) {
          result.error("CustomerInfo-Fetch", throwable.message, null)
          return
        }

        if (customerDetail == null) {
          result.success(null)
          return
        }

        val rules: List<Map<String, Any?>>? = customerDetail.rules?.map {
          mapOf<String, Any?>(
            "id" to it.id,
            "title" to it.title,
            "documentClasses" to it.documentClasses,
            "status" to it.status
          )
        }

        val missingRules: List<Map<String, Any?>>? = customerDetail.missingRules?.map {
          mapOf<String, Any?>(
            "id" to it?.id,
            "title" to it?.title,
            "documentClasses" to it?.documentClasses
          )
        }

        val customerInfoDict: Map<String, Any?> = mapOf(
          "id" to customerDetail.id,
          "name" to customerDetail.name,
          "email" to customerDetail.email,
          "phone" to customerDetail.phone,
          "status" to customerDetail.status,
          "occupation" to customerDetail.occupation,
          "city" to null,
          "address" to null,
          "province" to null,
          "idCardNumber" to customerDetail.idCardNumber,
          "rules" to rules,
          "missingRules" to missingRules
        )

        result.success(customerInfoDict)
      }
    })
  }

  private fun isSpeechVerifierAvailable(): Boolean {
    return try {
        Class.forName("ai.amani.speechverifier.SpeechVerifier")
        true
    } catch (e: ClassNotFoundException) {
        false
    }
  }
}
