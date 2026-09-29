import 'package:flutter/material.dart';
import 'package:flutter_amanisdk_example/qr/amani_qr_session.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Scans an Amani verification QR code and pops with its [QrSessionInfo].
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  static const routeName = '/qr-scanner';

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isHandled = false;
  String? _error;

  void _onDetect(BarcodeCapture capture) {
    if (_isHandled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;

      final info = AmaniQrSession.parse(raw);
      if (info == null) {
        setState(() => _error = "Bu QR kodu bir Amani doğrulama kodu değil.");
        continue;
      }

      _isHandled = true;
      debugPrint('[QR] scanned $info');
      _controller.stop();
      Navigator.pop(context, info);
      return;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Kodu Tara')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "Kamera açılamadı: ${error.errorCode.name}",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.all(16),
              child: Text(
                _error ?? "Doğrulamayı başlatmak için QR kodu okutun.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
