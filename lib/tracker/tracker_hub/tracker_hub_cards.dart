part of 'tracker_hub_page.dart';

class _TrackerSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color accent;

  const _TrackerSectionHeader({
    required this.title,
    required this.count,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _TrackerSectionGrid extends StatelessWidget {
  final List<String> trackerIds;
  final double maxWidth;
  final String? selectedTrackerId;
  final Map<String, String> devicePlayerMap;
  final EventSync? eventSync;
  final List<TimeRange> periods;
  final ValueChanged<String> onSelect;
  final Future<void> Function() onAlreadySynced;

  const _TrackerSectionGrid({
    required this.trackerIds,
    required this.maxWidth,
    required this.selectedTrackerId,
    required this.devicePlayerMap,
    required this.eventSync,
    required this.periods,
    required this.onSelect,
    required this.onAlreadySynced,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = _getCrossAxisCount(maxWidth);
    final childAspectRatio = _getChildAspectRatio(maxWidth);
    final rows = (trackerIds.length / crossAxisCount).ceil();
    // Approximate grid height so nested GridView can size inside ListView.
    final spacing = 16.0;
    final itemWidth =
        (maxWidth - 32 - spacing * (crossAxisCount - 1)) / crossAxisCount;
    final itemHeight = itemWidth / childAspectRatio;
    final height = rows * itemHeight + (rows > 0 ? (rows - 1) * spacing : 0);

    return SizedBox(
      height: height.clamp(0, double.infinity),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: trackerIds.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
        itemBuilder: (context, index) {
          final trackerId = trackerIds[index];
          final isSelected = trackerId == selectedTrackerId;
          final deviceSync = eventSync?.devices[trackerId];
          final isDone = deviceSync?.isSynced == true;

          return _TrackerCard(
            trackerId: trackerId,
            isSelected: isSelected,
            isDone: isDone,
            periods: periods,
            playerId: devicePlayerMap[trackerId] ?? '',
            onTap: () async {
              if (isDone) {
                await onAlreadySynced();
                return;
              }
              onSelect(trackerId);
            },
          );
        },
      ),
    );
  }
}

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

        final borderColor = isDone
            ? colors.success
            : (isSelected ? colors.warning : colors.border);
        final fillColor = isDone
            ? colors.success.withValues(alpha: 0.08)
            : (isSelected
                ? colors.primary.withValues(alpha: 0.10)
                : colors.card);

        return Opacity(
          opacity: isDone ? 0.72 : 1,
          child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: borderColor,
                  width: (isSelected || isDone) ? 1.5 : 1,
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
                              color: isDone
                                  ? colors.success
                                  : colors.textPrimary,
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
                              color: isDone
                                  ? colors.success.withValues(alpha: 0.18)
                                  : (isSelected
                                      ? colors.warning.withValues(alpha: 0.18)
                                      : colors.surface),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isDone
                                    ? colors.success
                                    : (isSelected
                                        ? colors.warning
                                        : colors.border),
                              ),
                            ),
                            child: Text(
                              isDone
                                  ? context.l10n.trackerStatusSynced
                                  : (isSelected
                                      ? context.l10n.trackerStatusSelected
                                      : context.l10n.trackerStatusOpen),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDone
                                    ? colors.success
                                    : (isSelected
                                        ? colors.warning
                                        : colors.textSecondary),
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
