import 'package:flutter_amanisdk/common/models/upload_result.dart';
import 'package:flutter/services.dart';
import 'package:flutter_amanisdk/flutter_amanisdk_method_channel.dart';

class AndroidNFCCapture {
  final MethodChannelAmaniSDK _methodChannel;
  final nfcChannel = const MethodChannel('amanisdk_nfc_channel');
  Function(bool)? _onFinishedCallback;
  Function(String)? _onErrorCallback;
  Function()? _onScanStart;

  AndroidNFCCapture(this._methodChannel);

  Future<bool> startNFCListener(
      {String? birthDate,
      String? expireDate,
      String? documentNo,

      /// Returns true if the capture is successfull
      required Function(bool) onFinishedCallback,

      /// Returns the error message from the card read error
      required Function(String) onErrorCallback,

      /// This runs once the user scan is started
      required Function() onScanStart}) {
    _onFinishedCallback = onFinishedCallback;
    _onErrorCallback = onErrorCallback;
    _onScanStart = onScanStart;
    nfcChannel.setMethodCallHandler(_handleInverseChannel);
    return _methodChannel.androidStartNFCListener(
        birthDate: birthDate, expireDate: expireDate, documentNo: documentNo);
  }

  Future<void> _handleInverseChannel(MethodCall call) async {
    final args = Map.from(call.arguments);
    switch (call.method) {
      case 'onNFCCompleted':
        if (_onFinishedCallback != null) {
          _onFinishedCallback!(args["isSuccess"]);
        }
        break;
      case 'onError':
        // While the NFC listener is active, the user can try
        // scanning the nfc multiple times, thus this callback
        // can be invoked multiple time
        if (_onErrorCallback != null) {
          _onErrorCallback!(args["message"]);
        }
        break;
      case 'onScanStart':
        if (_onScanStart != null) {
          _onScanStart!();
        }
        break;
    }
  }

  // Run this whenever you destroy your widget e.g deactivate / dispose
  Future<void> stopNFCListener() async {
    try {
      await _methodChannel.androidDisableNFCListener();
    } catch (err) {
      rethrow;
    }
  }

  Future<void> setType(String type) async {
    await _methodChannel.androidSetNFCType(type);
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
      return await _methodChannel.androidUploadNFC();
    }
    final response = await _methodChannel.androidUploadNFCWithDocumentId();
    return _methodChannel.deliverUploadResult(response, onResult);
  }

}
