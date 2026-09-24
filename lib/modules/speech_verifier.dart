import 'package:flutter_amanisdk/common/models/upload_result.dart';
import 'dart:typed_data';

import 'package:flutter_amanisdk/common/models/speech_verifier_settings.dart';
import 'package:flutter_amanisdk/flutter_amanisdk_method_channel.dart';

class SpeechVerifier {
  final MethodChannelAmaniSDK _methodChannel;

  SpeechVerifier(this._methodChannel);

  /// Starts the speech verifier flow. Returns the captured evidence image
  /// (black frame) as bytes when the flow completes successfully, mirroring
  /// the other capture modules.
  Future<Uint8List?> start({
    SpeechVerifierSettings? iosSettings,
    AndroidSpeechVerifierSettings? androidSettings,
  }) async {
    try {
      final dynamic result = await _methodChannel.startSpeechVerifier(
        iosSettings: iosSettings?.toJson(),
        androidSettings: androidSettings?.toJson(),
      );
      return result as Uint8List?;
    } catch (err) {
      rethrow;
    }
  }

  /// Uploads the speech verification and returns `true` when the upload succeeds.
  ///
  /// Pass [onResult] to also receive the `documentId` of the document the
  /// upload created:
  ///
  /// ```dart
  /// final isSuccess = await speechVerifier.upload(
  ///   onResult: (isSuccess, documentId) {
  ///     print('Upload finished: $isSuccess, documentId: $documentId');
  ///   },
  /// );
  /// ```
  Future<bool> upload({UploadResultCallback? onResult}) async {
    if (onResult == null) {
      return await _methodChannel.uploadSpeechVerifier();
    }
    final response = await _methodChannel.uploadSpeechVerifierWithDocumentId();
    return _methodChannel.deliverUploadResult(response, onResult);
  }

  Future<bool> androidBackButtonHandle() async {
    return await _methodChannel.androidSpeechVerifierBackPressHandle();
  }
}