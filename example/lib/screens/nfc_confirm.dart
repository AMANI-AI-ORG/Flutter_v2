import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_amanisdk/amani_sdk.dart';

class NFCConfrimScreen extends StatefulWidget {
  const NFCConfrimScreen({super.key});
  static const routeName = '/confirm-nfc';

  @override
  State<NFCConfrimScreen> createState() => _NFCConfrimScreenState();
}

class _NFCConfrimScreenState extends State<NFCConfrimScreen> {
  bool _isCapturing = false;
  bool _uploadState = false;
  bool _errorState = false;
  bool _startState = false;
  bool _HasNfc = false;

  final _idCapture = AmaniSDK().getIDCapture();
  final _androidNFCCapture = AmaniSDK().getAndroidNFCCapture();

  @override
  void dispose() {
    if (Platform.isAndroid) {
      _androidNFCCapture.stopNFCListener();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text("Capture NFC"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text("Is Capturing: $_isCapturing"),
                Text("Nfc Caputred: $_HasNfc"),
                Text("Upload State: $_uploadState"),
                Text("Error State: $_errorState"),
                Text("Started State: $_startState"),
                OutlinedButton(
                    onPressed: () {
                      if (Platform.isAndroid) {
                        _idCapture.setAndroidUsesNFC(true).then((_) {
                          setState(() {
                            _isCapturing = true;
                          });
                          try {
                            _androidNFCCapture.startNFCListener(
                                onFinishedCallback: (isCaptureComplete) {
                              setState(() {
                                _isCapturing = false;
                                _HasNfc = isCaptureComplete;
                                _uploadState = true;
                              });
                              _idCapture.upload(
                                  onResult: (isSuccess, documentId) {
                                debugPrint(
                                    "IDCapture upload: $isSuccess, documentId: $documentId");
                              }).then((isUploaded) {
                                setState(() {
                                  _uploadState = isUploaded;
                                });
                                Navigator.pushReplacementNamed(context, '/');
                              });
                            }, onErrorCallback: (errorStr) {
                              print(errorStr);
                              setState(() {
                                _errorState = true;
                              });
                            }, onScanStart: () {
                              setState(() {
                                _startState = true;
                              });
                            });
                          } catch (e) {
                            print("MRZ Error?");
                            print(e.toString());
                          }
                        }); // set uses nfc
                      }
                    },
                    child: const Text("Start Capture"))
              ],
            )
          ],
        ),
      ),
    );
  }
}
