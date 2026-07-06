import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/ask_diego_capabilities.dart';
import 'package:grinta/config/gemini_chat_config.dart';
import 'package:grinta/model/chat_action.dart';
import 'package:http/http.dart' as http;

/// Sends chat messages to Gemini via Cloud Function (or direct API in dev).
class GeminiChatService {
  GeminiChatService._();

  static final GeminiChatService instance = GeminiChatService._();

  Future<List<ChatAction>> sendMessage({
    required String message,
    required Map<String, dynamic> context,
    required String localeCode,
    List<Map<String, String>> history = const <Map<String, String>>[],
  }) async {
    if (kGeminiChatUseDirectApi && kGeminiApiKey.trim().isNotEmpty) {
      return _sendViaDirectApi(
        message: message,
        context: context,
        localeCode: localeCode,
        history: history,
      );
    }

    return _sendViaCloudFunction(
      message: message,
      context: context,
      localeCode: localeCode,
      history: history,
    );
  }

  Future<List<ChatAction>> _sendViaCloudFunction({
    required String message,
    required Map<String, dynamic> context,
    required String localeCode,
    required List<Map<String, String>> history,
  }) async {
    try {
      final functions = FirebaseFunctions.instanceFor(
        region: kGeminiFunctionsRegion,
      );
      final callable = functions.httpsCallable(kChatWithGeminiFunctionName);

      final result = await callable.call<Map<String, dynamic>>({
        'message': message,
        'context': context,
        'locale': localeCode,
        'history': history,
      });

      final data = result.data;
      return parseChatActions(data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('GeminiChatService callable error: ${e.code} ${e.message}');
      return <ChatAction>[
        ChatAnswerAction(
          text: _userFacingFunctionsError(e),
        ),
      ];
    } catch (e, st) {
      debugPrint('GeminiChatService error: $e\n$st');
      return const <ChatAction>[
        ChatAnswerAction(text: 'Une erreur est survenue. Réessayez plus tard.'),
      ];
    }
  }

  Future<List<ChatAction>> _sendViaDirectApi({
    required String message,
    required Map<String, dynamic> context,
    required String localeCode,
    required List<Map<String, String>> history,
  }) async {
    final systemPrompt = buildAskDiegoSystemPrompt();

    final historyText = history
        .map((Map<String, String> h) {
          final role = h['role'] == 'assistant' ? 'Assistant' : 'User';
          return '$role: ${h['text']}';
        })
        .join('\n');

    final body = <String, dynamic>{
      'system_instruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text':
                  'Context: ${jsonEncode(context)}\n$historyText\nQuestion: $message',
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.4,
        'responseMimeType': 'application/json',
      },
    };

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$kGeminiChatModel:generateContent?key=${kGeminiApiKey.trim()}',
    );

    try {
      final response = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('Gemini direct API error: ${response.statusCode} ${response.body}');
        return const <ChatAction>[
          ChatAnswerAction(text: 'Erreur API Gemini. Vérifiez la clé.'),
        ];
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List<dynamic>?;
      final content = candidates?.first?['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final text = (parts?.first?['text'] ?? '').toString();

      return parseChatActions(jsonDecode(text));
    } catch (e, st) {
      debugPrint('Gemini direct API exception: $e\n$st');
      return const <ChatAction>[
        ChatAnswerAction(text: 'Erreur lors de l\'appel Gemini.'),
      ];
    }
  }

  String _userFacingFunctionsError(FirebaseFunctionsException e) {
    if (e.code == 'failed-precondition') {
      return 'L\'assistant n\'est pas encore configuré côté serveur (clé Gemini manquante).';
    }
    if (e.code == 'unauthenticated') {
      return 'Connectez-vous pour utiliser l\'assistant.';
    }
    if (e.code == 'not-found') {
      return 'La fonction chatWithGemini n\'est pas déployée. Déployez les Cloud Functions.';
    }
    final message = e.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return 'Impossible de contacter l\'assistant pour le moment.';
  }
}
