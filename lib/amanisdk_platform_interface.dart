import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_amanisdk/common/models/android/auto_selfie_settings.dart';
import 'package:flutter_amanisdk/common/models/android/pose_estimation_settings.dart';
import 'package:flutter_amanisdk/common/models/ios/auto_selfie_settings.dart';
import 'package:flutter_amanisdk/common/models/ios/pose_estimation_settings.dart';
import 'package:flutter_amanisdk/common/models/nvi_data.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter_amanisdk/common/models/speech_verifier_settings.dart';
import 'flutter_amanisdk_method_channel.dart';

abstract class AmaniSDKPlatform extends PlatformInterface {
  /// Constructs a [AmaniSDKPlatform]
  AmaniSDKPlatform() : super(token: _token);

  static final Object _token = Object();

  static AmaniSDKPlatform _instance = MethodChannelAmaniSDK();

  /// The default instance of [AmaniSDKPlatform] to use.
  ///
  /// Defaults to [MethodChannelAmaniSDK].
  static AmaniSDKPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AmaniSDKPlatform] when
  /// they register themselves.
  static set instance(AmaniSDKPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  final methodChannel = const MethodChannel('amanisdk');

   Future<void> setConfigure({
    required String server,
    required List<String> enabledFeatures,
    String? sharedSecret,
    String uploadSource = "KYC"
  }) {
    throw UnimplementedError('configure() has not been implemented.');
  }

  Future<bool?> startAmaniSDKWithConfigure(
    String token,
    String id,
    String? birthDate,
    String? expireDate,
    String? documentNo,
    bool geoLocation,
    String? language,
    String? email,
    String? phone,
    String? name,
  ) {
    throw UnimplementedError(
      'startAmaniSDKConfigurable() has not been implemented.',
    );
  }

  Future<bool> initAmani({
    /// server url
    required String server,

    /// customer token acquired from our rest api
    required String customerToken,

    /// customers id card number or any random string, must match with
    /// the id supplied while creating the [customerToken] field
    required String customerIdCardNumber,

    /// Sets if location info must be supplied while uploading the document
    required bool useLocation,

    /// Language parameters
    required String lang,

    /// ApiVersion
    required String apiVersion,

    /// Optional shared secret
    String? sharedSecret,
  }) {
    throw UnimplementedError('initAmani() has not been implemented.');
  }

  // IDCapture
  Future<dynamic> startIDCapture(int stepID) {
    throw UnimplementedError('startIDCapture() has not been implemented.');
  }

  Future<bool> iOSStartIDCaptureNFC(Map<String, dynamic> mrzResult) async {
    throw UnimplementedError(
        'iOSStartIDCaptureNFC() has not been implemented.');
  }
  

  Future<void> androidSetUsesNFC(bool usesNFC) {
    throw UnimplementedError('androidSetUsesNFC() has not been implemented.');
  }

  Future<bool> uploadIDCapture() {
    throw UnimplementedError('uploadIDCapture() has not been implemented.');
  }

  Future<Map<String, dynamic>> uploadIDCaptureWithDocumentId() {
    throw UnimplementedError(
        'uploadIDCaptureWithDocumentId() has not been implemented.');
  }

  Future<void> setIDCaptureManualButtonTimeout(int timeout) {
    throw UnimplementedError(
        'setIDCaptureManualButtonTimeout() has not been implemented.');
  }

  Future<void> setIDCaptureType(String type) {
    throw UnimplementedError('setIDCaptureType() has not been implemented.');
  }

  Future<void> setIDCaptureVideoRecording(bool enabled) {
    throw UnimplementedError(
        'setIDCaptureVideoRecording() has not been implemented.');
  }

  Future<void> setIDCaptureHologramDetection(bool enabled) {
    throw UnimplementedError(
        'setIDCaptureHologramDetection() has not been implemented.');
  }

  /// Use this function to handle the back press.
  /// returns false to use on WillPopScope
  Future<bool> androidIDCaptureBackPressHandle() {
    throw UnimplementedError(
        'androidIDCaptureBackPressHandle() has not been implemented.');
  }

  // Selfie
  Future<dynamic> startSelfie() {
    throw UnimplementedError('startSelfie() has not been implemented.');
  }

  Future<bool> uploadSelfie() {
    throw UnimplementedError('startSelfie() has not been implemented.');
  }

  Future<void> setSelfieType(String type) {
    throw UnimplementedError('setSelfieType() has not been implemented.');
  }

  Future<bool> androidSelfieBackPressHandle() {
    throw UnimplementedError(
        'androidSelfieBackPressHandle() has not been implemented.');
  }

  // AutoSelfie
  Future<dynamic> startAutoSelfie({
    required IOSAutoSelfieSettings iosSettings,
    required AndroidAutoSelfieSettings androidSettings,
  }) {
    throw UnimplementedError('startAutoSelfie() has not been implemented.');
  }

  Future<bool> uploadAutoSelfie() {
    throw UnimplementedError('setSelfieType() has not been implemented.');
  }

  Future<void> setAutoSelfieType({required String type}) {
    throw UnimplementedError('setAutoSelfieType() has not been implemented.');
  }

  Future<bool> androidAutoSelfieBackPressHandle() {
    throw UnimplementedError(
        'androidAutoSelfieBackPressHandle() has not been implemented.');
  }

  // PoseEstimation
  Future<dynamic> startPoseEstimation(
      {required AndroidPoseEstimationSettings androidPoseEstimationSettings,
      required IOSPoseEstimationSettings iosPoseEstimationSettings}) {
    throw UnimplementedError('startPoseEstimation() has not been implemented.');
  }

  Future<bool> uploadPoseEstimation() {
    throw UnimplementedError('uploadAutoSelfie() has not been implemented');
  }

  Future<void> setPoseEstimationType(String type) {
    throw UnimplementedError(
        'setPoseEstimationType() has not been implemented');
  }

  Future<void> setPoseEstimationVideoRecording(bool enabled) {
    throw UnimplementedError(
        'setPoseEstimationVideoRecording() has not been implemented');
  }

  Future<bool> androidPoseEstimationBackPressHandle() {
    throw UnimplementedError(
        'androidPoseEstimationBackPressHandle() has not been implemented.');
  }

  // Speech Verifier

  Future<dynamic> startSpeechVerifier({
    String? iosSettings,
    String? androidSettings,
  }) {
    throw UnimplementedError('startSpeechVerifier() has not been implemented.');
  }

  Future<bool> uploadSpeechVerifier() {
    throw UnimplementedError(
        'uploadSpeechVerifier() has not been implemented.');
  }

  Future<bool> androidSpeechVerifierBackPressHandle() {
    throw UnimplementedError(
        'androidSpeechVerifierBackPressHandle() has not been implemented.');
  }

  // IOS NFC Capture
  Future<bool> iOSNFCCaptureWithImageData(Uint8List imageData) {
    throw UnimplementedError(
        'iosNFCCaptureWithImageData() has not been implemented.');
  }

  Future<bool> iOSNFCCaptureWithNviData(NviModel nviModel) {
    throw UnimplementedError(
        'iosNFCCaptureWithNviData() has not been implemented.');
  }

  Future<bool> iosNFCCaptureWithMRZCapture() {
    throw UnimplementedError(
        'iosNFCCaptureWithMRZCapture() has not been implemented.');
  }

  Future<bool> iosUploadNFCCapture() {
    throw UnimplementedError('iosUploadNFCCapture() has not been implemented.');
  }

  Future<void> iosSetNFCType(String type) {
    throw UnimplementedError('iosSetNFCType() has not been implemented.');
  }

  // Android NFC Capture
  Future<void> androidStartNFCListener(
      {String? birthDate, String? expireDate, String? documentNo}) {
    throw UnimplementedError(
        'androidStartNFCListener() has not been implemented.');
  }

  Future<void> androidDisableNFCListener() {
    throw UnimplementedError(
        'androidDisableNFCListener() has not been implemented.');
  }

  Future<void> androidSetNFCType(String type) {
    throw UnimplementedError('androidSetNFCType() has not been implemented.');
  }

  Future<bool> androidUploadNFC() {
    throw UnimplementedError('androidUploadNFC() has not been implemented.');
  }

  // BioLogin
  Future<void> initBioLogin(
      {required String server,
      required String token,
      required String customerId,
      required String attemptId,
      int? source,
      int? comparisonAdapter,
      String? sharedSecret}) {
    throw UnimplementedError('initBioLogin() has not been implemented.');
  }

  Future<dynamic> startBioLoginWithAutoSelfie(
      {required IOSAutoSelfieSettings iosSettings,
      required AndroidAutoSelfieSettings androidSettings}) {
    throw UnimplementedError(
        'startBioLoginWithAutoSelfie() has not been implemented.');
  }

  Future<dynamic> iOSStartBioLoginWithPoseEstimation(
      {required IOSPoseEstimationSettings settings}) {
    throw UnimplementedError(
        'iOSStartBioLoginWithPoseEstimation() has not been implemented.');
  }

  Future<dynamic> androidStartBioLoginWithPoseEstimation(
      {required AndroidPoseEstimationSettings settings}) {
    throw UnimplementedError(
        "androidStartBioLoginWithPoseEstimation() has not been implemented.");
  }

  Future<dynamic> startBioLoginWithManualSelfie(
      {required String androidSelfieDescriptionText}) {
    throw UnimplementedError(
        'startBioLoginWithManualSelfie() has not been implemented.');
  }

  Future<bool> uploadBioLogin() {
    throw UnimplementedError('uploadBioLogin() has not been implemented.');
  }

  Future<bool> androidBioLoginBackPressHandle() {
    throw UnimplementedError(
        'androidBioLoginBackPressHandle() has not been implemented.');
  }

  Future<Uint8List?> startDocumentCaptureWithView(int documentCount) {
    throw UnimplementedError(
        'startDocumentCaptureWithView() has not been implemented.');
  }

  Future<void> documentCaptureSetType(String type) {
    throw UnimplementedError(
        'documentCaptureSetType() has not been implemented.');
  }

  Future<bool> documentCaptureUpload(List<Map<String, dynamic>>? files) {
    throw UnimplementedError('upload() has not been implemented.');
  }

  Future<bool> androidDocumentCaptureBackPressHandle() {
    throw UnimplementedError(
        'androidDocumentCaptureBackPressHandle() has not been implemented.');
  }

  Future<dynamic> getCustomerInfo() {
    throw UnimplementedError("getCustomerInfo() has not been implemented.");
  }

  /// **WARNING** Do not use this for production. This is only intented for quick
  /// debugging and testing purposes
  Future<bool> initAmaniWithEmail({
    required String server,
    required String email,
    required String password,
    required String customerIdCardNumber,
    required bool useLocation,
    required String lang,
    required String apiVersion,
    String? sharedSecret,
  }) {
    throw UnimplementedError('initAmaniWithEmail() has not been implemented.');
  }
}
