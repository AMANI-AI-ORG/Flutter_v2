// ignore_for_file: file_names
// File name is part of the public import path (see README); do not rename.


enum AmaniAndroidDynamicFeature {
  idCapture,
  idHologramDetection,
  nfcScan,
  selfieAuto,
  selfiePoseEstimation,
}

enum AmaniUploadSource { kyc, video, password }

extension AmaniUploadSourceExtension on AmaniUploadSource {
  String get getUploadSourceString {
    switch (this) {
      case AmaniUploadSource.kyc:
        return "KYC";
      case AmaniUploadSource.video:
        return "VIDEO";
      case AmaniUploadSource.password:
        return "PASSWORD";
    }
  }
}