import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// A failure that is safe to show to a user.
///
/// Everything thrown out of the data layer is normalised into one of these by
/// [AppFailure.from], so presentation code never has to know whether the
/// underlying problem came from PostgREST, GoTrue, storage, or the socket. Each
/// variant carries a Kurdish [message]; [cause] and [stackTrace] are retained
/// for logging but are never rendered.
sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  /// Whether retrying the same operation could plausibly succeed.
  bool get isRetryable => switch (this) {
    NetworkFailure() => true,
    UnknownFailure() => true,
    AuthFailure() => false,
    PermissionFailure() => false,
    NotFoundFailure() => false,
    ValidationFailure() => false,
    ConfigurationFailure() => false,
  };

  /// Normalises any thrown object into an [AppFailure].
  ///
  /// Already-typed failures pass through untouched so that specific messages
  /// raised by the repositories survive the trip to the UI.
  factory AppFailure.from(Object error, [StackTrace? stackTrace]) {
    if (error is AppFailure) return error;

    if (error is SocketException || error is TimeoutException) {
      return NetworkFailure(cause: error, stackTrace: stackTrace);
    }

    if (error is AuthException) {
      return AuthFailure(
        message: 'چوونەژوورەوە سەرکەوتوو نەبوو، تکایە دووبارە هەوڵبدەرەوە',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is StorageException) {
      return UnknownFailure(
        message: 'بارکردنی وێنە سەرکەوتوو نەبوو',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is PostgrestException) {
      return _fromPostgrest(error, stackTrace);
    }

    return UnknownFailure(cause: error, stackTrace: stackTrace);
  }

  static AppFailure _fromPostgrest(
    PostgrestException error,
    StackTrace? stackTrace,
  ) {
    // PostgREST reports RLS denials as 401/403, and `.single()` with no rows as
    // PGRST116. Anything else is surfaced generically rather than leaking the
    // raw database message to the user.
    final status = error.code;
    if (status == '42501' || status == '401' || status == '403') {
      return PermissionFailure(cause: error, stackTrace: stackTrace);
    }
    if (status == 'PGRST116' || status == '404') {
      return NotFoundFailure(cause: error, stackTrace: stackTrace);
    }
    if (status == '23505') {
      return ValidationFailure(
        'ئەم تۆمارە پێشتر هەیە',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    return UnknownFailure(cause: error, stackTrace: stackTrace);
  }

  @override
  String toString() => '$runtimeType: $message';
}

/// The device is offline, or the request timed out.
final class NetworkFailure extends AppFailure {
  const NetworkFailure({
    String message = 'پەیوەندی ئینتەرنێت بەردەست نییە',
    super.cause,
    super.stackTrace,
  }) : super(message);
}

/// The user must sign in before this action is possible.
final class AuthFailure extends AppFailure {
  const AuthFailure({
    String message = 'تکایە بچۆ ژوورەوە',
    super.cause,
    super.stackTrace,
  }) : super(message);
}

/// The user is signed in but not allowed to perform this action.
final class PermissionFailure extends AppFailure {
  const PermissionFailure({
    String message = 'ڕێگەپێدراو نیت',
    super.cause,
    super.stackTrace,
  }) : super(message);
}

/// The requested record does not exist.
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({
    String message = 'هیچ بابەتێک نەدۆزرایەوە',
    super.cause,
    super.stackTrace,
  }) : super(message);
}

/// User-supplied input was rejected before or by the server.
final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, {super.cause, super.stackTrace});
}

/// The app is missing the configuration it needs (for example, `.env` keys).
final class ConfigurationFailure extends AppFailure {
  const ConfigurationFailure({
    String message = 'زانیاری Supabase لە پەڕگەی .env دانەنراوە',
    super.cause,
    super.stackTrace,
  }) : super(message);
}

/// Anything we could not classify.
final class UnknownFailure extends AppFailure {
  const UnknownFailure({
    String message = 'هەڵەیەک ڕوویدا، تکایە دووبارە هەوڵبدەرەوە',
    super.cause,
    super.stackTrace,
  }) : super(message);
}

/// Runs [action], converting any thrown object into an [AppFailure].
///
/// This is the single funnel every repository method goes through, which is
/// what lets the UI rely on `catch (error) => AppFailure` without each call
/// site re-implementing the mapping.
Future<T> guardFailures<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on Object catch (error, stackTrace) {
    Error.throwWithStackTrace(AppFailure.from(error, stackTrace), stackTrace);
  }
}
