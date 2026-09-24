import 'package:flutter_amanisdk/common/models/upload_result.dart';
import 'dart:typed_data';

import 'package:flutter_amanisdk/common/models/android/auto_selfie_settings.dart';
import 'package:flutter_amanisdk/common/models/ios/auto_selfie_settings.dart';
import 'package:flutter_amanisdk/flutter_amanisdk_method_channel.dart';

class AutoSelfie {
  final MethodChannelAmaniSDK _methodChannel;

  AutoSelfie(this._methodChannel);

  Future<Uint8List> start({
    required AndroidAutoSelfieSettings androidAutoSelfieSettings,
    required IOSAutoSelfieSettings iosAutoSelfieSettings,
  }) async {
    try {
      final dynamic imgData = await _methodChannel.startAutoSelfie(
          androidSettings: androidAutoSelfieSettings,
          iosSettings: iosAutoSelfieSettings);
      if (imgData != null) {
        return imgData as Uint8List;
      } else {
        throw Exception("[AmaniSDK] no image returned from autoSelfieModule");
      }
    } catch (err) {
      rethrow;
    }
  }

  /// Uploads the captured auto selfie and returns `true` when the upload succeeds.
  ///
  /// Pass [onResult] to also receive the `documentId` of the document the
  /// upload created:
  ///
  /// ```dart
  /// final isSuccess = await autoSelfie.upload(
  ///   onResult: (isSuccess, documentId) {
  ///     print('Upload finished: $isSuccess, documentId: $documentId');
  ///   },
  /// );
  /// ```
  Future<bool> upload({UploadResultCallback? onResult}) async {
    if (onResult == null) {
      return await _methodChannel.uploadAutoSelfie();
    }
    final response = await _methodChannel.uploadAutoSelfieWithDocumentId();
    return _methodChannel.deliverUploadResult(response, onResult);
  }

  Future<void> setType(String type) async {
    await _methodChannel.setAutoSelfieType(type: type);
  }

  Future<bool> androidBackButtonHandle() async {
    return await _methodChannel.androidAutoSelfieBackPressHandle();
  }
}
