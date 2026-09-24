
import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_amanisdk/common/models/api_version.dart';
import 'package:flutter_amanisdk/common/models/customer_detail.dart';
import 'package:flutter_amanisdk/flutter_amanisdk_method_channel.dart';
import 'package:flutter_amanisdk/modules/auto_selfie.dart';
import 'package:flutter_amanisdk/modules/bio_login.dart';
import 'package:flutter_amanisdk/modules/document_capture.dart';
import 'package:flutter_amanisdk/modules/id_capture.dart';
import 'package:flutter_amanisdk/modules/nfc_capture_android.dart';
import 'package:flutter_amanisdk/modules/nfc_capture_ios.dart';
import 'package:flutter_amanisdk/modules/pose_estimation.dart';
import 'package:flutter_amanisdk/modules/selfie.dart';
import 'package:flutter_amanisdk/modules/signature.dart';
import 'package:flutter_amanisdk/modules/speech_verifier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'amaniAndroidConfigure.dart';
import 'amanisdk_platform_interface.dart';
import 'sdkresult.dart';

class AmaniSDK {
  Completer<SdkResult>? _completer;

  // ignore: non_constant_identifier_names
  Amanisdk() {
    AmaniSDKPlatform.instance.methodChannel
        .setMethodCallHandler(_handleInverseChannel);
  }

  final MethodChannelAmaniSDK _methodChannel = MethodChannelAmaniSDK();
  // final delegateChannel = const MethodChannel("amanisdk_delegate_channel");
  // final delegateEventChannel = const EventChannel("amanisdk_delegate_channel");
  static const EventChannel _delegateEventChannel = EventChannel("amanisdk_delegate_channel");

  static Stream<dynamic>? _cachedDelegateStream;

  /// returns [IdCapture] module
  IdCapture getIDCapture() {
    return IdCapture(_methodChannel);
  }

  /// returns [Selfie] module
  Selfie getSelfie() {
    return Selfie(_methodChannel);
  }

  /// returns [AutoSelfie] module
  AutoSelfie getAutoSelfie() {
    return AutoSelfie(_methodChannel);
  }

  /// Returns [PoseEstimation] module
  PoseEstimation getPoseEstimation() {
    return PoseEstimation(_methodChannel);
  }

   /// Returns [SpeechVerifier] module
  SpeechVerifier getSpeechVerifier() {
    return SpeechVerifier(_methodChannel);
  }

  /// Returns [IOSNFCCapture] module
  IOSNFCCapture getIOSNFCCapture() {
    return IOSNFCCapture(_methodChannel);
  }

  /// Returns [AndroidNFCCapture] module
  AndroidNFCCapture getAndroidNFCCapture() {
    return AndroidNFCCapture(_methodChannel);
  }

  /// Returns [BioLogin] module
  BioLogin getBioLogin() {
    return BioLogin(_methodChannel);
  }

  /// Returns [DocumentCapture] module
  DocumentCapture getDocumentCapture() {
    return DocumentCapture(_methodChannel);
  }

  /// Returns [Signature] module
  Signature getSignature() {
    return Signature(_methodChannel);
  }

  /// Initializes the SDK
  Future<bool> initAmani({
    /// server url
    required String server,

    /// customer token acquired from our rest api
    required String customerToken,

    /// customers id card number or any random string, must match with
    /// the id supplied while creating the customerToken field
    required String customerIdCardNumber,

    /// Sets if location info must be supplied while uploading the document
    required bool useLocation,

    /// Language parameters
    required String lang,

    /// API Version defaults to v2. Do not set this unless
    /// it's specified by Amani to you.
    AmaniApiVersion? apiVersion,

    /// Optional shared secret
    String? sharedSecret,
  }) async {
    if (server.isEmpty) {
      throw Exception("server parameter cannot be empty string");
    }

    String apiV = apiVersion == AmaniApiVersion.v1 ? "v1" : "v2";

    Uri serverURI = Uri.parse(server).normalizePath();
    try {
      var login = await _methodChannel.initAmani(
        server: serverURI.origin,
        customerToken: customerToken,
        customerIdCardNumber: customerIdCardNumber,
        lang: lang,
        useLocation: useLocation,
        sharedSecret: sharedSecret,
        apiVersion: apiV,
      );
      return login;
    } catch (err) {
      rethrow;
    }
  }
  
