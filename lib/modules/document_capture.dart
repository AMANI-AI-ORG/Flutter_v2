import 'package:flutter_amanisdk/common/models/upload_result.dart';
import 'dart:typed_data';

import 'package:flutter_amanisdk/common/models/file_type.dart';
import 'package:flutter_amanisdk/flutter_amanisdk_method_channel.dart';

class DocumentCapture {
  final MethodChannelAmaniSDK _methodChannel;

  DocumentCapture(this._methodChannel);

  Future<Uint8List> start({int documentCount = 1}) async {
    if (documentCount < 0) {
      throw Exception(
          'Document count cannot be negative, are you sure you want to use this method?');
    }

    try {
      final imageData =
          await _methodChannel.startDocumentCaptureWithView(documentCount);
      if (imageData != null) {
        return imageData;
      } else {
        throw Exception('[AmaniSDK] No image returned from document capture');
      }
    } catch (err) {
      rethrow;
    }
  }

  /// Uploads the captured document, or the given [files] instead, and returns
  /// `true` when the upload succeeds. Pass `null` as [files] to upload the
  /// captured document.
  ///
  /// Pass [onResult] to also receive the `documentId` of the document the
  /// upload created:
  ///
  /// ```dart
  /// final isSuccess = await documentCapture.startUploadWithFiles(
  ///   null,
  ///   onResult: (isSuccess, documentId) {
  ///     print('Upload finished: $isSuccess, documentId: $documentId');
  ///   },
  /// );
  /// ```
  Future<bool> startUploadWithFiles(List<FileTypeModel>? files,
      {UploadResultCallback? onResult}) async {
    final fileList = files?.map((element) => element.toMap()).toList();
    if (onResult == null) {
      final uploadState = await _methodChannel.documentCaptureUpload(fileList);
      return uploadState == true;
    }
    final response =
        await _methodChannel.documentCaptureUploadWithDocumentId(fileList);
    return _methodChannel.deliverUploadResult(response, onResult);
  }

  Future<void> setType(String type) async {
    try {
      await _methodChannel.documentCaptureSetType(type);
    } catch (err) {
      rethrow;
    }
  }

  Future<bool> androidBackButtonHandler() async {
    try {
      final res = await _methodChannel.androidDocumentCaptureBackPressHandle();
      return res;
    } catch (err) {
      rethrow;
    }
  }
}
