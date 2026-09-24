import 'package:flutter/material.dart';
import 'package:flutter_amanisdk/amani_sdk.dart';
import 'package:flutter_amanisdk/common/models/speech_verifier_settings.dart';
import 'package:flutter_amanisdk/modules/speech_verifier.dart';

class SpeechVerifierScreen extends StatefulWidget {
  const SpeechVerifierScreen({Key? key}) : super(key: key);

  @override
  State<SpeechVerifierScreen> createState() => _SpeechVerifierScreenState();
}

class _SpeechVerifierScreenState extends State<SpeechVerifierScreen> {
  final SpeechVerifier _module = AmaniSDK().getSpeechVerifier();
  String? _status;

  // Shared step definition, reused for both platforms.
  List<SpeechVerifierStepConfiguration> get _steps => [
        SpeechVerifierStepConfiguration.identityQuestion(const [
          SpeechVerifierIdentityQuestionConfiguration(
            type: SpeechVerifierIdentityQuestionType.idNumber,
            matchThresholdPercent: 75,
          ),
        ]),
      ];

  static const _answers = SpeechVerifierIdentityAnswers(
    idNumber: "22180378472",
  );

  Future<void> _start() async {
    try {
      await _module.start(
        iosSettings: SpeechVerifierSettings(
          type: "XXX_ST_0",
          videoRecording: true,
          timeoutSeconds: 30,
          steps: _steps,
          identityAnswers: _answers,
          appearance: const SpeechVerifierAppearanceSettings(
            highlightedTextColor: "#34C759",
          ),
        ),
        androidSettings: AndroidSpeechVerifierSettings(
          type: "",
          serverURL: "",
          token:
              "",
          steps: _steps,
          identityAnswers: _answers,
          matchThresholdPercent: 75,
        ),
      );

      final isUploaded =
          await _module.upload(onResult: (isSuccess, documentId) {
        debugPrint(
            "SpeechVerifier upload: $isSuccess, documentId: $documentId");
      });
      final uploaded = isUploaded;
      if (!mounted) return;
      setState(() => _status = uploaded ? "Upload succeeded" : "Upload failed");
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text('Speech Verifier'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_status != null) Text(_status!),
            OutlinedButton(
              onPressed: _start,
              child: const Text("Start"),
            ),
          ],
        ),
      ),
    );
  }
}
