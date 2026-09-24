import 'package:flutter_amanisdk/common/models/upload_result.dart';
import 'dart:typed_data';
import 'package:flutter_amanisdk/common/models/android/pose_estimation_settings.dart';
import 'package:flutter_amanisdk/common/models/ios/pose_estimation_settings.dart';
import 'package:flutter_amanisdk/flutter_amanisdk_method_channel.dart';

class PoseEstimation {
  final MethodChannelAmaniSDK _methodChannel;

  PoseEstimation(this._methodChannel);

  Future<Uint8List> start(
      {required IOSPoseEstimationSettings iosSettings,
      required AndroidPoseEstimationSettings androidSettings}) async {
    try {
      final dynamic imageData = await _methodChannel.startPoseEstimation(
          iosPoseEstimationSettings: iosSettings,
          androidPoseEstimationSettings: androidSettings);
      if (imageData != null) {
        return imageData as Uint8List;
      } else {
        throw Exception(
            "[AmaniSDK] no image returned from poseEstimation module");
      }
    } catch (err) {
      rethrow;
    }
  }

  /// Uploads the pose estimation images and returns `true` when the upload succeeds.
  ///
  /// Pass [onResult] to also receive the `documentId` of the document the
  /// upload created:
  ///
  /// ```dart
  /// final isSuccess = await poseEstimation.upload(
  ///   onResult: (isSuccess, documentId) {
  ///     print('Upload finished: $isSuccess, documentId: $documentId');
  ///   },
  /// );
  /// ```
  Future<bool> upload({UploadResultCallback? onResult}) async {
    if (onResult == null) {
      return await _methodChannel.uploadPoseEstimation();
    }
    final response = await _methodChannel.uploadPoseEstimationWithDocumentId();
    return _methodChannel.deliverUploadResult(response, onResult);
  }

  Future<void> setType(String type) async {
    await _methodChannel.setPoseEstimationType(type);
  }

  Future<bool> androidBackButtonHandle() async {
    return await _methodChannel.androidPoseEstimationBackPressHandle();
  }

  Future<void> setVideoRecording(bool enabled) async {
    await _methodChannel.setPoseEstimationVideoRecording(enabled);
  }
}
