import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/user_avatar_service.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/widget/web_circle_network_image.dart';
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
    // Rebuild when Firebase Auth profile (photoURL) changes — AppSession alone
    // can miss late OAuth photoURL on web.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, authSnapshot) {
        final User? authUser =
            FirebaseAuth.instance.currentUser ?? authSnapshot.data;

        return Consumer<AppSession>(
          builder: (context, appSession, _) {
            final User? resolvedAuthUser =
                authUser ?? appSession.user ?? authSnapshot.data;
            final authUid = liveAuthUid(sessionUser: resolvedAuthUser) ?? '';
            final authPhotoUrl = liveAuthPhotoUrl(sessionUser: resolvedAuthUser);
            final useDirectAuth = authPhotoUrl != null &&
                authPhotoUrl.isNotEmpty &&
                shouldUseDirectAuthPhoto(
                  player,
                  authUid,
                  sessionPlayers: appSession.currentUserPlayers,
                );

            if (kDebugMode) {
              debugPrint(
                'AppSessionPlayerAvatar player=${effectiveMemberId(player)} '
                'authUid=$authUid authPhoto=$authPhotoUrl '
                'linked=${isPlayerLinkedToAuthUser(player, authUid)} '
                'sessionPlayer=${isAuthUsersSessionPlayer(player, authUid, sessionPlayers: appSession.currentUserPlayers)} '
                'path=${useDirectAuth ? 'direct' : 'cascade'}',
              );
            }

            // Logged-in user's own player: always use live Auth photoURL directly.
            // Never cascade through session/default URLs (transient load errors
            // were permanently sticking on the default portrait).
            if (useDirectAuth) {
              return _DirectAuthPhotoAvatar(
                key: ValueKey('auth-photo|$authUid|$authPhotoUrl'),
                photoUrl: authPhotoUrl,
                player: player,
                imageProvider: imageProvider,
                radius: radius,
              );
            }

            final memberId = effectiveMemberId(player);
            final sessionUrls =
                memberId != null ? appSession.playersPhotoUrls[memberId] : null;
            final resolvedUrls = buildDisplayAvatarUrls(
              player: player,
              sessionUrls: sessionUrls,
              overrideUrls: imageUrls,
              authUser: resolvedAuthUser,
            );

            if (kDebugMode) {
              debugPrint(
                'AppSessionPlayerAvatar cascade urls=$resolvedUrls',
              );
            }

            final rebuildKey =
                '${resolvedAuthUser?.uid}|${resolvedAuthUser?.photoURL}|${resolvedUrls.join('|')}';

            Widget avatar = _PlayerAvatarImage(
              key: ValueKey(rebuildKey),
              player: player,
              imageProvider: imageProvider,
              imageUrls: resolvedUrls,
              radius: radius,
            );

            if (watchSessionForStaleWebAvatar) {
              avatar = _WebStaleAvatarWatcher(
                player: player,
                imageUrls: resolvedUrls,
                child: avatar,
              );
            }

            return avatar;
          },
        );
      },
    );
  }
}

/// Auth profile photo for the logged-in user's player — no URL cascade.
class _DirectAuthPhotoAvatar extends StatefulWidget {
  const _DirectAuthPhotoAvatar({
    super.key,
    required this.photoUrl,
    required this.player,
    required this.imageProvider,
    required this.radius,
  });

  final String photoUrl;
  final Player player;
  final ImageProvider? imageProvider;
  final double radius;

  @override
  State<_DirectAuthPhotoAvatar> createState() => _DirectAuthPhotoAvatarState();
}

class _DirectAuthPhotoAvatarState extends State<_DirectAuthPhotoAvatar> {
  bool _loadFailed = false;

