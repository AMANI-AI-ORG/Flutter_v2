import 'package:flutter/material.dart';
import 'package:flutter_amanisdk/amani_sdk.dart';
import 'package:flutter_amanisdk/common/models/android/auto_selfie_settings.dart';
import 'package:flutter_amanisdk/common/models/android/pose_estimation_settings.dart';
import 'package:flutter_amanisdk/common/models/ios/auto_selfie_settings.dart';
import 'package:flutter_amanisdk/common/models/ios/pose_estimation_settings.dart';
import 'package:flutter_amanisdk_example/qr/amani_qr_session.dart';

class BioLogin extends StatefulWidget {
  const BioLogin({Key? key}) : super(key: key);

  @override
  State<BioLogin> createState() => _BioLoginState();
}

class _BioLoginState extends State<BioLogin> {
  final _bioLogin = AmaniSDK().getBioLogin();
  String _customerID = "";

  String _status = "";
  bool _hasCapture = false;

  // Uses the server URL and token of the session started from the QR code.
  Future<void> initBioLogin() async {
    final accessData = AmaniQrSession.lastAccessData;
    if (accessData == null) {
      setState(() => _status = "Önce ana ekrandan QR kodu okutun.");
      return;
    }
    try {
      await _bioLogin.init(
          server: accessData.serverUrl,
          token: accessData.accessToken,
          customerId: _customerID,
          attemptId: "1");
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = "BioLogin başlatılamadı: $e");
    }
  }

  // Keeps the capture result so the upload button can be enabled.
  Future<void> _onCaptured(Future<dynamic> capture) async {
    try {
      await capture;
      if (!mounted) return;
      setState(() {
        _hasCapture = true;
        _status = "Selfie alındı, yüklemeye hazır.";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = "Hata: $e");
    }
  }

  Future<void> _upload() async {
    setState(() => _status = "Yükleniyor...");
    try {
      String? uploadedDocumentId;
      final isUploaded = await _bioLogin.upload(
        onResult: (isSuccess, documentId) {
          debugPrint("BioLogin upload: $isSuccess, documentId: $documentId");
          uploadedDocumentId = documentId;
        },
      );
      if (!mounted) return;
      setState(() => _status = isUploaded
          ? "Yükleme başarılı. documentId: $uploadedDocumentId"
          : "Yükleme başarısız.");
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = "Hata: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    initBioLogin();
  }

  final AndroidPoseEstimationSettings _androidPoseEstimationSettings =
      AndroidPoseEstimationSettings(
    poseCount: 3,
    animationDuration: 500,
    faceNotInside: "Your face is not inside the area",
    faceNotStraight: "Your face is not straight",
    faceIsTooFar: "Your face is too far",
    holdPhoneVertically: "Please hold stable",
    alertTitle: "Verification Failed",
    alertDescription: "Failed 1",
    alertTryAgain: "Try again",
    turnRight: "→",
    turnLeft: "←",
    turnUp: "↑",
    turnDown: "↓",
    lookStraight: "Look straight",
    mainGuideVisibility: true,
    secondaryGuideVisibility: true,
  );

  final IOSPoseEstimationSettings _iosPoseEstimationSettings =
      IOSPoseEstimationSettings(
    faceIsOk: "Please hold stable",
    notInArea: "Please align your face to the area",
    faceTooSmall: "Your face is in too far",
    faceTooBig: "Your face is in too close",
    completed: "Verification Completed",
    turnRight: "→",
    turnLeft: "←",
    turnUp: "↑",
    turnDown: "↓",
    lookStraight: "Look straight",
    errorMessage:
        "Please complete the steps while your face is aligned to the area",
    tryAgain: "Try again",
    errorTitle: "Verification Failure",
    confirm: "Confirm",
    next: "Next",
    holdPhoneVertically: "Please hold the phone straight",
    informationScreenDesc1:
        "To start verification, align your face with the area",
    informationScreenDesc2: "",
    informationScreenTitle: "Selfie Verification Instructions",
    wrongPose: "Your face must be straight",
    descriptionHeader:
        "Please make sure you are doing the correct pose and your face is aligned with the area",
    appBackgroundColor: "000000",
    appFontColor: "ffffff",
    primaryButtonBackgroundColor: "ffffff",
    primaryButtonTextColor: "000000",
    ovalBorderColor: "ffffff",
    ovalBorderSuccessColor: "00ff00",
    poseCount: "3",
    mainGuideVisibility: "true",
    secondaryGuideVisibility: "true",
    buttonRadious: "10",
    manualCropTimeout: 30,
  );

  final IOSAutoSelfieSettings _iOSAutoSelfieSettings = IOSAutoSelfieSettings(
      faceIsOk: "Please hold stable",
      notInArea: "Please align your face with the area",
      faceTooSmall: "Your face is in too far",
      faceTooBig: "Your face is in too close",
      completed: "All OK!",
      appBackgroundColor: "000000",
      appFontColor: "ffffff",
      primaryButtonBackgroundColor: "ffffff",
      ovalBorderSuccessColor: "00ff00",
      ovalBorderColor: "ffffff",
      countTimer: "3",
      manualCropTimeout: 30);

  final AndroidAutoSelfieSettings _androidAutoSelfieSettings =
      AndroidAutoSelfieSettings(
          textSize: 16,
          counterVisible: true,
          counterTextSize: 21,
          manualCropTimeout: 30,
          distanceText: "Please align your face with the area",
          faceNotFoundText: "No faces found",
          restartText: "Process failed, restarting...",
          stableText: "Please hold stable");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(backgroundColor: Colors.red, title: const Text("BioLogin")),
      body: Center(
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                  labelText: "Customer ID", border: UnderlineInputBorder()),
              onChanged: (customerID) {
                setState(() {
                  _customerID = customerID;
                });
              },
            ),
            OutlinedButton(
                onPressed: () {
                  _onCaptured(_bioLogin.startWithAutoSelfie(
                      iosAutoSelfieSettings: _iOSAutoSelfieSettings,
                      androidAutoSelfieSettings: _androidAutoSelfieSettings));
                },
                child: const Text("Start AutoSelfie BioLogin")),
            OutlinedButton(
                onPressed: () {
                  _onCaptured(_bioLogin.iOSStartWithPoseEstimation(
                      settings: _iosPoseEstimationSettings));
                },
                child: const Text("Start PoseEstimation BioLogin")),
            OutlinedButton(
                onPressed: () {
                  _bioLogin.androidStartWithPoseEstimation(
                      settings: _androidPoseEstimationSettings,
                      onSuccessCallback: (imageData) {
                        setState(() {
                          _hasCapture = true;
                          _status = "Selfie alındı, yüklemeye hazır.";
                        });
                      },
                      onFailureCallback: (failureParams) {
                        print(failureParams["reason"] +
                            failureParams["currentAttempt"]);
                      });
                },
                child: const Text("Start PoseEstimation BioLogin (Android)")),
            OutlinedButton(
                onPressed: () {
                  _onCaptured(_bioLogin.startWithManualSelfie(
                      androidSelfieDescriptionText: "Hi"));
                },
                child: const Text("Start Manual Selfie BioLogin")),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _hasCapture ? _upload : null,
                child: const Text("Upload")),
            const SizedBox(height: 12),
            Text(_status, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
