part of '../models.dart';

class _SplittedDocumentData {
  _SplittedDocumentData.split(Map<String, dynamic> data) {
    for (var entry in data.entries) {
      _insertField([], entry.key, entry.value);
    }
  }

  void _insertField(
      List<String> parentFields, String fieldName, dynamic value) {
    final fullFieldPath = parentFields.isNotEmpty
        ? '${parentFields.join('.')}.$fieldName'
        : fieldName;
    if (value is FieldValue) {
      // insert into field transforms
      fieldTransforms
          .removeWhere((element) => element.fieldPath == fullFieldPath);
      fieldTransforms.add(value._fieldTransform..fieldPath = fullFieldPath);
    } else {
      // insert into data
      var item = data;
      for (var field in parentFields) {
        item = item[field];
      }
      // handle nested map special case
      // we cannot support FieldValues within nested Maps inside of Arrays
      if (value is Map) {
        item[fieldName] = <String, dynamic>{};
        final newParentFields = List<String>.from(parentFields);
        newParentFields.add(fieldName);
        for (final entry in value.entries) {
          _insertField(newParentFields, entry.key, entry.value);
        }
      } else {
        item[fieldName] = value;
      }
    }
  }

  final Map<String, dynamic> data = {};
  final List<DocumentTransform_FieldTransform> fieldTransforms = [];
}

class WriteBatch {
  WriteBatch(this._gateway);

  FirestoreGateway _gateway;

  final List<_Op> _ops = <_Op>[];

  bool get isEmpty => _ops.isEmpty;

  void set(DocumentReference documentReference, Map<String, dynamic> data,
      [SetOptions? options]) {
    final splittedData = _SplittedDocumentData.split(data);

    final document = documentReference._encodeMap(splittedData.data)
      ..name = documentReference.fullPath;

    final documentTransform = DocumentTransform()
      ..document = documentReference.fullPath
      ..fieldTransforms.addAll(splittedData.fieldTransforms);

    final op = PendingWriteOp()..update = document;

    if (documentTransform.fieldTransforms.isNotEmpty) {
      op.transform = documentTransform;
    }

    if (options?.merge ?? false) {
      var mask = DocumentMask();
      document.fields.keys.forEach((key) => mask.fieldPaths.add(key));
      op.updateMask = mask;
    }

    _ops.add(_Op(docPath: documentReference.fullPath, op: op));
  }

  Future<void> commit([List<int>? transactionId]) async {
    final request = CommitRequest()
      ..database = _gateway.database
      ..writes.addAll(_ops.map((e) => e.op));

    if (transactionId != null) {
      request.transaction = transactionId;
    }

    await _gateway.client.commit(request);
  }

  void _reset() {
    _ops.clear();
  }
}

typedef PendingWriteOp = Write;

class _Op {
  _Op({required this.docPath, required this.op});

  final String docPath;
  final PendingWriteOp op;
}
