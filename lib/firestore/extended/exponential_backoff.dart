part of '../models.dart';

class ExponentialBackoff {
  Duration _nextBackoff = Duration(seconds: 2);

  Future<void> backoffAndWait() async {
    final backoff = _nextBackoff;
    _nextBackoff *= 2;
    await Future.delayed(backoff);
  }
}
