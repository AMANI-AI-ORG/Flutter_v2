import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_amanisdk/amani_sdk.dart';
import 'package:flutter_amanisdk/common/models/nvi_data.dart';
import 'package:flutter_amanisdk/modules/id_capture.dart';
import 'package:flutter_amanisdk_example/screens/nfc_confirm.dart';
import 'package:flutter_amanisdk_example/screens/nfc_scan_screen.dart';

class ConfirmArguments {
  final String source;
  final Uint8List imageData;
  final bool? idCaptureBothSidesTaken;
  final bool? idCaptureNFCCompleted;

  ConfirmArguments(
      {required this.source,
      required this.imageData,
      this.idCaptureBothSidesTaken,
      this.idCaptureNFCCompleted});
}

class ConfirmScreenState extends StatefulWidget {
  const ConfirmScreenState({super.key});
  static const routeName = '/confirm';

  @override
  State<ConfirmScreenState> createState() => _ConfirmScreen();
}

class _ConfirmScreen extends State<ConfirmScreenState> {
  final _idCapture = AmaniSDK().getIDCapture();
  final _autoSelfie = AmaniSDK().getAutoSelfie();
  final _selfie = AmaniSDK().getSelfie();
  final _poseEstimation = AmaniSDK().getPoseEstimation();
  final _documentCapture = AmaniSDK().getDocumentCapture();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  // Uploads both ID sides directly, skipping the NFC step.
  Future<void> _uploadIdWithoutNfc() async {
    setState(() => _isLoading = true);
    // An earlier NFC flow may have switched the SDK to NFC mode; turn it off.
    await _idCapture.setAndroidUsesNFC(false);
    final isUploaded =
        await _idCapture.upload(onResult: (isSuccess, documentId) {
      debugPrint(
          "IDCapture upload (no NFC): $isSuccess, documentId: $documentId");
    });
    if (!mounted) return;
    if (isUploaded) {
      Navigator.pushReplacementNamed(context, '/');
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as ConfirmArguments;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text("Confirm Document?"),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.memory(
                  args.imageData,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: 450,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                        onPressed: (() => Navigator.pop(context)),
                        child: const Text("Try again!")),
                    OutlinedButton(
                        onPressed: (() async {
                          setState(() {
                            _isLoading = true;
                          });
                          if (args.source == "idCapture" &&
                              args.idCaptureBothSidesTaken == true &&
                              args.idCaptureNFCCompleted == true) {
                            final isUploaded = await _idCapture.upload(
                                onResult: (isSuccess, documentId) {
                              debugPrint(
                                  "IDCapture upload: $isSuccess, documentId: $documentId");
                            });
                            if (isUploaded) {
                              Navigator.pushReplacementNamed(context, '/');
                            }
                          } else if (args.source == "idCapture" &&
                              args.idCaptureBothSidesTaken == true &&
                              args.idCaptureNFCCompleted == false) {
                            if (Platform.isIOS) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const NFCScanScreen()),
                              );
                            } else if (Platform.isAndroid) {
                              Navigator.pushNamed(
                                  context, NFCConfrimScreen.routeName);
                            }
                          } else if (args.source == "idCapture" &&
                              args.idCaptureBothSidesTaken == false) {
                            var imageData = await _idCapture.start(IdSide.back);
                            Navigator.pushNamed(
                                context, ConfirmScreenState.routeName,
                                arguments: ConfirmArguments(
                                    source: "idCapture",
                                    imageData: imageData,
                                    idCaptureBothSidesTaken: true,
                                    idCaptureNFCCompleted: false));
                          } else if (args.source == "selfie") {
                            final isUploaded = await _selfie.upload(
                                onResult: (isSuccess, documentId) {
                              debugPrint(
                                  "Selfie upload: $isSuccess, documentId: $documentId");
                            });
                            if (isUploaded) {
                              Navigator.pushReplacementNamed(context, '/');
                            }
                          } else if (args.source == "autoSelfie") {
                            final isUploaded = await _autoSelfie.upload(
                                onResult: (isSuccess, documentId) {
                              debugPrint(
                                  "AutoSelfie upload: $isSuccess, documentId: $documentId");
                            });
                            if (isUploaded) {
                              Navigator.pushReplacementNamed(context, '/');
                            }
                          } else if (args.source == "poseEstimation") {
                            final isUploaded = await _poseEstimation.upload(
                                onResult: (isSuccess, documentId) {
                              debugPrint(
                                  "PoseEstimation upload: $isSuccess, documentId: $documentId");
                            });
                            if (isUploaded) {
                              Navigator.pushReplacementNamed(context, '/');
                            }
                          } else if (args.source == "documentCapture") {
                            final isUploaded = await _documentCapture
                                .startUploadWithFiles(null,
                                    onResult: (isSuccess, documentId) {
                              debugPrint(
                                  "DocumentCapture upload: $isSuccess, documentId: $documentId");
                            });
                            if (isUploaded) {
                              Navigator.pushReplacementNamed(context, '/');
                            }
                          }
                        }),
                        child: const Text("Confirm"))
                  ],
                ),
                if (args.source == "idCapture" &&
                    args.idCaptureBothSidesTaken == true &&
                    args.idCaptureNFCCompleted == false)
                  OutlinedButton(
                      onPressed: _uploadIdWithoutNfc,
                      child: const Text("Upload without NFC")),
              ],
            ),
    );
  }
}
