import 'package:flutter_amanisdk/common/models/upload_result.dart';
import 'dart:typed_data';

import 'package:flutter_amanisdk/flutter_amanisdk_method_channel.dart';

class Selfie {
  final MethodChannelAmaniSDK _methodChannel;

  Selfie(this._methodChannel);

  Future<Uint8List> start() async {
    try {
      final dynamic imageData = await _methodChannel.startSelfie();
      if (imageData != null) {
        return imageData as Uint8List;
      } else {
        throw Exception("[AmaniSDK] no image returned from selfie module");
      }
    } catch (err) {
      rethrow;
    }
  }

  /// Uploads the captured selfie and returns `true` when the upload succeeds.
  ///
  /// Pass [onResult] to also receive the `documentId` of the document the
  /// upload created:
  ///
  /// ```dart
  /// final isSuccess = await selfie.upload(
  ///   onResult: (isSuccess, documentId) {
  ///     print('Upload finished: $isSuccess, documentId: $documentId');
  ///   },
  /// );
  /// ```
  Future<bool> upload({UploadResultCallback? onResult}) async {
    if (onResult == null) {
      return await _methodChannel.uploadSelfie();
    }
    final response = await _methodChannel.uploadSelfieWithDocumentId();
    return _methodChannel.deliverUploadResult(response, onResult);
  }

  Future<void> setType(String type) async {
    await _methodChannel.setSelfieType(type);
  }

  Future<bool> androidBackButtonHandle() async {
    return await _methodChannel.androidSelfieBackPressHandle();
  }
}
