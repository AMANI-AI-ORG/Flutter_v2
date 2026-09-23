/// Result of [IdCapture.uploadWithDocumentId].
class IdUploadResult {
  /// Whether the upload request succeeded.
  final bool isSuccess;

  /// The id of the document created by the upload.
  /// `null` when the upload failed, or on platforms that do not provide it yet.
  final String? documentId;

  const IdUploadResult({required this.isSuccess, this.documentId});

  factory IdUploadResult.fromMap(Map<String, dynamic> map) {
    final dynamic documentId = map['documentId'];
    return IdUploadResult(
      isSuccess: map['isSuccess'] == true,
      documentId: documentId is String && documentId.isNotEmpty ? documentId : null,
    );
  }

  @override
  String toString() =>
      'IdUploadResult(isSuccess: $isSuccess, documentId: $documentId)';
}
