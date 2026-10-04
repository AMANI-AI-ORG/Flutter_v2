import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_amanisdk/amaniAndroidConfigure.dart';
import 'package:flutter_amanisdk/amani_sdk.dart';
import 'package:flutter_amanisdk/common/models/api_version.dart';

/// Values read from an Amani verification QR code.
class QrSessionInfo {
  final String pid;
  final String serverUrl;

  const QrSessionInfo({required this.pid, required this.serverUrl});

  @override
  String toString() => 'QrSessionInfo(pid: $pid, serverUrl: $serverUrl)';
}

/// Response of `GET {serverUrl}/api/v2/profile/url?pid={pid}`.
class UserAccessData {
  final String accessToken;
  final String serverUrl;
  final String? language;
  final String? company;

  const UserAccessData({
    required this.accessToken,
    required this.serverUrl,
    this.language,
    this.company,
  });

  factory UserAccessData.fromJson(Map<String, dynamic> json) {
    final token = json['access_token'];
    final server = json['server_url'];
    if (token is! String ||
        token.isEmpty ||
        server is! String ||
        server.isEmpty) {
      throw const FormatException(
          'access_token or server_url is missing in the response');
    }
    return UserAccessData(
      accessToken: token,
      serverUrl: server,
      language: json['language'] as String?,
      company: json['company'] as String?,
    );
  }
}

/// Example-only flow: QR code -> pid + server URL -> access token -> SDK init.
///
/// Mirrors the native Amani Verify app, without the BioLogin and video call flows.
class AmaniQrSession {
  AmaniQrSession._();

  /// Whether the SDK was initialized in this app run. Kept static so the home
  /// screen does not ask for a new QR code every time it is rebuilt.
  static bool isStarted = false;

  /// Reads the pid and server URL from the scanned QR payload.
  ///
  /// The pid comes from the `pid` query parameter. The server URL comes from a
  /// `server_url` / `serverUrl` / `server` / `base_url` / `baseUrl` query
  /// parameter, or falls back to the origin of an http(s) QR link.
  /// Returns `null` when the payload is not an Amani verification QR code.
  static QrSessionInfo? parse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;

    final query = uri.queryParameters;
    final pid = query['pid'] ?? query['PID'];
    if (pid == null || pid.isEmpty) return null;

    String? server;
    for (final key in const [
      'server_url',
      'serverUrl',
      'server',
      'base_url',
      'baseUrl'
    ]) {
      final value = query[key];
      if (value != null && value.isNotEmpty) {
        server = value;
        break;
      }
    }
    if (server == null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      server = uri.origin;
    }
    if (server == null) return null;

    final serverUri =
        Uri.tryParse(server.contains('://') ? server : 'https://$server');
    if (serverUri == null || serverUri.host.isEmpty) return null;

    return QrSessionInfo(pid: pid, serverUrl: serverUri.origin);
  }

  /// Exchanges the pid for an access token.
  static Future<UserAccessData> fetchAccessData(QrSessionInfo info) async {
    final url = Uri.parse('${info.serverUrl}/api/v2/profile/url')
        .replace(queryParameters: {'pid': info.pid});

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.getUrl(url);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw HttpException(
            'Access token request failed (${response.statusCode}): $body',
            uri: url);
      }
      return UserAccessData.fromJson(jsonDecode(body) as Map<String, dynamic>);
    } finally {
      client.close();
    }
  }

  /// Initializes the SDK with the access token.
  ///
  /// With a v2 profile token the Core SDK identifies the customer from the
  /// token, but the bridge still requires a non-empty id, so the token's
  /// `profile_id` is passed as the id.
  static Future<bool> start(UserAccessData data, {String? language}) async {
    final lang = language ?? data.language ?? 'tr';
    final id = _profileIdFromToken(data.accessToken) ?? 'qr-session';
    final sdk = AmaniSDK();

    bool isSuccess;
    if (Platform.isAndroid) {
      await sdk.setConfigure(
        server: data.serverUrl,
        enabledFeatures: const [
          AmaniAndroidDynamicFeature.idCapture,
          AmaniAndroidDynamicFeature.idHologramDetection,
          AmaniAndroidDynamicFeature.nfcScan,
          AmaniAndroidDynamicFeature.selfieAuto,
          AmaniAndroidDynamicFeature.selfiePoseEstimation,
        ],
      );
      final result = await sdk.startAmaniSDKWithConfigure(
        token: data.accessToken,
        id: id,
        geoLocation: true,
        lang: lang,
      );
      if (result.isTokenExpired) {
        debugPrint('[QR] access token has already expired');
      }
      isSuccess = result.isSessionStarted;
    } else {
      isSuccess = await sdk.initAmani(
        server: data.serverUrl,
        customerToken: data.accessToken,
        customerIdCardNumber: id,
        useLocation: true,
        apiVersion: AmaniApiVersion.v2,
        lang: lang,
      );
    }

    isStarted = isSuccess;
    debugPrint(
        '[QR] SDK init finished: $isSuccess (server: ${data.serverUrl}, lang: $lang)');
    return isSuccess;
  }

  static String? _profileIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final profileId = payload is Map ? payload['profile_id'] : null;
      return profileId is String && profileId.isNotEmpty ? profileId : null;
    } catch (_) {
      return null;
    }
  }
}
