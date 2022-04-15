part of '../models.dart';

class FieldValue {
  FieldValue._(this._fieldTransform);

  final DocumentTransform_FieldTransform _fieldTransform;

  factory FieldValue.serverTimestamp() {
    final fieldTransform = DocumentTransform_FieldTransform()
      ..setToServerValue =
          DocumentTransform_FieldTransform_ServerValue.REQUEST_TIME;
    return FieldValue._(fieldTransform);
  }

  factory FieldValue.arrayUnion(List<dynamic> elements) {
    final fieldTransform = DocumentTransform_FieldTransform()
      ..appendMissingElements =
          ArrayValue(values: elements.map(TypeUtil.encode));
    return FieldValue._(fieldTransform);
  }

  factory FieldValue.arrayRemove(List<dynamic> elements) {
    final fieldTransform = DocumentTransform_FieldTransform()
      ..removeAllFromArray = ArrayValue(values: elements.map(TypeUtil.encode));
    return FieldValue._(fieldTransform);
  }
}
