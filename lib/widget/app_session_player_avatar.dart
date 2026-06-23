import 'package:flutter/material.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:provider/provider.dart';

/// Avatar joueur (initiales ou photo) réutilisable dans l'app.
class AppSessionPlayerAvatar extends StatelessWidget {
  const AppSessionPlayerAvatar({
    super.key,
    required this.player,
    this.imageProvider,
    this.imageUrls,
    this.radius = 18,
    this.watchSessionForStaleWebAvatar = false,
  });

  final Player player;
  final ImageProvider? imageProvider;
  final List<String>? imageUrls;
  final double radius;
  final bool watchSessionForStaleWebAvatar;

  @override
  Widget build(BuildContext context) {
    if (watchSessionForStaleWebAvatar) {
      return _WebStaleAvatarWatcher(
        player: player,
        imageUrls: imageUrls,
        radius: radius,
        child: _buildAvatar(),
      );
    }

    return _buildAvatar();
  }

  Widget _buildAvatar() {
    if (imageUrls != null && imageUrls!.isNotEmpty) {
      return _CascadingNetworkAvatar(
        player: player,
        imageUrls: imageUrls!,
        radius: radius,
      );
    }

    final firstName = player.firstName ?? '';
    final lastName = player.lastName ?? '';
    final initials = _buildInitials(firstName, lastName);

    return CircleAvatar(
      radius: radius,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              initials,
              style: TextStyle(fontSize: radius * 0.65),
            )
          : null,
    );
  }

  static String _buildInitials(String firstName, String lastName) {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    final value = '$f$l';
    return value.isNotEmpty ? value : '?';
  }
}

/// On web, triggers [AppSession.requestAvatarRefreshIfStale] when URLs look stale.
class _WebStaleAvatarWatcher extends StatefulWidget {
  const _WebStaleAvatarWatcher({
    required this.player,
    required this.imageUrls,
    required this.radius,
    required this.child,
  });

  final Player player;
  final List<String>? imageUrls;
  final double radius;
  final Widget child;

  @override
  State<_WebStaleAvatarWatcher> createState() => _WebStaleAvatarWatcherState();
}

class _WebStaleAvatarWatcherState extends State<_WebStaleAvatarWatcher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRefresh());
  }

  @override
  void didUpdateWidget(covariant _WebStaleAvatarWatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls != widget.imageUrls ||
        oldWidget.player.keyMember != widget.player.keyMember) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRefresh());
    }
  }

  void _maybeRefresh() {
    if (!mounted) return;
    final appSession = context.read<AppSession>();
    if (appSession.sessionAvatarUrlsLookStale(
      widget.player,
      widget.imageUrls,
    )) {
      appSession.requestAvatarRefreshIfStale();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Essaie chaque URL en cascade ; repli sur initiales si tout échoue.
class _CascadingNetworkAvatar extends StatefulWidget {
  const _CascadingNetworkAvatar({
    required this.player,
    required this.imageUrls,
    required this.radius,
  });

  final Player player;
  final List<String> imageUrls;
  final double radius;

  @override
  State<_CascadingNetworkAvatar> createState() =>
      _CascadingNetworkAvatarState();
}

class _CascadingNetworkAvatarState extends State<_CascadingNetworkAvatar> {
  late int _index = _firstNonEmptyUrlIndex(widget.imageUrls, 0);
  bool _isAdvancing = false;

  static int _firstNonEmptyUrlIndex(List<String> urls, int start) {
    for (var i = start; i < urls.length; i++) {
      if (urls[i].trim().isNotEmpty) {
        return i;
      }
    }
    return urls.length;
  }

  @override
  void didUpdateWidget(covariant _CascadingNetworkAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_listEquals(oldWidget.imageUrls, widget.imageUrls)) {
      _index = _firstNonEmptyUrlIndex(widget.imageUrls, 0);
      _isAdvancing = false;
    }
  }

  void _advanceToNextUrl() {
    if (_isAdvancing) return;

    final int nextIndex = _firstNonEmptyUrlIndex(widget.imageUrls, _index + 1);
    if (nextIndex >= widget.imageUrls.length) return;

    _isAdvancing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _index = nextIndex;
        _isAdvancing = false;
      });
    });
  }

  Widget _initialsFallback() {
    return AppSessionPlayerAvatar(
      player: widget.player,
      radius: widget.radius,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= widget.imageUrls.length) {
      return _initialsFallback();
    }

    final size = widget.radius * 2;
    final url = widget.imageUrls[_index].trim();

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Image.network(
          url,
          key: ValueKey('player-photo-$url'),
          fit: BoxFit.cover,
          width: size,
          height: size,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          errorBuilder: (_, __, ___) {
            _advanceToNextUrl();
            return SizedBox(width: size, height: size);
          },
        ),
      ),
    );
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
