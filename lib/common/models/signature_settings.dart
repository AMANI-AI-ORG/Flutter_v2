/// Settings for the signature screen shown by [Signature.start].
class SignatureSettings {
  /// How many signatures the customer is asked for. Must be at least 1.
  final int count;

  /// Text shown at the top of the signature screen.
  final String title;

  /// Label of the button that clears the current signature.
  final String clearButtonText;

  /// Label of the button that confirms the current signature.
  final String confirmButtonText;

  /// Button color as a hex string, for example `#1E88E5`.
  final String? buttonColor;

  const SignatureSettings({
    this.count = 1,
    this.title = 'Please sign in the area below',
    this.clearButtonText = 'Clear',
    this.confirmButtonText = 'Confirm',
    this.buttonColor,
  }) : assert(count >= 1, 'count must be at least 1');

  Map<String, dynamic> toMap() => {
        'count': count,
        'title': title,
        'clearButtonText': clearButtonText,
        'confirmButtonText': confirmButtonText,
        if (buttonColor != null) 'buttonColor': buttonColor,
      };
}
