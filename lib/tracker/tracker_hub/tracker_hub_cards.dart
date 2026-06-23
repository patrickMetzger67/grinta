part of 'tracker_hub_page.dart';

class _TrackerCard extends StatelessWidget {
  final String trackerId;
  final bool isSelected;
  final bool isDone;
  final VoidCallback onTap;
  final List<TimeRange> periods;
  final String playerId;

  const _TrackerCard({
    required this.trackerId,
    required this.isSelected,
    required this.isDone,
    required this.onTap,
    required this.periods,
    required this.playerId,
  });

  String _formatPlayerName(Player? player) {
    if (player == null) return '';

    final String firstName = (player.firstName ?? '').trim();
    final String lastName = (player.lastName ?? '').trim();

    final String firstLetter =
    firstName.isNotEmpty ? firstName[0].toUpperCase() : '';

    final String upperLastName = lastName.toUpperCase();

    if (firstLetter.isNotEmpty && upperLastName.isNotEmpty) {
      return '$firstLetter. $upperLastName';
    } else if (upperLastName.isNotEmpty) {
      return upperLastName;
    } else if (firstName.isNotEmpty) {
      return firstName;
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final PlayerService playerService = PlayerService();

    return FutureBuilder<Player?>(
      future: playerService.getPlayerById(playerId),
      builder: (context, playerSnapshot) {
        final Player? player = playerSnapshot.data;
        final String playerName = _formatPlayerName(player);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary.withValues(alpha: 0.10)
                    : colors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? colors.success : colors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Flexible(
                      flex: 3,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            trackerId,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Flexible(
                      flex: 4,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            constraints: const BoxConstraints(
                              maxWidth: 60,
                              maxHeight: 60,
                            ),
                            child: player == null
                                ? Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.primary.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: isDone
                                        ? colors.success
                                        : colors.danger,
                                  ),
                                ),
                              ),
                            )
                                : PlayerPhoto(player: player, radius: 30),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    if (playerName.isNotEmpty)
                      Flexible(
                        flex: 2,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              playerName,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),

                    Flexible(
                      flex: 3,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.success.withValues(alpha: 0.18)
                                  : colors.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color:
                                isSelected ? colors.success : colors.border,
                              ),
                            ),
                            child: Text(
                              isSelected
                                  ? context.l10n.trackerStatusSelected
                                  : (isDone
                                      ? context.l10n.trackerStatusSynced
                                      : context.l10n.trackerStatusOpen),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: (isSelected || isDone)
                                    ? colors.success
                                    : colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}



class _TrackerDetailPanel extends StatelessWidget {
  final String? trackerId;
  final List<TimeRange> periods;
  final bool isMatch;
  final String eventId;
  final FieldGpsCorners? fieldGpsCorners;
  final String? playerId;
  final EventSync? eventSync;
  final String? ownerId;

  const _TrackerDetailPanel({
    required this.trackerId,
    required this.periods,
    required this.isMatch,
    required this.eventId,
    required this.fieldGpsCorners,
    required this.playerId,
    required this.eventSync,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (trackerId == null) {
      return Container(
        color: colors.background,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.gps_not_fixed_rounded,
                  size: 46,
                  color: colors.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.emptyNoTracker,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.trackerSelectForActions,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AsiDownloaderPanel(
      trackerId: trackerId!,
      periods: periods,
      isMatch: isMatch,
      eventId: eventId,
      fieldGpsCorners:fieldGpsCorners,
      playerId: playerId ?? '',
      eventSync: eventSync!,
      ownerId: ownerId,
    );
  }
}

class _TrackerEmptyState extends StatelessWidget {
  const _TrackerEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.gps_off_rounded,
              size: 46,
              color: colors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.emptyNoTrackers,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
