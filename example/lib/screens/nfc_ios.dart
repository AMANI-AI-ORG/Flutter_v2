import 'package:flutter/material.dart';
import 'package:flutter_amanisdk/amani_sdk.dart';
import 'package:flutter_amanisdk/common/models/nvi_data.dart';
import 'package:flutter_amanisdk/modules/id_capture.dart';

class IOSNFC extends StatefulWidget {
  const IOSNFC({Key? key}) : super(key: key);

  @override
  State<IOSNFC> createState() => IOSNFCState();
}

class IOSNFCState extends State<IOSNFC> {
  final _nfcCapture = AmaniSDK().getIOSNFCCapture();
  final _idCapture = AmaniSDK().getIDCapture();
  bool _isCompleted = false;

  String _dateOfBirth = "";
  String _documentNo = "";
  String _expireDate = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("IOS NFC Capture $_isCompleted"),
        backgroundColor: Colors.deepOrange,
      ),
      body: Center(
        child: Column(
          children: [
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
                            .startWithNviModel(NviModel(
                                _documentNo, _dateOfBirth, _expireDate))
                            .then((isDone) {
                          setState(() {
                            _isCompleted = isDone;
                          });
                        });
                      }
                    },
                    child:
                        const Text("NVI Data Start (fields must be filled)")),
                OutlinedButton(
                    onPressed: () {
                      _nfcCapture.startWithMRZCapture().then((isCompleted) {
                        setState(() {
                          _isCompleted = isCompleted;
                        });
                      });
                    },
                    child: const Text("MRZ Capture Start")),
                OutlinedButton(
                    onPressed: () {
                      _idCapture.start(IdSide.back).then((imageData) {
                        _nfcCapture
                            .startWithImageData(imageData)
                            .then((isDone) => setState(() {
                                  _isCompleted = isDone;
                                }));
                      });
                    },
                    child: const Text("Image Data Start (opens idCapture")),
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
