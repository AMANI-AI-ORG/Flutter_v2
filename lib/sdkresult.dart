class SdkResult {
  bool isVerificationCompleted;
  bool isTokenExpired;

  /// Due to differences in our iOS SDK this field always will be *nil* on iOS.
  /// Use it with Platform Check.
  ///
  /// On Android 1000 is the default value.
  int? apiExceptionCode;

  /// This field indicates there is an network error that should show up an
  /// error popup on your applications side
  bool? networkError;

  /// This List will be filled if user canceled the KYC process,
  /// or failed the verification
  Map<String, dynamic>? rules;

  /// `true` when [AmaniSDK.startAmaniSDKWithConfigure] started the SDK session.
  bool isSessionStarted;

  SdkResult(this.isVerificationCompleted, this.isTokenExpired,
      this.apiExceptionCode, this.networkError, this.rules,
      {this.isSessionStarted = false});

  factory SdkResult.fromJson(dynamic json) {
    return SdkResult(
        json['isVerificationCompleted'] ?? false,
        json['isTokenExpired'] ?? false,
        json['apiExceptionCode'] as int?,
        json['networkError'] ?? false,
        json['rules'],
        isSessionStarted: json['isSessionStarted'] ?? false);
  }
}