  @override
  void didUpdateWidget(covariant _DirectAuthPhotoAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl) {
      _loadFailed = false;
    }
  }

  Widget _initialsFallback() {
    return _InitialsAvatar(
      player: widget.player,
      imageProvider: widget.imageProvider,
      radius: widget.radius,
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = normalizeAuthPhotoDisplayUrl(widget.photoUrl);
    if (url.isEmpty || _loadFailed) {
      if (kDebugMode) {
        debugPrint(
          '_DirectAuthPhotoAvatar initials url=$url loadFailed=$_loadFailed',
        );
      }
      return _initialsFallback();
    }

    final size = widget.radius * 2;

    if (kDebugMode) {
      debugPrint('_DirectAuthPhotoAvatar loading url=$url kIsWeb=$kIsWeb');
    }

    // Web: native <img> avoids CORS/canvas failures on Google lh3 URLs.
    if (kIsWeb) {
      return WebCircleNetworkImage(
        key: ValueKey('direct-auth-web-$url'),
        url: url,
        size: size,
        errorChild: _initialsFallback(),
        onError: () {
          if (kDebugMode) {
            debugPrint('_DirectAuthPhotoAvatar web img onError url=$url');
          }
          if (mounted) setState(() => _loadFailed = true);
        },
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Image.network(
          url,
          key: ValueKey('direct-auth-$url'),
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) {
              debugPrint(
                '_DirectAuthPhotoAvatar load failed url=$url '
                'error=$error stack=$stackTrace',
              );
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _loadFailed = true);
            });
            return _initialsFallback();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(width: size, height: size);
          },
        ),
      ),
    );
  }
}

class _PlayerAvatarImage extends StatefulWidget {
  const _PlayerAvatarImage({
    super.key,
    required this.player,
    required this.imageProvider,
    required this.imageUrls,
    required this.radius,
  });

  final Player player;
  final ImageProvider? imageProvider;
  final List<String> imageUrls;
  final double radius;

  @override
  State<_PlayerAvatarImage> createState() => _PlayerAvatarImageState();
}

class _PlayerAvatarImageState extends State<_PlayerAvatarImage> {
  int _urlIndex = 0;

  @override
  void initState() {
    super.initState();
    _urlIndex = _firstNonEmptyUrlIndex(widget.imageUrls, 0);
  }

  @override
  void didUpdateWidget(covariant _PlayerAvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_listEquals(oldWidget.imageUrls, widget.imageUrls)) {
      _urlIndex = _firstNonEmptyUrlIndex(widget.imageUrls, 0);
    }
  }

  static int _firstNonEmptyUrlIndex(List<String> urls, int start) {
    for (var i = start; i < urls.length; i++) {
      if (urls[i].trim().isNotEmpty) {
        return i;
      }
    }
    return urls.length;
  }

  void _tryNextUrl() {
    final int nextIndex = _firstNonEmptyUrlIndex(widget.imageUrls, _urlIndex + 1);
    if (nextIndex >= widget.imageUrls.length) {
      if (_urlIndex != widget.imageUrls.length) {
        setState(() => _urlIndex = widget.imageUrls.length);
      }
      return;
    }
    if (nextIndex != _urlIndex) {
      setState(() => _urlIndex = nextIndex);
    }
  }

  Widget _initialsFallback() {
    return _InitialsAvatar(
      player: widget.player,
      imageProvider: widget.imageProvider,
      radius: widget.radius,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_urlIndex >= widget.imageUrls.length) {
      if (kDebugMode) {
        debugPrint(
          '_PlayerAvatarImage initials player=${effectiveMemberId(widget.player)} '
          'urls=${widget.imageUrls}',
        );
      }
      return _initialsFallback();
    }

    final url = normalizeAuthPhotoDisplayUrl(widget.imageUrls[_urlIndex].trim());
    final size = widget.radius * 2;
    final isAuthUrl = UserAvatarService.isExternalAuthPhotoUrl(url);

    if (kDebugMode) {
      debugPrint(
        '_PlayerAvatarImage url[$_urlIndex]=$url authUrl=$isAuthUrl kIsWeb=$kIsWeb',
      );
    }

    if (kIsWeb && isAuthUrl) {
      return WebCircleNetworkImage(
        key: ValueKey('player-auth-web-$url'),
        url: url,
        size: size,
        errorChild: _InitialsAvatar(
          player: widget.player,
          imageProvider: null,
          radius: widget.radius,
        ),
        onError: _tryNextUrl,
      );
    }

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
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) {
              debugPrint(
                '_PlayerAvatarImage load failed url=$url '
                'error=$error stack=$stackTrace',
              );
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _tryNextUrl();
            });
            return _InitialsAvatar(
              player: widget.player,
              imageProvider: null,
              radius: widget.radius,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
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

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({
    required this.player,
    required this.imageProvider,
    required this.radius,
  });

  final Player player;
  final ImageProvider? imageProvider;
  final double radius;

  @override
  Widget build(BuildContext context) {
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
    required this.child,
  });

  final Player player;
  final List<String>? imageUrls;
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
        effectiveMemberId(oldWidget.player) !=
            effectiveMemberId(widget.player)) {
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
