import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Argument validation shared by the public API, so bad input fails fast in Dart
/// before it reaches the native bridges.
class AmaniInputValidation {
  const AmaniInputValidation._();

  /// Validates [server] and returns its normalized origin (scheme + host + port).
  ///
  /// KYC credentials and documents must not travel over cleartext HTTP, so only
  /// `https` is accepted. `http` is tolerated in debug builds for local test servers.
  /// A bare host without a scheme is treated as `https://<host>`.
  ///
  /// Throws [ArgumentError] when the value is not acceptable.
  static String normalizeServer(String server) {
    final trimmed = server.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(server, 'server', 'must not be empty');
    }

    final Uri? uri = Uri.tryParse(trimmed.contains('://') ? trimmed : 'https://$trimmed');
    if (uri == null || uri.host.isEmpty) {
      throw ArgumentError.value(server, 'server', 'is not a valid URL');
    }

    final scheme = uri.scheme.toLowerCase();
    final isAllowed = scheme == 'https' || (kDebugMode && scheme == 'http');
    if (!isAllowed) {
      throw ArgumentError.value(
          server, 'server', 'must use https (plain http is only allowed in debug builds)');
    }
    return uri.normalizePath().origin;
  }

  /// A [sharedSecret] is optional, but when it is given it must carry content.
  static void checkSharedSecret(String? sharedSecret) {
    if (sharedSecret != null && sharedSecret.trim().isEmpty) {
      throw ArgumentError.value(
          '<redacted>', 'sharedSecret', 'must not be empty when provided');
    }
  }

  /// Decodes the payload of a JWT without verifying it. Returns null when [token]
  /// is not a well-formed JWT (malformed base64 or JSON must not crash the caller).
  ///
  /// The signature is checked by the server; this is only a client side sanity check.
  static Map<String, dynamic>? decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      return payload is Map<String, dynamic> ? payload : null;
    } on FormatException {
      return null;
    }
  }
}
