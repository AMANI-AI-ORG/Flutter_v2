import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_amanisdk/amani_sdk.dart';
import 'package:flutter_amanisdk/common/models/signature_settings.dart';
import 'package:flutter_amanisdk/modules/signature.dart';

class SignatureScreen extends StatefulWidget {
  const SignatureScreen({Key? key}) : super(key: key);

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final Signature _signature = AmaniSDK().getSignature();

  int _count = 1;
  Uint8List? _image;
  String _status = "";
  bool _isBusy = false;
  bool _isSignatureOpen = false;

  Future<void> _start() async {
    setState(() {
      _isBusy = true;
      _status = "İmza bekleniyor...";
      _image = null;
      _isSignatureOpen = true;
    });
    try {
      final image = await _signature.start(
        settings: SignatureSettings(
          count: _count,
          title: "Lütfen aşağıdaki alana imzanızı atın",
          clearButtonText: "Temizle",
          confirmButtonText: "Onayla",
        ),
      );
      if (!mounted) return;
      setState(() {
        _image = image;
        _status = "İmza alındı, yüklemeye hazır.";
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _status = "Hata (${e.code}): ${e.message}");
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _isSignatureOpen = false;
        });
      }
    }
  }

  // Android: close the native signature screen instead of leaving this page.
  Future<bool> _onWillPop() async {
    if (Platform.isAndroid && _isSignatureOpen) {
      return await _signature.androidBackButtonHandle();
    }
    return true;
  }

  Future<void> _upload() async {
    setState(() {
      _isBusy = true;
      _status = "Yükleniyor...";
    });
    try {
      String? uploadedDocumentId;
      final isUploaded = await _signature.upload(
        onResult: (isSuccess, documentId) {
          debugPrint("Signature upload: $isSuccess, documentId: $documentId");
          uploadedDocumentId = documentId;
        },
      );
      if (!mounted) return;
      setState(() => _status = isUploaded
          ? "Yükleme başarılı. documentId: $uploadedDocumentId"
          : "Yükleme başarısız.");
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _status = "Hata (${e.code}): ${e.message}");
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: const Text('Signature')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text("İmza sayısı:"),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: _count,
                    items: const [1, 2, 3]
                        .map((n) =>
                            DropdownMenuItem(value: n, child: Text("$n")))
                        .toList(),
                    onChanged: _isBusy
                        ? null
                        : (value) => setState(() => _count = value ?? 1),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isBusy ? null : _start,
                child: const Text("İmza Al"),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _isBusy || _image == null ? null : _upload,
                child: const Text("Yükle"),
              ),
              const SizedBox(height: 16),
              Text(_status, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              if (_image != null)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12)),
                    child: Image.memory(_image!, fit: BoxFit.contain),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
