import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/gio_session_opinion.dart';
import 'package:grinta/services/gio_session_opinion_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/ask_diego/ask_diego_access.dart';
import 'package:grinta/widget/ask_diego/ask_diego_avatar.dart';
import 'package:provider/provider.dart';

/// « L'avis de Gio » on a training or match performance sheet.
class GioSessionOpinionButton extends StatelessWidget {
  const GioSessionOpinionButton({
    super.key,
    required this.eventId,
    required this.playerId,
    required this.isMatch,
    required this.source,
    required this.currentMetrics,
    this.teamId,
    this.player,
    this.playerName,
    this.opinionService,
  });

  final String eventId;
  final String playerId;
  final bool isMatch;
  final GioSessionOpinionSource source;
  final Map<String, num> currentMetrics;
  final String? teamId;
  final Player? player;
  final String? playerName;
  final GioSessionOpinionService? opinionService;

  @override
  Widget build(BuildContext context) {
    if (eventId.trim().isEmpty || currentMetrics.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _open(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const AskDiegoAvatar(size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.gioSessionOpinionButton,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    if (!await ensureAskGioAccess(context)) return;
    if (!context.mounted) return;

    final session = context.read<AppSession>();
    final localeCode = Localizations.localeOf(context).languageCode;
    final colors = context.appColors;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _GioSessionOpinionSheet(
          session: session,
          localeCode: localeCode,
          eventId: eventId,
          playerId: playerId,
          isMatch: isMatch,
          source: source,
          currentMetrics: currentMetrics,
          teamId: teamId,
          player: player,
          playerName: playerName,
          opinionService: opinionService ?? GioSessionOpinionService(),
        );
      },
    );
  }
}

class _GioSessionOpinionSheet extends StatefulWidget {
  const _GioSessionOpinionSheet({
    required this.session,
    required this.localeCode,
    required this.eventId,
    required this.playerId,
    required this.isMatch,
    required this.source,
    required this.currentMetrics,
    required this.opinionService,
    this.teamId,
    this.player,
    this.playerName,
  });

  final AppSession session;
  final String localeCode;
  final String eventId;
  final String playerId;
  final bool isMatch;
  final GioSessionOpinionSource source;
  final Map<String, num> currentMetrics;
  final GioSessionOpinionService opinionService;
  final String? teamId;
  final Player? player;
  final String? playerName;

  @override
  State<_GioSessionOpinionSheet> createState() =>
      _GioSessionOpinionSheetState();
}

class _GioSessionOpinionSheetState extends State<_GioSessionOpinionSheet> {
  late Future<String> _opinion;

  @override
  void initState() {
    super.initState();
    _opinion = _load();
  }

  Future<String> _load() {
    return widget.opinionService.requestOpinion(
      session: widget.session,
      localeCode: widget.localeCode,
      isMatch: widget.isMatch,
      source: widget.source,
      eventId: widget.eventId,
      playerId: widget.playerId,
      currentMetrics: widget.currentMetrics,
      player: widget.player,
      teamId: widget.teamId,
      playerName: widget.playerName,
    );
  }

  void _retry() {
    setState(() {
      _opinion = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final height = MediaQuery.sizeOf(context).height * 0.72;

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                const AskDiegoAvatar(size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.gioSessionOpinionButton,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.actionClose,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: colors.textPrimary),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.border),
          Expanded(
            child: FutureBuilder<String>(
              future: _opinion,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: colors.primary),
                          const SizedBox(height: 16),
                          Text(
                            l10n.gioSessionOpinionLoading,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.hasError ||
                    (snapshot.data?.trim().isEmpty ?? true)) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.gioSessionOpinionError,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _retry,
                            child: Text(l10n.actionRetry),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    16 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: SelectableText(
                    snapshot.data!.trim(),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
