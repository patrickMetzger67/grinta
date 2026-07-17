import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/chat_action.dart';
import 'package:grinta/model/chat_message.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/chat_context_service.dart';
import 'package:grinta/services/chat_navigation_service.dart';
import 'package:grinta/services/gemini_chat_service.dart';
import 'package:grinta/services/opponent_typical_team_chat_context.dart';
import 'package:grinta/services/player_activity_report_chat_context.dart';
import 'package:grinta/services/session_report_action_resolver.dart';
import 'package:grinta/services/session_report_chat_context.dart';
import 'package:grinta/services/session_report_sender_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/ask_diego/ask_diego_avatar.dart';
import 'package:grinta/widget/chat_bot/chat_input_bar.dart';
import 'package:grinta/widget/chat_bot/chat_message_bubble.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

Future<void> showAskDiegoSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.appColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => AskDiegoSheet(
        scrollController: scrollController,
      ),
    ),
  );
}

class AskDiegoSheet extends StatefulWidget {
  const AskDiegoSheet({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  State<AskDiegoSheet> createState() => _AskDiegoSheetState();
}

class _AskDiegoSheetState extends State<AskDiegoSheet> {
  static const _uuid = Uuid();
  static const Map<String, String> _speechLocaleFallbacks = <String, String>{
    'fr': 'fr_FR',
    'en': 'en_US',
    'de': 'de_DE',
    'es': 'es_ES',
    'it': 'it_IT',
  };

  final TextEditingController _inputController = TextEditingController();
  final ChatContextService _contextService = ChatContextService();
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  final List<ChatMessage> _messages = <ChatMessage>[];
  bool _isSending = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  String? _speakingMessageId;
  late final Future<void> _speechInitFuture;
  Future<Map<String, dynamic>>? _preloadedContextFuture;

  @override
  void initState() {
    super.initState();
    _speechInitFuture = _initSpeech();
    unawaited(_initTts());
    _seedWelcomeMessage();
    WidgetsBinding.instance.addPostFrameCallback((_) => _preloadContext());
  }

  void _preloadContext() {
    if (!mounted) return;
    final session = context.read<AppSession>();
    final localeCode = Localizations.localeOf(context).languageCode;
    _preloadedContextFuture = _contextService.buildContext(
      session: session,
      localeCode: localeCode,
      preloadNextMatchTypicalTeam: true,
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    unawaited(_speech.stop());
    unawaited(_tts.stop());
    super.dispose();
  }

  void _seedWelcomeMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            id: _uuid.v4(),
            role: ChatMessageRole.assistant,
            text: context.l10n.askDiegoWelcome,
          ),
        );
      });
    });
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        setState(() {
          if (status == SpeechToText.listeningStatus) {
            _isListening = true;
          } else if (status == SpeechToText.doneStatus ||
              status == SpeechToText.notListeningStatus) {
            _isListening = false;
          }
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isListening = false);
        _showSpeechSnackBar(_speechErrorMessage(context, error.errorMsg));
      },
    );
    if (mounted) {
      setState(() => _speechAvailable = available);
    }
  }

  void _showSpeechSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _speechErrorMessage(BuildContext context, String? reason) {
    final l10n = context.l10n;
    final trimmed = reason?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return l10n.askDiegoSpeechUnavailable;
    }
    final normalized = trimmed.toLowerCase();
    if (_isSpeechPermissionDenied(normalized)) {
      return l10n.askDiegoSpeechPermissionDenied;
    }
    if (normalized.contains('not supported') ||
        normalized.contains('speech_not_supported')) {
      return l10n.askDiegoSpeechUnavailable;
    }
    return l10n.askDiegoSpeechError(trimmed);
  }

  bool _isSpeechPermissionDenied(String normalizedReason) {
    return normalizedReason.contains('not-allowed') ||
        normalizedReason.contains('not allowed') ||
        normalizedReason.contains('permission') ||
        normalizedReason.contains('denied') ||
        normalizedReason.contains('service-not-allowed');
  }

  Future<String?> _resolveSpeechLocale() async {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode.toLowerCase();

    try {
      final locales = await _speech.locales();
      if (locales.isEmpty) {
        return _speechLocaleFallbacks[languageCode];
      }

      final countryCode = locale.countryCode?.toUpperCase();
      if (countryCode != null && countryCode.isNotEmpty) {
        final exactId = '${languageCode}_$countryCode';
        for (final entry in locales) {
          if (entry.localeId.toLowerCase() == exactId.toLowerCase()) {
            return entry.localeId;
          }
        }
      }

      for (final entry in locales) {
        final id = entry.localeId.toLowerCase();
        if (id.startsWith('${languageCode}_') || id == languageCode) {
          return entry.localeId;
        }
      }

      final fallback = _speechLocaleFallbacks[languageCode];
      if (fallback != null) {
        for (final entry in locales) {
          if (entry.localeId == fallback) {
            return entry.localeId;
          }
        }
      }

      return locales.first.localeId;
    } catch (_) {
      return _speechLocaleFallbacks[languageCode];
    }
  }

  Future<void> _initTts() async {
    await _tts.setSpeechRate(0.48);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speakingMessageId = null);
    });
  }

  List<Map<String, String>> _historyForApi() {
    return _messages
        .where((ChatMessage m) => !m.isLoading && m.text.trim().isNotEmpty)
        .map(
          (ChatMessage m) => <String, String>{
            'role': m.role == ChatMessageRole.user ? 'user' : 'assistant',
            'text': m.text,
          },
        )
        .toList();
  }

  Future<Map<String, dynamic>> _resolveContextForSend({
    required AppSession session,
    required String localeCode,
    required String userMessage,
  }) async {
    final needsFreshContext =
        OpponentTypicalTeamChatContext.detectsTypicalTeamIntent(userMessage) ||
            PlayerActivityReportChatContext.detectsActivityReportIntent(
              userMessage,
            ) ||
            SessionReportChatContext.detectsSessionReportIntent(userMessage);

    final preloaded = _preloadedContextFuture;
    if (!needsFreshContext && preloaded != null) {
      try {
        final cached = await preloaded;
        final teams = session.teamsForAgendaSelectedSeason;
        final agenda = cached['agenda'];
        final itemCount = agenda is Map ? agenda['itemCount'] as int? ?? 0 : 0;
        if (teams.isNotEmpty && itemCount > 0) {
          return cached;
        }
        if (kDebugMode) {
          debugPrint(
            'AskDiego: discarding preloaded context '
            '(teams=${teams.length}, agenda.itemCount=$itemCount)',
          );
        }
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('AskDiego: preloaded context failed: $error\n$stackTrace');
        }
      }
    }

    return _contextService.buildContext(
      session: session,
      localeCode: localeCode,
      userMessage: userMessage,
      preloadNextMatchTypicalTeam: false,
    );
  }

  void _logAgendaContextDebug(Map<String, dynamic> appContext) {
    if (!kDebugMode) return;

    final agenda = appContext['agenda'];
    final lastWeek = appContext['lastWeekAgenda'];
    final itemCount = agenda is Map ? agenda['itemCount'] as int? ?? 0 : 0;
    final lastWeekCount =
        lastWeek is Map ? lastWeek['itemCount'] as int? ?? 0 : 0;
    final sampleDates = agenda is Map
        ? ((agenda['items'] as List<dynamic>?)
                ?.take(3)
                .map((dynamic item) {
                  if (item is Map) {
                    return item['date']?.toString() ?? '?';
                  }
                  return '?';
                })
                .join(', ') ??
            '(none)')
        : '(none)';

    debugPrint(
      'AskDiego send context: agenda.itemCount=$itemCount '
      'lastWeekAgenda.itemCount=$lastWeekCount '
      'sampleDates=$sampleDates',
    );
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final text = (overrideText ?? _inputController.text).trim();
    if (text.isEmpty || _isSending) return;

    _inputController.clear();
    FocusManager.instance.primaryFocus?.unfocus();

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: ChatMessageRole.user,
      text: text,
    );

    final loadingId = _uuid.v4();
    final loadingMessage = ChatMessage(
      id: loadingId,
      role: ChatMessageRole.assistant,
      text: '',
      isLoading: true,
    );

    setState(() {
      _messages.addAll(<ChatMessage>[userMessage, loadingMessage]);
      _isSending = true;
    });
    _scrollToBottom();

    final session = context.read<AppSession>();
    final localeCode = Localizations.localeOf(context).languageCode;

    final appContext = await _resolveContextForSend(
      session: session,
      localeCode: localeCode,
      userMessage: text,
    );
    _logAgendaContextDebug(appContext);
    _preloadedContextFuture = null;
    _preloadContext();

    final actions = await GeminiChatService.instance.sendMessage(
      message: text,
      context: appContext,
      localeCode: localeCode,
      history: _historyForApi(),
    );

    if (!mounted) return;

    final answerText = joinAnswerTexts(actions);
    ChatNavigateAction? navigateAction;
    ChatSendReportAction? sendReportAction;
    for (final action in actions) {
      if (action is ChatNavigateAction && navigateAction == null) {
        navigateAction = action;
      }
      if (action is ChatSendReportAction && sendReportAction == null) {
        sendReportAction = action;
      }
    }

    var displayText = answerText.isNotEmpty
        ? answerText
        : context.l10n.askDiegoEmptyResponse;

    // Client-owned flow for PDF/email session reports: do not rely on the
    // deployed Gemini prompt (it may still refuse until chatWithGemini is updated).
    if (SessionReportChatContext.detectsSessionReportIntent(text)) {
      final l10n = context.l10n;
      final resolved = sendReportAction != null
          ? SessionReportResolveResult(action: sendReportAction)
          : SessionReportActionResolver.resolveDetailed(
              appContext: appContext,
              userMessage: text,
            );

      if (resolved.action != null) {
        final reportFeedback = await _handleSendReportAction(
          action: resolved.action!,
          appContext: appContext,
          localeCode: localeCode,
        );
        if (!mounted) return;
        displayText = (reportFeedback != null && reportFeedback.isNotEmpty)
            ? reportFeedback
            : l10n.sessionReportEmailFailed;
      } else {
        displayText = _sessionReportFailureMessage(
          l10n: l10n,
          failureReason: resolved.failureReason,
          appContext: appContext,
        );
      }
    }

    if (!mounted) return;

    setState(() {
      _isSending = false;
      _messages.removeWhere((ChatMessage m) => m.id == loadingId);
      _messages.add(
        ChatMessage(
          id: _uuid.v4(),
          role: ChatMessageRole.assistant,
          text: displayText,
          navigationRoute: navigateAction?.route,
          navigationParams: navigateAction?.params ?? const <String, dynamic>{},
          navigationLabel: _navigationLabelForRoute(
            context,
            navigateAction?.route,
          ),
        ),
      );
    });
    _scrollToBottom();

    if (navigateAction != null &&
        navigateAction.route.trim().toLowerCase() != 'team_stats_opponents') {
      await ChatNavigationService.instance.navigate(
        context,
        navigateAction.route,
        navigateAction.params,
        userMessage: text,
      );
    }
  }

  Future<String?> _handleSendReportAction({
    required ChatSendReportAction action,
    required Map<String, dynamic> appContext,
    required String localeCode,
  }) async {
    final l10n = context.l10n;
    final eventId = action.eventId;
    final email = action.email ??
        SessionReportChatContext.extractEmailFromMessage(
          (appContext['sessionReports'] is Map)
              ? (appContext['sessionReports'] as Map)['requestedEmail']
                  ?.toString()
              : null,
        ) ??
        ((appContext['sessionReports'] is Map)
            ? (appContext['sessionReports'] as Map)['defaultEmail']?.toString()
            : null);

    if (eventId == null || eventId.isEmpty) {
      return l10n.sessionReportEmailNoStats;
    }
    if (email == null || email.trim().isEmpty) {
      return l10n.sessionReportEmailInvalid;
    }

    final sessionMeta = _findSessionReportMeta(
      appContext: appContext,
      eventId: eventId,
    );
    final isMatch = action.isMatch ??
        (sessionMeta?['type']?.toString() == 'match');

    final result = await SessionReportSenderService.instance.sendReport(
      l10n: l10n,
      toEmail: email.trim(),
      eventId: eventId,
      isMatch: isMatch,
      title: sessionMeta?['title']?.toString(),
      subtitle: sessionMeta?['subtitle']?.toString(),
      teamId: sessionMeta?['teamId']?.toString(),
      teamName: sessionMeta?['teamName']?.toString(),
      localeCode: localeCode,
      eventDate: _parseIsoDate(sessionMeta?['date']?.toString()),
    );

    if (result.success) {
      return l10n.sessionReportEmailSuccess(email.trim());
    }

    final error = result.error ?? '';
    if (error == 'noStats') {
      return l10n.sessionReportEmailNoStats;
    }
    if (error == 'invalidEmail' || error == 'emptyEmail') {
      return l10n.sessionReportEmailInvalid;
    }
    return l10n.sessionReportEmailFailed;
  }

  Map<String, dynamic>? _findSessionReportMeta({
    required Map<String, dynamic> appContext,
    required String eventId,
  }) {
    final reports = appContext['sessionReports'];
    if (reports is! Map) return null;
    final sessions = reports['sessions'];
    if (sessions is! List) return null;
    for (final entry in sessions) {
      if (entry is! Map) continue;
      if ((entry['eventId'] ?? '').toString() == eventId) {
        return Map<String, dynamic>.from(entry);
      }
    }
    return null;
  }

  DateTime? _parseIsoDate(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _sessionReportFailureMessage({
    required AppLocalizations l10n,
    required String? failureReason,
    required Map<String, dynamic> appContext,
  }) {
    switch (failureReason) {
      case 'no_email':
        return l10n.sessionReportEmailAskAddress;
      case 'no_sessions':
        return l10n.sessionReportEmailNoSessionYesterday;
      case 'no_stats':
      case 'no_event':
      case 'missing_context':
        return l10n.sessionReportEmailNoStats;
      default:
        final reports = appContext['sessionReports'];
        final reason =
            reports is Map ? reports['dataUnavailableReason']?.toString() : null;
        if (reason == 'period_not_understood') {
          return l10n.sessionReportEmailPeriodUnclear;
        }
        return l10n.sessionReportEmailNoStats;
    }
  }

  String? _navigationLabelForRoute(BuildContext context, String? route) {
    if (route == null) return null;
    switch (route.trim().toLowerCase()) {
      case 'team_stats_opponents':
        return context.l10n.askDiegoOpenOpponentStats;
      case 'create_training':
        return context.l10n.createTrainingTitle;
      case 'create_match':
        return context.l10n.createMatchTitle;
      default:
        return context.l10n.askDiegoOpenScreen;
    }
  }

  Future<void> _openMessageNavigation(ChatMessage message) async {
    final route = message.navigationRoute;
    if (route == null) return;
    await ChatNavigationService.instance.navigate(
      context,
      route,
      message.navigationParams,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.scrollController.hasClients) return;
      widget.scrollController.animateTo(
        widget.scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _toggleListening() async {
    if (_isSending) return;

    if (_isListening || _speech.isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    await _speechInitFuture;
    if (!mounted) return;

    if (!_speechAvailable) {
      _showSpeechSnackBar(context.l10n.askDiegoSpeechUnavailable);
      return;
    }

    if (_speakingMessageId != null) {
      await _tts.stop();
      if (mounted) setState(() => _speakingMessageId = null);
    }

    final localeId = await _resolveSpeechLocale();

    try {
      await _speech.listen(
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 30),
        ),
        onResult: (result) {
          _inputController.text = result.recognizedWords;
          _inputController.selection = TextSelection.collapsed(
            offset: _inputController.text.length,
          );
          if (result.finalResult) {
            unawaited(_speech.stop());
            if (mounted) setState(() => _isListening = false);
            if (result.recognizedWords.trim().isNotEmpty) {
              unawaited(_sendMessage(result.recognizedWords));
            }
          }
        },
      );

      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      if (!_speech.isListening && !_isListening) {
        _showSpeechSnackBar(
          _speechErrorMessage(context, _speech.lastError?.errorMsg),
        );
      }
    } on ListenFailedException catch (error) {
      if (!mounted) return;
      setState(() => _isListening = false);
      _showSpeechSnackBar(_speechErrorMessage(context, error.message));
    } on SpeechToTextNotInitializedException {
      if (!mounted) return;
      setState(() => _isListening = false);
      _showSpeechSnackBar(context.l10n.askDiegoSpeechUnavailable);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isListening = false);
      _showSpeechSnackBar(_speechErrorMessage(context, error.toString()));
    }
  }

  Future<void> _speakMessage(ChatMessage message) async {
    if (_speakingMessageId == message.id) {
      await _tts.stop();
      if (mounted) setState(() => _speakingMessageId = null);
      return;
    }

    final localeCode = Localizations.localeOf(context).languageCode;
    final ttsLanguage = localeCode == 'fr' ? 'fr-FR' : 'en-US';

    await _tts.stop();
    await _tts.setLanguage(ttsLanguage);

    if (!mounted) return;
    setState(() => _speakingMessageId = message.id);
    await _tts.speak(message.text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: colors.border,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              const AskDiegoAvatar(size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.askDiegoTitle,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: colors.textSecondary),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colors.border),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return ChatMessageBubble(
                message: message,
                isSpeaking: _speakingMessageId == message.id,
                onSpeak: message.role == ChatMessageRole.assistant &&
                        !message.isLoading
                    ? () => unawaited(_speakMessage(message))
                    : null,
                onNavigate: message.navigationRoute != null
                    ? () => unawaited(_openMessageNavigation(message))
                    : null,
              );
            },
          ),
        ),
        ChatInputBar(
          controller: _inputController,
          onSend: () => unawaited(_sendMessage()),
          onMicPressed: () => unawaited(_toggleListening()),
          isListening: _isListening,
          isSending: _isSending,
        ),
      ],
    );
  }
}
