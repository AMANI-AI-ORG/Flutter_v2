import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_amanisdk/amani_sdk.dart';
import 'package:flutter_amanisdk/common/models/file_type.dart';
import 'package:flutter_amanisdk/modules/document_capture.dart';
import 'package:flutter_amanisdk_example/screens/confim.dart';
import 'package:file_picker/file_picker.dart';

class DocumentCaputureScreen extends StatefulWidget {
  const DocumentCaputureScreen({super.key});

  @override
  State<DocumentCaputureScreen> createState() => _DocumentCaputureScreenState();
}

class _DocumentCaputureScreenState extends State<DocumentCaputureScreen> {
  void _pickFile() async {
    // opens storage to pick files and the picked file or files
    // are assigned into result and if no file is chosen result is null.
    // you can also toggle "allowMultiple" true or false depending on your need
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);

    // if no file is picked
    if (result == null) return;

    final fileConvertUint8List =
        await File(result.files.first.path!).readAsBytes();
    // final mineType = lookupMimeType(result.files.first.path!);
    FileTypeModel documentFile =
        FileTypeModel(data: fileConvertUint8List, dataType: "application/pdf");
    _documentCaptureModule.startUploadWithFiles([documentFile],
        onResult: (isSuccess, documentId) {
      debugPrint("DocumentCapture upload: $isSuccess, documentId: $documentId");
    }).then((isUploaded) {
      Navigator.pushNamed(context, "/");
    }).catchError((err) {});
  }

  final DocumentCapture _documentCaptureModule =
      AmaniSDK().getDocumentCapture();

  Future<void> initSDK() async {
    await _documentCaptureModule.setType("TUR_IB_0");
  }

  @override
  void initState() {
    super.initState();
    initSDK();
  }

  Future<bool> onWillPop() async {
    if (Platform.isAndroid) {
      try {
        bool canPop = await _documentCaptureModule.androidBackButtonHandler();
        return canPop;
      } catch (e) {
        return true;
      }
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.blueAccent,
            title: const Text("Document Capture Screen")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                  onPressed: () {
                    _documentCaptureModule.start().then((image) {
                      Navigator.pushNamed(context, ConfirmScreenState.routeName,
                          arguments: ConfirmArguments(
                              source: "documentCapture",
                              imageData: image,
                              idCaptureBothSidesTaken: false,
                              idCaptureNFCCompleted: false));
                    }).catchError((err) {});
                  },
                  child: const Text("Start")),
              OutlinedButton(
                  onPressed: () {
                    _pickFile();
                  },
                  child: const Text("Upload Document"))
            ],
          ),
        ),
      ),
    );
  }
}
