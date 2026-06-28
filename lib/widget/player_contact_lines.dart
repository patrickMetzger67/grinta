import 'package:flutter/material.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/util/app_theme.dart';

/// Email and phone lines shown below a player name in list or card rows.
class PlayerContactLines extends StatelessWidget {
  const PlayerContactLines({
    super.key,
    required this.player,
    this.emailOverride,
    this.phoneE164Override,
  });

  final Player player;
  final String? emailOverride;
  final String? phoneE164Override;

  @override
  Widget build(BuildContext context) {
    final email = emailOverride?.trim().isNotEmpty == true
        ? emailOverride!.trim()
        : player.email?.trim();
    final phone = phoneE164Override?.trim().isNotEmpty == true
        ? phoneE164Override!.trim()
        : player.phoneE164?.trim();

    final hasEmail = email != null && email.isNotEmpty;
    final hasPhone = phone != null && phone.isNotEmpty;
    if (!hasEmail && !hasPhone) {
      return const SizedBox.shrink();
    }

    final colors = context.appColors;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.textSecondary,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasEmail)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        if (hasPhone)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              phone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
      ],
    );
  }
}
