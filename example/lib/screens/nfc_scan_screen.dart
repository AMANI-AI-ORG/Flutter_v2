import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_amanisdk/amani_sdk.dart';
import 'package:flutter_amanisdk/common/models/nvi_data.dart';
import 'package:flutter_amanisdk/modules/id_capture.dart';

class NFCScanScreen extends StatefulWidget {
  const NFCScanScreen({Key? key}) : super(key: key);

  @override
  State<NFCScanScreen> createState() => _NFCScanScreenState();
}

class _NFCScanScreenState extends State<NFCScanScreen> {
  StreamSubscription<dynamic>? _eventSubscription;

  final _amani = AmaniSDK();
  late final _idCapture = _amani.getIDCapture();

  String? _mrzDocumentId;
  String? _mrzRawPayload;
  Map<String, dynamic> mrzResult = {};

  // UI state
  String _error = "";
  bool _isFetchingMrz = false;
  bool _isStartingNfc = false;

  bool get _isMrzReady => (mrzResult.isNotEmpty);

  @override
  void initState() {
    super.initState();
    // Only listen for the MRZ delegate here; the MRZ request is sent on button tap.
    _startListeningForMrzEvents();
  }

  Future<void> _onTapMainButton() async {
    if (_isMrzReady) {
      await _onTapStartNFC();
    } else {
      await _startMrzRequest();
    }
  }

  void _startListeningForMrzEvents() {
    _eventSubscription?.cancel();
    _eventSubscription = _amani.getDelegateStream().listen(
      (event) {
        if (event is! Map) return;

        final type = event['type'];
        final data = event['data'];

        if (type == 'mrzInfoDelegate') {
          _handleMrzInfoDelegate(data);
          return;
        }

        if (type == 'error') {
          final msg = _extractErrorMessage(data);
          if (!mounted) return;
          setState(() {
            _error = "Hata: $msg";
            _isFetchingMrz = false; // spinner dursun
          });
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _error = "EventStream hatası: $error";
          _isFetchingMrz = false;
        });
      },
    );
  }

  Future<void> _startMrzRequest() async {
    if (!mounted || _isFetchingMrz) return;
    setState(() {
      _error = "";
      _isFetchingMrz = true;
      _mrzRawPayload = null;
      mrzResult = {};
      _mrzDocumentId = null;
    });

    try {
      final documentId = await _idCapture.getMrzRequest();
      if (!mounted) return;

      setState(() {
        _mrzDocumentId = documentId;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "MRZ isteği başarısız: $e";
        _isFetchingMrz = false;
      });
    }
  }

  Future<void> _handleMrzInfoDelegate(dynamic data) async {
    String? raw;
    Map<String, dynamic>? directMap;

    if (data is String) {
      raw = data;
    } else if (data is Map) {
      directMap = Map<String, dynamic>.from(data as Map);
    } else if (data != null) {
      raw = data.toString();
    }

    Map<String, dynamic> parsed = {};

    try {
      if (directMap != null) {
        parsed = directMap;
      } else if (raw != null && raw.isNotEmpty) {
        _mrzRawPayload = raw;
        parsed = await _idCapture.processNFC(raw);
      }
    } catch (e) {
      parsed = {};
      if (!mounted) return;
      setState(() {
        _error = "MRZ verisi ayrıştırılamadı: $e";
      });
    }

    if (!mounted) return;
    setState(() {
      mrzResult = parsed;
      _error = "";

      _isFetchingMrz = false;
    });
  }

  String _extractErrorMessage(dynamic data) {
    if (data is Map) {
      return (data['error_message'] ?? data.toString()).toString();
    }
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        return decoded.toString();
      } catch (_) {
        return data;
      }
    }
    return data?.toString() ?? "Unknown error";
  }

  Future<void> _onTapStartNFC() async {
    if (_isStartingNfc) return;

    if (mrzResult.isEmpty) {
      setState(() => _error = "MRZ verisi henüz gelmedi. Lütfen bekleyin.");
      return;
    }

    setState(() {
      _error = "";
      _isStartingNfc = true;
    });

    try {
      if (mrzResult.isEmpty &&
          _mrzRawPayload != null &&
          _mrzRawPayload!.isNotEmpty) {
        final parsed = await _idCapture.processNFC(_mrzRawPayload!);
        if (mounted) {
          setState(() => mrzResult = parsed);
        }
      }

      final bool isDone = await _idCapture.iosStartNFC(mrzResult);

      if (!mounted) return;

      if (!isDone) {
        setState(() {
          _isStartingNfc = false;
          _error = "NFC başlatılamadı. (DocId/MRZ kontrol edin)";
        });
        return;
      }

      final isUploaded =
          await _idCapture.upload(onResult: (isSuccess, documentId) {
        debugPrint("IDCapture upload: $isSuccess, documentId: $documentId");
      });
      final bool isSuccess = isUploaded;

      if (!mounted) return;

      setState(() {
        _isStartingNfc = false;
      });

      if (isSuccess) {
        Navigator.pushReplacementNamed(context, '/');
      } else {
        setState(() {
          _error = "Upload başarısız.";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isStartingNfc = false;
        _error = "Başlatma hatası: $e";
      });
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool buttonEnabled = !_isStartingNfc && !_isFetchingMrz;
    final String buttonLabel = _isFetchingMrz
        ? "MRZ Bekleniyor..."
        : (_isMrzReady ? "NFC Taramasını Başlat" : "MRZ Bilgisini Al");

    return Scaffold(
      appBar: AppBar(title: const Text('NFC Tarama')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              children: [
                Center(
                  child: Text(
                    _isMrzReady
                        ? 'NFC sürecini başlatmak için butona basınız'
                        : 'MRZ bilgisini almak için butona basınız',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _error,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),

          // Button
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
              onPressed: buttonEnabled ? _onTapMainButton : null,
              child: _isStartingNfc
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(buttonLabel),
            ),
          ),

          if (_isFetchingMrz)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text(
                          "MRZ verisi alınıyor...",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
