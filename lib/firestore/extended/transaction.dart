part of '../models.dart';

class Transaction {
  Transaction(this._gateway) : _writeBatch = WriteBatch(_gateway);

  final FirestoreGateway _gateway;
  final WriteBatch _writeBatch;
  final ExponentialBackoff _backoff = ExponentialBackoff();
  late List<int> _transactionId;

  Future<Document> get(DocumentReference documentReference) async {
    if (!_writeBatch.isEmpty) {
      throw Exception('READ_AFTER_WRITE_ERROR_MSG');
    }

    return _gateway.getDocument(documentReference.fullPath, _transactionId);
  }

  Transaction set(
      DocumentReference documentReference, Map<String, dynamic> data,
      [SetOptions? options]) {
    _writeBatch.set(documentReference, data, options);
    return this;
  }

  Future<void> begin() async {
    final transactionOptions = TransactionOptions();
    final beginTransactionRequest = BeginTransactionRequest()
      ..database = _gateway.database
      ..options = transactionOptions;

    final beginTransactionResponse =
        await _gateway.client.beginTransaction(beginTransactionRequest);
    _transactionId = beginTransactionResponse.transaction;
  }

  Future<void> commit() async {
    await _writeBatch.commit();
  }

  Future<void> rollback() async {
    final request = RollbackRequest()
      ..database = _gateway.database
      ..transaction = _transactionId;
    await _gateway.client.rollback(request);
  }

  Future<T> runTransaction<T>(
      Future<T> Function(Transaction) transactionHandler) async {
    _writeBatch._reset();
    await begin();
    final result = await transactionHandler(this);
    await commit();
    return result;
  }

  Future<void> maybeBackoff() async {
    await _backoff.backoffAndWait();
  }
}
