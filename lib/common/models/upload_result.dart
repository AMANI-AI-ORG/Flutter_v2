/// Completion of the `upload` methods of the SDK modules.
///
/// [isSuccess] is `true` when the upload succeeded. [documentId] is the id of
/// the document the upload created, or `null` when the upload failed.
typedef UploadResultCallback = void Function(bool isSuccess, String? documentId);
