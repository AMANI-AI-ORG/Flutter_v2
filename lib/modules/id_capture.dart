import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_amanisdk/common/models/id_upload_result.dart';
import 'package:flutter_amanisdk/common/models/nvi_data.dart';
import 'package:flutter_amanisdk/flutter_amanisdk_method_channel.dart';
import 'package:flutter/material.dart';

enum IdSide { front, back }



class IdCapture {
  final MethodChannelAmaniSDK _methodChannel;
  // final eventChannel = const EventChannel('amanisdk_event_channel');
  final eventChannel = const EventChannel('amanisdk_delegate_channel');
  
  IdCapture(this._methodChannel);
  Future<Uint8List> start(IdSide idSide) async {
    try {
      final dynamic imageData =
          await _methodChannel.startIDCapture(idSide.index);
      if (imageData != null) {
        return imageData as Uint8List;
      } else {
        throw Exception("[AmaniSDK] no image returned from idCapture module");
      }
    } catch (err) {
      rethrow;
    }
  }

  Future<bool> iosStartNFC(Map<String, dynamic> mrzResult) async {
    if (!Platform.isIOS) return false;
    if (mrzResult.isEmpty != true) {
 
     try {
      final bool isDone = await _methodChannel.iOSStartIDCaptureNFC(mrzResult);
      return isDone;
       } catch (err) {
      rethrow;
       }
      } else {
        return false;
      }
    }

    Future<Map<String, dynamic>> processNFC(String mrzResult) async {
        Map<String, dynamic> mrzData = {};
        try {
          // Parse the incoming string data using the helper function
          final eventData = _parseMrzData(mrzResult);
          mrzData.addAll(eventData);
          return mrzData;
        } catch (e) {
          print("[AmaniSDK] Failed to parse MRZ data: $e");
          return {};
        }
    }
     

  Future<void> setAndroidUsesNFC(bool usesNFC) async {
    if (Platform.isAndroid) {
      await _methodChannel.androidSetUsesNFC(usesNFC);
    }
  }

  Future<bool> upload() async {
    try {
      final bool isDone = await _methodChannel.uploadIDCapture();
      return isDone;
    } catch (err) {
      rethrow;
    }
  }

  /// Uploads the captured ID and also returns the created `documentId`.
  ///
  /// Currently the `documentId` is only provided on iOS. On other platforms
  /// this falls back to [upload] and `documentId` is always `null`.
  Future<IdUploadResult> uploadWithDocumentId() async {
    try {
      if (!Platform.isIOS) {
        final bool isDone = await _methodChannel.uploadIDCapture();
        return IdUploadResult(isSuccess: isDone, documentId: null);
      }
      final response = await _methodChannel.uploadIDCaptureWithDocumentId();
      return IdUploadResult.fromMap(response);
    } catch (err) {
      rethrow;
    }
  }


Future<String?> getMrzRequest() async {
  if (!Platform.isIOS) return null;
  try {
    final result =  await _methodChannel.getMrzRequest();
    return result;
  } catch (err) {
    rethrow;
  }
}

  Future<void> setType(String type) async {
    await _methodChannel.setIDCaptureType(type);
  }

  Future<void> setManualButtonTimeout(int time) async {
    await _methodChannel.setIDCaptureManualButtonTimeout(time);
  }

  Future<bool> androidBackButtonHandle() async {
    return await _methodChannel.androidIDCaptureBackPressHandle();
  }

  Future<void> setHologramDetection(bool enabled) async {
    return await _methodChannel.setIDCaptureHologramDetection(enabled);
  }

  Future<void> setVideoRecording(bool enabled) async {
    return await _methodChannel.setIDCaptureVideoRecording(enabled);
  }

 Map<String, dynamic> _parseMrzData(String data) {
  Map<String, dynamic> parsedData = {};

  // Regex to match both Optional and non-Optional values
  RegExp regex = RegExp(r'(\w+):\s*(Optional\("?(.*?)"?\)|"(.*?)"|(\S+))');
  Iterable<RegExpMatch> matches = regex.allMatches(data);

  for (var match in matches) {
    String key = match.group(1)!;
    String value = match.group(3) ?? match.group(4) ?? match.group(5) ?? '';

    // Add value to parsedData regardless of Optional
    parsedData[key] = value.isNotEmpty && value != 'nil' ? value : null;
  }

  return parsedData;
}

 
}


 
      
    