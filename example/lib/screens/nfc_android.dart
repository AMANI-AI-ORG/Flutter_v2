import 'package:flutter/material.dart';
import 'package:flutter_amanisdk/amani_sdk.dart';
import 'package:flutter_amanisdk/modules/nfc_capture_android.dart';

class AndroidNFC extends StatefulWidget {
  const AndroidNFC({Key? key}) : super(key: key);

  @override
  State<AndroidNFC> createState() => AndroidNFCState();
}

class AndroidNFCState extends State<AndroidNFC> {
  bool _isCompleted = false;
  final AndroidNFCCapture _nfcCapture = AmaniSDK().getAndroidNFCCapture();

  String _dateOfBirth = "";
  String _documentNo = "";
  String _expireDate = "";

  Future<void> stopNFCListener() async {
    _nfcCapture.stopNFCListener();
  }

  Future<void> setNFCType() async {
    _nfcCapture.setType("XXX_NF_0");
  }

  @override
  void initState() {
    setNFCType();
    super.initState();
  }

  @override
  void dispose() {
    stopNFCListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Android NFC Capture"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Center(
        child: Column(
          children: [
            Text("is nfc captured: $_isCompleted"),
            Column(children: [
              TextField(
                decoration: const InputDecoration(
                    labelText: "Date of Birth", border: UnderlineInputBorder()),
                onChanged: (dateOfBirth) {
                  setState(() {
                    _dateOfBirth = dateOfBirth;
                  });
                },
              ),
              TextField(
                decoration: const InputDecoration(
                    labelText: "Document No", border: UnderlineInputBorder()),
                onChanged: (documentNo) {
                  setState(() {
                    _documentNo = documentNo;
                  });
                },
              ),
              TextField(
                decoration: const InputDecoration(
                    labelText: "Expire Date", border: UnderlineInputBorder()),
                onChanged: (expireDate) {
                  setState(() {
                    _expireDate = expireDate;
                  });
                },
              ),
            ]),
            Column(
              children: [
                OutlinedButton(
                    onPressed: () {
                      if (_dateOfBirth != "" &&
                          _expireDate != "" &&
                          _documentNo != "") {
                        _nfcCapture
                            .startNFCListener(
                                birthDate: _dateOfBirth,
                                expireDate: _expireDate,
                                documentNo: _documentNo,
                                onFinishedCallback: (isCaptureCompleted) {
                                  setState(() {
                                    _isCompleted = isCaptureCompleted;
                                  });
                                },
                                onErrorCallback: (errorStr) {
                                  print("ON ERROR");
                                  print(errorStr);
                                  print(errorStr);
                                  print(errorStr);
                                  print(errorStr);
                                  print(errorStr);
                                  print(errorStr);
                                  print("ON ERROR");
                                  print("ON ERROR");
                                  print("ON ERROR");
                                  print("ON ERROR");
                                },
                                onScanStart: () {
                                  print("SCAN STARTED");
                                  print("SCAN STARTED");
                                  print("SCAN STARTED");
                                  print("SCAN STARTED");
                                  print("SCAN STARTED");
                                  print("SCAN STARTED");
                                })
                            .then((value) {
                          // This is where the NFC Listener is active
                          // For card found event
                        });
                      }
                    },
                    child:
                        const Text("NVI Data Start (fields must be filled)")),
                OutlinedButton(
                    onPressed: () {
                      if (_isCompleted == false) {
                        return;
                      } else {
                        _nfcCapture.upload(onResult: (isSuccess, documentId) {
                          debugPrint(
                              "NFC upload: $isSuccess, documentId: $documentId");
                        }).then((isUploaded) {});
                      }
                    },
                    child: const Text("Upload (last step)"))
              ],
            )
          ],
        ),
      ),
    );
  }
}
