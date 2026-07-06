import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

const String kStreamFunctionsRegion = 'europe-west1';
const String kCreateTeamStreamChannelFunctionName = 'createTeamStreamChannel';
const String _logPrefix = '[StreamChannel]';

/// Parsed callable failure from [FirebaseFunctionsException].
class StreamChannelCallableError {
  const StreamChannelCallableError({
    required this.code,
    this.message,
    this.details,
    required this.userMessage,
  });

  final String code;
  final String? message;
  final Object? details;
  final String userMessage;

  factory StreamChannelCallableError.fromException(
    FirebaseFunctionsException e,
  ) {
    return StreamChannelCallableError(
      code: e.code,
      message: e.message,
      details: e.details,
      userMessage: StreamChannelService.userFacingError(e),
    );
  }
}

/// Calls Cloud Functions for GetStream team channels.
class StreamChannelService {
  StreamChannelService._();

  static final StreamChannelService instance = StreamChannelService._();

  /// Emits a line via [print], [debugPrint], and [developer.log] so web
  /// consoles always show Stream channel diagnostics.
  static void log(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final line =
        message.startsWith(_logPrefix) ? message : '$_logPrefix $message';
    // ignore: avoid_print
    print(line);
    debugPrint(line);
    developer.log(
      line,
      name: 'StreamChannel',
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<Map<String, dynamic>> createTeamStreamChannel({
    required String teamId,
    String? teamName,
  }) async {
    final trimmedTeamId = teamId.trim();
    final trimmedTeamName = teamName?.trim();
    final namePart = _teamNameSuffix(trimmedTeamName);

    log(
      '$kCreateTeamStreamChannelFunctionName starting:'
      ' teamId=$trimmedTeamId$namePart'
      ' function=$kCreateTeamStreamChannelFunctionName'
      ' region=$kStreamFunctionsRegion',
    );

    try {
      final functions = FirebaseFunctions.instanceFor(
        region: kStreamFunctionsRegion,
      );
      final callable =
          functions.httpsCallable(kCreateTeamStreamChannelFunctionName);

      final result = await callable.call<Map<String, dynamic>>({
        'teamId': trimmedTeamId,
      });

      final data = Map<String, dynamic>.from(result.data);

      log(
        '$kCreateTeamStreamChannelFunctionName succeeded:'
        ' teamId=$trimmedTeamId$namePart'
        ' response=${encodeForLog(data)}',
      );

      return data;
    } on FirebaseFunctionsException catch (e, st) {
      _logFunctionsException(
        teamId: trimmedTeamId,
        teamName: trimmedTeamName,
        error: e,
        stackTrace: st,
      );
      rethrow;
    } catch (e, st) {
      _logGenericFailure(
        teamId: trimmedTeamId,
        teamName: trimmedTeamName,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Returns the best available server message (message or details), ignoring
  /// values that duplicate the error code (e.g. message == "internal").
  static String? extractServerMessage(FirebaseFunctionsException e) {
    final code = e.code.trim().toLowerCase();

    bool isRedundant(String value) {
      final normalized = value.trim().toLowerCase();
      return normalized.isEmpty || normalized == code;
    }

    final message = e.message?.trim();
    if (message != null && !isRedundant(message)) {
      return message;
    }

    final details = e.details;
    if (details is String) {
      final trimmed = details.trim();
      if (!isRedundant(trimmed)) {
        return trimmed;
      }
    }
    if (details is Map) {
      for (final key in ['message', 'error', 'detail', 'details', 'reason']) {
        final value = details[key]?.toString().trim();
        if (value != null && !isRedundant(value)) {
          return value;
        }
      }
      if (details.isNotEmpty) {
        final encoded = encodeForLog(details);
        if (!isRedundant(encoded)) {
          return encoded;
        }
      }
    }
    if (details != null && details is! Map && details is! String) {
      final encoded = details.toString().trim();
      if (!isRedundant(encoded)) {
        return encoded;
      }
    }

    return null;
  }

  /// Formats a callable error for logs (code, message, details).
  static String formatFunctionsException(FirebaseFunctionsException e) {
    final buffer = StringBuffer('code=${e.code}');
    final message = e.message?.trim();
    if (message != null && message.isNotEmpty) {
      buffer.write(' message=$message');
    }
    buffer.write(' details=${encodeForLog(e.details)}');
    return buffer.toString();
  }

  static String encodeForLog(Object? value) {
    if (value == null) {
      return 'null';
    }
    try {
      return jsonEncode(value);
    } catch (_) {
      return value.toString();
    }
  }

  /// Human-readable French message for snackbars; prefers server text when set.
  static String userFacingError(FirebaseFunctionsException e) {
    final serverMessage = extractServerMessage(e);
    if (serverMessage != null && serverMessage.isNotEmpty) {
      return serverMessage;
    }

    switch (e.code) {
      case 'internal':
        return 'Erreur serveur lors de la création du groupe Stream';
      case 'permission-denied':
        return 'Accès refusé';
      case 'unauthenticated':
        return 'Non connecté';
      case 'failed-precondition':
        return 'Configuration Stream manquante';
      case 'not-found':
        return 'Équipe introuvable';
      case 'invalid-argument':
        return 'Identifiant d\'équipe manquant';
      default:
        return 'Erreur lors de la création du groupe Stream';
    }
  }

  /// Parses a callable exception into a structured error for UI handling.
  StreamChannelCallableError parseCallableError(FirebaseFunctionsException e) {
    return StreamChannelCallableError.fromException(e);
  }

  static String _teamNameSuffix(String? teamName) {
    if (teamName != null && teamName.isNotEmpty) {
      return ' teamName="$teamName"';
    }
    return '';
  }

  void _logFunctionsException({
    required String teamId,
    String? teamName,
    required FirebaseFunctionsException error,
    StackTrace? stackTrace,
  }) {
    final namePart = _teamNameSuffix(teamName);

    log(
      '$kCreateTeamStreamChannelFunctionName failed:'
      ' teamId=$teamId$namePart',
      error: error,
    );
    log('code=${error.code}');
    log('message=${error.message ?? "(null)"}');
    log('details=${encodeForLog(error.details)}');
    log('formatted=${formatFunctionsException(error)}');
    if (stackTrace != null) {
      log('stackTrace=$stackTrace', stackTrace: stackTrace);
    }
  }

  void _logGenericFailure({
    required String teamId,
    String? teamName,
    required Object error,
    StackTrace? stackTrace,
  }) {
    final namePart = _teamNameSuffix(teamName);

    log(
      '$kCreateTeamStreamChannelFunctionName failed:'
      ' teamId=$teamId$namePart error=${error.toString()}',
      error: error,
      stackTrace: stackTrace,
    );
    if (stackTrace != null) {
      log('stackTrace=$stackTrace', stackTrace: stackTrace);
    }
  }
}
