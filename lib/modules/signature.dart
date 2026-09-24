import 'dart:typed_data';

import 'package:flutter_amanisdk/common/models/signature_settings.dart';
import 'package:flutter_amanisdk/common/models/upload_result.dart';
import 'package:flutter_amanisdk/flutter_amanisdk_method_channel.dart';

/// Signature module.
class Signature {
  final MethodChannelAmaniSDK _methodChannel;

  Signature(this._methodChannel);

  /// Opens the signature screen and returns the last confirmed signature as
  /// PNG bytes once all [SignatureSettings.count] signatures are confirmed.
  ///
  /// Throws a [PlatformException] with code `30053` when the customer closes
  /// the screen before finishing.
  Future<Uint8List> start({SignatureSettings settings = const SignatureSettings()}) async {
    final dynamic imageData = await _methodChannel.startSignature(settings.toMap());
    if (imageData == null) {
      throw Exception("[AmaniSDK] no image returned from signature module");
    }
    return imageData as Uint8List;
  }

  /// Uploads the confirmed signatures and returns `true` when the upload succeeds.
  ///
  /// Pass [onResult] to also receive the `documentId` of the document the
  /// upload created:
  ///
  /// ```dart
  /// final isSuccess = await signature.upload(
  ///   onResult: (isSuccess, documentId) {
  ///     print('Upload finished: $isSuccess, documentId: $documentId');
  ///   },
  /// );
  /// ```
  Future<bool> upload({UploadResultCallback? onResult}) async {
    if (onResult == null) {
      return await _methodChannel.uploadSignature();
    }
    final response = await _methodChannel.uploadSignatureWithDocumentId();
    return _methodChannel.deliverUploadResult(response, onResult);
  }

  /// Android only: call from `WillPopScope.onWillPop` while the signature
  /// screen is open. Closes the screen and returns `false`.
  Future<bool> androidBackButtonHandle() async {
    return await _methodChannel.androidSignatureBackPressHandle();
  }
}