    Future<void> setConfigure({
    required String server,
    List<AmaniAndroidDynamicFeature> enabledFeatures = const [],
    String? sharedSecret,
    AmaniUploadSource uploadSource = AmaniUploadSource.kyc,
  }) async {
    await AmaniSDKPlatform.instance.setConfigure(
      server: server,
      enabledFeatures: enabledFeatures.map((e) => e.name).toList(),
      sharedSecret: sharedSecret,
      uploadSource: uploadSource.getUploadSourceString,
    );
  }

  Future<SdkResult> startAmaniSDKWithConfigure({
    required String token,
    required String id,
    String? birthDate,
    String? expireDate,
    String? documentNo,
    bool geoLocation = false,
    String? lang,
    String? email,
    String? phone,
    String? name,
  }) async {
    
    if (token.isEmpty) {
      throw Exception("You can't use an empty string as token");
    }

    if (!token.contains(".")) {
      throw Exception("The token must be in JWT format");
    }

    
    final tokenParts = token.split('.');
    if (tokenParts.length < 2) {
      throw Exception("Invalid JWT token format");
    }

    final payloadBytes = base64Decode(base64.normalize(tokenParts[1]));
    final payloadJson = jsonDecode(utf8.decode(payloadBytes));

    
    if (payloadJson['profile_id'] == null && payloadJson['customer_id'] == null) {
      throw Exception("You can't use admin token with this SDK.");
    }

    
    AmaniSDKPlatform.instance.startAmaniSDKWithConfigure(
      token,
      id,
      birthDate,
      expireDate,
      documentNo,
      geoLocation,
      lang,
      email,
      phone,
      name,
    );

    _completer = Completer<SdkResult>();
    return _completer!.future;
  }

  Future<void> _handleInverseChannel(MethodCall call) async {
    switch (call.method) {
      case 'onSuccess':
        final result = SdkResult.fromJson(jsonDecode(call.arguments));
        _completer?.complete(result);
        break;
      case 'onError':
        _completer?.completeError(call.arguments);
    }
  }
  

  Stream<dynamic> getDelegateStream() {
    _cachedDelegateStream ??= _delegateEventChannel.receiveBroadcastStream().asBroadcastStream();
    return _cachedDelegateStream!;
  }

  Future<CustomerInfoModel> getCustomerInfo() async {
    final customerInfo = await _methodChannel.getCustomerInfo();
    if (customerInfo != null) {
      final model =
          CustomerInfoModel.fromMap(Map<String, dynamic>.from(customerInfo));
      return model;
    } else {
      throw Exception("Failed to get customer info");
    }
  }

  /// Initializes the SDK
  /// **warning** do not use this command in production.
  /// It'll throw exception if used in production
  Future<bool> initAmaniWithEmail({
    /// server url
    required String server,

    /// api login email
    required String email,

    // api login password
    required String password,

    /// customers id card number or any random string, must match with
    /// the id supplied while creating the customerToken field
    required String customerIdCardNumber,

    /// Sets if location info must be supplied while uploading the document
    required bool useLocation,

    /// Language parameters
    required String lang,

    /// ApiVersion
    AmaniApiVersion? apiVersion,

    /// Optional shared secret
    String? sharedSecret,
  }) async {
    if (server.isEmpty) {
      throw Exception("server parameter cannot be empty string");
    }

    if (!kDebugMode) {
      throw Exception(
          "You can't run this method on production version of your app");
    }

    String apiV = apiVersion == AmaniApiVersion.v1 ? "v1" : "v2";

    Uri serverURI = Uri.parse(server).normalizePath();
    try {
      var login = await _methodChannel.initAmaniWithEmail(
          server: serverURI.origin,
          email: email,
          password: password,
          customerIdCardNumber: customerIdCardNumber,
          lang: lang,
          useLocation: useLocation,
          sharedSecret: sharedSecret,
          apiVersion: apiV);
      return login;
    } catch (err) {
      rethrow;
    }
  }
  
}
