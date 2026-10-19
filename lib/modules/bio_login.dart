import 'package:flutter/services.dart';

import 'package:flutter_amanisdk/common/models/android/auto_selfie_settings.dart';
import 'package:flutter_amanisdk/common/models/android/pose_estimation_settings.dart';
import 'package:flutter_amanisdk/common/models/ios/auto_selfie_settings.dart';
import 'package:flutter_amanisdk/common/models/ios/pose_estimation_settings.dart';
import 'package:flutter_amanisdk/common/models/upload_result.dart';
import 'package:flutter_amanisdk/flutter_amanisdk_method_channel.dart';

class BioLogin {
  final MethodChannelAmaniSDK _methodChannel;
  BioLogin(this._methodChannel);

  MethodChannel? _androidBioLoginChannel;
  Function(Uint8List)? _androidPoseEstimationOnSuccess;
  Function(Map<String, dynamic>)? _androidPoseEstimationOnFailure;

  /// Sets up BioLogin.
  ///
  /// iOS uses [server] and [token] to build the BioLogin module.
  /// Android (BioLogin V2) runs on the SDK session instead: start it first with
  /// [AmaniSDK.setConfigure] and [AmaniSDK.startAmaniSDKWithConfigure] using a
  /// profile token. [customerId] and [attemptId] are no longer used.
  Future<void> init({
    required String customerId,
    required String server,
    required String token,
    required String attemptId,
    int? source,
    int? comparisonAdapter,
    String? sharedSecret,
  }) async {
    return _methodChannel.initBioLogin(
        server: server,
        token: token,
        customerId: customerId,
        attemptId: attemptId,
        source: source,
        comparisonAdapter: comparisonAdapter,
        sharedSecret: sharedSecret);
  }

  Future<Uint8List> startWithAutoSelfie(
      {required IOSAutoSelfieSettings iosAutoSelfieSettings,
      required AndroidAutoSelfieSettings androidAutoSelfieSettings}) async {
    try {
      final imageData = await _methodChannel.startBioLoginWithAutoSelfie(
          iosSettings: iosAutoSelfieSettings,
          androidSettings: androidAutoSelfieSettings);
      if (imageData != null) {
        return imageData;
      } else {
        throw Exception("Nothing returned from BioLogin.startWithAutoSelfie");
      }
    } catch (err) {
      rethrow;
    }
  }

  Future<void> _handleInverseChannel(MethodCall call) async {
    final args = Map.from(call.arguments);
    switch (call.method) {
      case 'androidBioLoginPoseEstimation#onSuccess':
        if (_androidPoseEstimationOnSuccess != null) {
          _androidPoseEstimationOnSuccess!(args["image"] as Uint8List);
        }
        break;
      case 'androidBioLoginPoseEstimation#onError':
        throw Exception(args["message"]);
      case 'androidBioLoginPoseEstimation#onFailure':
        if (_androidPoseEstimationOnFailure != null) {
          _androidPoseEstimationOnFailure!(args as Map<String, dynamic>);
        }
    }
  }

  Future<Uint8List> iOSStartWithPoseEstimation(
      {required IOSPoseEstimationSettings settings}) async {
    final imageData = await _methodChannel.iOSStartBioLoginWithPoseEstimation(
        settings: settings);
    if (imageData != null) {
      return imageData;
    } else {
      throw Exception("Nothing returned from BioLogin.startWithPoseEstimation");
    }
  }

  Future<Uint8List?> androidStartWithPoseEstimation(
      {required AndroidPoseEstimationSettings settings,
      required Function(Uint8List) onSuccessCallback,
      required Function(Map<String, dynamic>) onFailureCallback}) async {
    _androidPoseEstimationOnSuccess = onSuccessCallback;
    _androidPoseEstimationOnFailure = onFailureCallback;
    _androidBioLoginChannel = const MethodChannel('amanisdk_biologin_channel');
    _androidBioLoginChannel!.setMethodCallHandler(_handleInverseChannel);

    return await _methodChannel.androidStartBioLoginWithPoseEstimation(
        settings: settings);
  }

  Future<Uint8List> startWithManualSelfie(
      {required String androidSelfieDescriptionText}) async {
    try {
      final imageData = await _methodChannel.startBioLoginWithManualSelfie(
          androidSelfieDescriptionText: androidSelfieDescriptionText);
      if (imageData != null) {
        return imageData;
      } else {
        throw Exception("Nothing returned from BioLogin.startWithManualSelfie");
      }
    } catch (err) {
      rethrow;
    }
  }

  /// Uploads the BioLogin selfie and returns `true` when the selfie was
  /// approved. Unlike other modules, `false` means the upload failed or the
  /// selfie was not approved.
  ///
  /// Pass [onResult] to also receive the `documentId` of the document the
  /// upload created:
  ///
  /// ```dart
  /// final isSuccess = await bioLogin.upload(
  ///   onResult: (isSuccess, documentId) {
  ///     print('Upload finished: $isSuccess, documentId: $documentId');
  ///   },
  /// );
  /// ```
  Future<bool> upload({UploadResultCallback? onResult}) async {
    if (onResult == null) {
      return await _methodChannel.uploadBioLogin();
    }
    final response = await _methodChannel.invokeUpload('uploadBioLogin');
    return _methodChannel.deliverUploadResult(response, onResult);
  }

  Future<bool> androidBackButtonHandle() async {
    return await _methodChannel.androidBioLoginBackPressHandle();
  }
}
