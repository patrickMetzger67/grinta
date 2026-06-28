part of 'team_detail_screen.dart';

class TeamThresholdCardData {
  const TeamThresholdCardData({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class _TeamMemberVm {
  const _TeamMemberVm({
    required this.player,
    required this.effectives,
    required this.trackers,
    this.grintaPositions = const <int>[],
    this.isGrintaRoster = false,
    this.grintaEmail,
    this.grintaPhoneE164,
    this.grintaBirthday,
    this.grintaHeightCm,
    this.grintaWeightKg,
    this.grintaInvitationId,
    this.invitationAccepted,
  });

  final Player player;
  final Effectives? effectives;
  final List<_TrackerChipVm> trackers;
  final List<int> grintaPositions;
  final bool isGrintaRoster;
  final String? grintaEmail;
  final String? grintaPhoneE164;
  final DateTime? grintaBirthday;
  final int? grintaHeightCm;
  final double? grintaWeightKg;
  final String? grintaInvitationId;
  final bool? invitationAccepted;
}

class _TrackerChipVm {
  const _TrackerChipVm({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}



class _TrackerChip extends StatelessWidget {
  const _TrackerChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 180,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF232A3B),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFFFFB27A),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeaderSquareIconButton extends StatelessWidget {
  const _HeaderSquareIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF232A3B),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CircleGhostButton extends StatelessWidget {
  const _CircleGhostButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: colors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

class _ThresholdCard extends StatelessWidget {
  const _ThresholdCard({
    required this.data,
  });

  final TeamThresholdCardData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: 190,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF232A3B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            data.value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFFFFB27A),
            ),
          ),
        ],
      ),
    );
  }
}