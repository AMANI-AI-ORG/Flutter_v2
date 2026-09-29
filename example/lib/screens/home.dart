import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_amanisdk/amani_sdk.dart';
import 'package:flutter_amanisdk_example/qr/amani_qr_session.dart';
import 'package:flutter_amanisdk_example/screens/qr_scanner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Listen to SDK delegate events once per app run, not on every rebuild of home.
  static StreamSubscription<dynamic>? _delegateSubscription;

  bool _isStarting = false;
  String _status = AmaniQrSession.isStarted
      ? "SDK hazır."
      : "Doğrulamayı başlatmak için QR kodu okutun.";

  @override
  void initState() {
    super.initState();
    _delegateSubscription ??= AmaniSDK().getDelegateStream().listen((event) {
      debugPrint("delegate event recieved");
      debugPrint("$event");
    });
  }

  Future<void> _scanAndStart() async {
    final info = await Navigator.push<QrSessionInfo>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (info == null || !mounted) return;

    setState(() {
      _isStarting = true;
      _status = "Oturum başlatılıyor...";
    });
    try {
      final accessData = await AmaniQrSession.fetchAccessData(info);
      final isSuccess = await AmaniQrSession.start(accessData);
      if (!mounted) return;
      setState(() => _status = isSuccess
          ? "SDK hazır."
          : "SDK başlatılamadı. QR kodu tekrar okutun.");
    } catch (e) {
      debugPrint("[QR] session start failed: $e");
      if (!mounted) return;
      setState(() => _status = "Hata: $e");
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Widget _moduleButton(String title, String route) {
    return OutlinedButton(
      onPressed: AmaniQrSession.isStarted
          ? () => Navigator.pushNamed(context, route)
          : null,
      child: Text(title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.blue,
            title: const Text('Amani Flutter SDK Demo')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_status, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isStarting ? null : _scanAndStart,
                    icon: _isStarting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.qr_code_scanner),
                    label: Text(AmaniQrSession.isStarted
                        ? "Yeni QR Kodu Tara"
                        : "QR Kodu Tara"),
                  ),
                  const SizedBox(height: 24),
                  _moduleButton('ID Capture', '/id-capture'),
                  _moduleButton('Selfie', '/selfie'),
                  _moduleButton('Auto Selfie', '/auto-selfie'),
                  _moduleButton('Pose Estimation', '/pose-estimation'),
                  _moduleButton('NFC', '/nfc'),
                  _moduleButton('Speech Verifier', '/speech-verifier'),
                  _moduleButton('Signature', '/signature'),
                  _moduleButton('BioLogin', '/bio-login'),
                  _moduleButton('Document Capture', '/document-capture'),
                ]),
          ),
        ));
  }
}
