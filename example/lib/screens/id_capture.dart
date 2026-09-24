import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_amanisdk/amani_sdk.dart';
import 'package:flutter_amanisdk/modules/id_capture.dart';
import 'package:flutter_amanisdk_example/screens/confim.dart';

class IdCaptureScreen extends StatefulWidget {
  const IdCaptureScreen({Key? key}) : super(key: key);

  @override
  State<IdCaptureScreen> createState() => _IdCaptureScreenState();
}

class _IdCaptureScreenState extends State<IdCaptureScreen> {
  final IdCapture _idCaptureModule = AmaniSDK().getIDCapture();

  bool _sdkReady = false;
  String? _initError;
  
  get onWillPop => null;

  Future<void> initSDK() async {
    try {
      await _idCaptureModule.setType("TUR_ID_1");
      debugPrint("setType ok");

      await _idCaptureModule.setHologramDetection(false);
      debugPrint("setHologramDetection ok");

      await _idCaptureModule.setVideoRecording(true);
      debugPrint("setVideoRecording ok");

      await _idCaptureModule.setManualButtonTimeout(15);
      debugPrint("setManualButtonTimeout ok");

      if (mounted) {
        setState(() {
          _sdkReady = true;
        });
      }
    } catch (e, st) {
      debugPrint("initSDK error: $e");
      debugPrintStack(stackTrace: st);
      if (mounted) {
        setState(() {
          _initError = e.toString();
          _sdkReady = false;
        });
      }
    }
  }

 @override
  void initState() {
    super.initState();
    initSDK();
  }

  Future<void> _startCapture() async {
    if (!_sdkReady) return;

    try {
      final imageData = await _idCaptureModule.start(IdSide.front);
      if (!mounted) return;

      Navigator.pushNamed(
        context,
        ConfirmScreenState.routeName,
        arguments: ConfirmArguments(
          source: "idCapture",
          imageData: imageData,
          idCaptureBothSidesTaken: false,
          idCaptureNFCCompleted: false,
        ),
      );
    } catch (e, st) {
      debugPrint("startIDCapture error: $e");
      debugPrintStack(stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.purple,
          title: const Text('ID Capture Screen'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_initError != null) Text(_initError!),
              OutlinedButton(
                onPressed: _sdkReady ? _startCapture : null,
                child: Text(_sdkReady ? "Start" : "Preparing..."),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
  // Future<void> initSDK() async {
  //   await _idCaptureModule.setType("TUR_ID_1");
  //   await _idCaptureModule.setHologramDetection(false);
  //   await _idCaptureModule.setVideoRecording(true);
  //   await _idCaptureModule.setManualButtonTimeout(15);
  // }

//   @override
//   void initState() {
//     super.initState();
//     initSDK();
//   }

//   Future<bool> onWillPop() async {
//     if (Platform.isAndroid) {
//       try {
//         bool canPop = await _idCaptureModule.androidBackButtonHandle();
//         return canPop;
//       } catch (e) {
//         return true;
//       }
//     } else {
//       return true;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: onWillPop,
//       child: Scaffold(
//         appBar: AppBar(
//           backgroundColor: Colors.purple,
//           title: const Text('ID Capture Screen'),
//         ),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               OutlinedButton(
//                   onPressed: () {
//                     _idCaptureModule.start(IdSide.front).then((imageData) {
//                       Navigator.pushNamed(context, ConfirmScreenState.routeName,
//                           arguments: ConfirmArguments(
//                               source: "idCapture",
//                               imageData: imageData,
//                               idCaptureBothSidesTaken: false,
//                               idCaptureNFCCompleted: false));
//                     }).catchError((err) {});
//                   },
//                   child: const Text("Start")),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
