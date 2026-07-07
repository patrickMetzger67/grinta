import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Grinta-branded Stream Chat theme (colors + avatar fallbacks).
class GrintaStreamChatTheme {
  GrintaStreamChatTheme._();

  /// Orange-toned gradient pairs for user avatar backgrounds.
  static const List<List<Color>> avatarPalettes = [
    [Color(0xFFF95C1B), Color(0xFFFF8A5B)],
    [Color(0xFFE76637), Color(0xFFF95C1B)],
    [Color(0xFFC44A12), Color(0xFFE76637)],
    [Color(0xFFD4551F), Color(0xFFFF8A5B)],
    [Color(0xFFB8420A), Color(0xFFF95C1B)],
    [Color(0xFFF95C1B), Color(0xFFF5B74A)],
    [Color(0xFF9E3A0E), Color(0xFFD4551F)],
    [Color(0xFFE05A20), Color(0xFFFF8A5B)],
  ];

  static StreamChatThemeData themeFor({
    required Brightness brightness,
    required AppColors colors,
  }) {
    final isDark = brightness == Brightness.dark;
    final baseColorTheme =
        isDark ? StreamColorTheme.dark() : StreamColorTheme.light();

    final colorTheme = baseColorTheme.copyWith(
      brightness: brightness,
      textHighEmphasis: colors.textPrimary,
      textLowEmphasis: colors.textSecondary,
      disabled: colors.border,
      borders: colors.border,
      inputBg: colors.surface,
      appBg: colors.background,
      barsBg: colors.surface,
      linkBg: colors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
      accentPrimary: colors.primary,
      accentError: colors.danger,
      accentInfo: colors.success,
      highlight: colors.primary.withValues(alpha: isDark ? 0.15 : 0.1),
    );

    return StreamChatThemeData(
      brightness: brightness,
      colorTheme: colorTheme,
      messageListViewTheme: StreamMessageListViewThemeData(
        backgroundColor: colors.background,
      ),
    );
  }

  static StreamChatConfigurationData config() {
    return StreamChatConfigurationData(
      defaultUserImage: _grintaDefaultUserImage,
    );
  }

  /// Grinta-themed emoji picker config for the message compose bar.
  static Config emojiPickerConfig({
    required AppColors colors,
    required Locale locale,
  }) {
    return Config(
      height: 280,
      locale: locale,
      checkPlatformCompatibility: true,
      emojiViewConfig: EmojiViewConfig(
        backgroundColor: colors.surface,
        columns: 8,
        emojiSizeMax: 28,
        noRecents: Text(
          '—',
          style: TextStyle(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
      categoryViewConfig: CategoryViewConfig(
        backgroundColor: colors.surface,
        iconColor: colors.textSecondary,
        iconColorSelected: colors.primary,
        indicatorColor: colors.primary,
        backspaceColor: colors.textSecondary,
        dividerColor: colors.border,
      ),
      bottomActionBarConfig: BottomActionBarConfig(
        backgroundColor: colors.surface,
        buttonColor: colors.primary.withValues(alpha: 0.15),
        buttonIconColor: colors.primary,
      ),
      searchViewConfig: SearchViewConfig(
        backgroundColor: colors.surface,
        buttonIconColor: colors.primary,
        inputTextStyle: TextStyle(color: colors.textPrimary),
        hintTextStyle: TextStyle(color: colors.textSecondary),
      ),
    );
  }
}

Widget _grintaDefaultUserImage(BuildContext context, User user) {
  return Center(
    child: _GrintaUserAvatarFallback(
      name: user.name,
      userId: user.id,
    ),
  );
}

class _GrintaUserAvatarFallback extends StatelessWidget {
  const _GrintaUserAvatarFallback({
    required this.name,
    required this.userId,
  });

  final String name;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final palette = GrintaStreamChatTheme
        .avatarPalettes[userId.hashCode.abs() % GrintaStreamChatTheme.avatarPalettes.length];
    final initials = name.initials ?? '?';

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final fontSize = initials.length == 2 ? side / 3 : side / 2;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette,
            ),
          ),
          child: Center(
            child: Text(
              initials,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize.isFinite ? fontSize : 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        );
      },
    );
  }
}
