import 'package:flutter/material.dart';
import 'package:flutter_amanisdk_example/screens/auto_selfie.dart';
import 'package:flutter_amanisdk_example/screens/biologin.dart';
import 'package:flutter_amanisdk_example/screens/confim.dart';
import 'package:flutter_amanisdk_example/screens/document_capture.dart';
import 'package:flutter_amanisdk_example/screens/home.dart';
import 'package:flutter_amanisdk_example/screens/id_capture.dart';
import 'package:flutter_amanisdk_example/screens/nfc_android.dart';
import 'package:flutter_amanisdk_example/screens/nfc_confirm.dart';
import 'package:flutter_amanisdk_example/screens/nfc_home.dart';
import 'package:flutter_amanisdk_example/screens/nfc_ios.dart';
import 'package:flutter_amanisdk_example/screens/nfc_scan_screen.dart';
import 'package:flutter_amanisdk_example/screens/pose_estimation.dart';
import 'package:flutter_amanisdk_example/screens/selfie.dart';
import 'package:flutter_amanisdk_example/screens/signature.dart';
import 'package:flutter_amanisdk_example/screens/speech_verifier.dart';

void main() {
  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (ctx) => const HomeScreen(),
      '/id-capture': (ctx) => const IdCaptureScreen(),
      '/confirm': (ctx) => ConfirmScreenState(),
      '/selfie': (ctx) => const SelfieScreen(),
      '/auto-selfie': (ctx) => const AutoSelfieScreen(),
      '/pose-estimation': (ctx) => const PoseEstimationScreen(),
      '/nfc': (ctx) => const NFCHome(),
      '/nfc-ios': (ctx) => const IOSNFC(),
      '/nfc-android': (ctx) => const AndroidNFC(),
      '/bio-login': (ctx) => const BioLogin(),
      '/confirm-nfc': (ctx) => const NFCConfrimScreen(),
      '/document-capture': (ctx) => const DocumentCaputureScreen(),
      '/nfc-scan-screen': (ctx) => const NFCScanScreen(),
      '/speech-verifier': (ctx) => const SpeechVerifierScreen(),
      '/signature': (ctx) => const SignatureScreen(),
    },
  ));
}
