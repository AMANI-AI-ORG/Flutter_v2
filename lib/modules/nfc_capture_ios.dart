import 'dart:typed_data';

import 'package:flutter_amanisdk/common/models/upload_result.dart';
import 'package:flutter_amanisdk/common/models/nvi_data.dart';
import 'package:flutter_amanisdk/flutter_amanisdk_method_channel.dart';

class IOSNFCCapture {
  final MethodChannelAmaniSDK _methodChannel;

  IOSNFCCapture(this._methodChannel);

  Future<bool> startWithImageData(Uint8List imageData) async {
    try {
      final bool isSuccess =
          await _methodChannel.iOSNFCCaptureWithImageData(imageData);
      return isSuccess;
    } catch (err) {
      rethrow;
    }
  }

  Future<bool> startWithNviModel(NviModel nviModel) async {
    try {
      final bool isSuccess =
          await _methodChannel.iOSNFCCaptureWithNviData(nviModel);
      return isSuccess;
    } catch (err) {
      rethrow;
    }
  }

  Future<bool> startWithMRZCapture() async {
    try {
      final bool isSuccess = await _methodChannel.iosNFCCaptureWithMRZCapture();
      return isSuccess;
    } catch (err) {
      rethrow;
    }
  }

  /// Uploads the NFC data and returns `true` when the upload succeeds.
  ///
  /// Pass [onResult] to also receive the `documentId` of the document the
  /// upload created:
  ///
  /// ```dart
  /// final isSuccess = await nfcCapture.upload(
  ///   onResult: (isSuccess, documentId) {
  ///     print('Upload finished: $isSuccess, documentId: $documentId');
  ///   },
  /// );
  /// ```
  Future<bool> upload({UploadResultCallback? onResult}) async {
    if (onResult == null) {
      return await _methodChannel.iosUploadNFCCapture();
    }
    final response = await _methodChannel.iosUploadNFCCaptureWithDocumentId();
    return _methodChannel.deliverUploadResult(response, onResult);
  }

  Future<void> setType(String type) async {
    await _methodChannel.iosSetNFCType(type);
  }
}
