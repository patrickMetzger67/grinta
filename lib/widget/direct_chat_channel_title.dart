import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import '../services/direct_chat_peer_directory.dart';
import '../util/direct_chat_identity.dart';

/// Whether this channel should use first name + last name + email (not groups).
bool isDirectChatChannel(Channel channel) {
  final currentId = channel.client.state.currentUser?.id;
  final members = channel.state?.members ?? const <Member>[];
  final otherMemberCount =
      members.where((member) => member.userId != currentId).length;
  return isDirectMessageChannel(
    memberCount: channel.memberCount ?? members.length,
    channelName: channel.name,
    otherMemberCount: otherMemberCount,
  );
}

/// List-row title for a 1:1 conversation: **Prénom Nom** then email.
class DirectChatChannelTitle extends StatelessWidget {
  const DirectChatChannelTitle({
    super.key,
    required this.channel,
    this.titleStyle,
    this.emailStyle,
  });

  final Channel channel;
  final TextStyle? titleStyle;
  final TextStyle? emailStyle;

  @override
  Widget build(BuildContext context) {
    final previewTheme = StreamChannelPreviewTheme.of(context);
    final resolvedTitleStyle = titleStyle ?? previewTheme.titleStyle;
    final resolvedEmailStyle = emailStyle ?? previewTheme.subtitleStyle;
    final membersStream = channel.state?.membersStream;
    final members = channel.state?.members ?? const <Member>[];

    if (membersStream == null) {
      return StreamChannelName(
        channel: channel,
        textStyle: resolvedTitleStyle,
      );
    }

    return BetterStreamBuilder<List<Member>>(
      stream: membersStream,
      initialData: members,
      builder: (context, nextMembers) {
        final other = _otherMember(channel, nextMembers);
        if (other == null) {
          return StreamChannelName(
            channel: channel,
            textStyle: resolvedTitleStyle,
          );
        }

        return _DirectChatPeerTitle(
          peerId: other.userId ?? other.user?.id ?? '',
          streamIdentity: identityFromStreamUser(other.user),
          titleStyle: resolvedTitleStyle,
          emailStyle: resolvedEmailStyle,
        );
      },
    );
  }
}

/// Header title for a 1:1 conversation (same name + email stack).
class DirectChatChannelHeaderTitle extends StatelessWidget {
  const DirectChatChannelHeaderTitle({
    super.key,
    required this.channel,
  });

  final Channel channel;

  @override
  Widget build(BuildContext context) {
    final headerTheme = StreamChannelHeaderTheme.of(context);
    return DirectChatChannelTitle(
      channel: channel,
      titleStyle: headerTheme.titleStyle,
      emailStyle: headerTheme.subtitleStyle,
    );
  }
}

DirectChatIdentity identityFromStreamUser(User? user) {
  return resolveDirectChatIdentity(
    firstName: _extraString(user, 'firstName'),
    lastName: _extraString(user, 'lastName'),
    email: _extraString(user, 'email'),
    streamName: _streamDisplayName(user),
  );
}

Member? _otherMember(Channel channel, List<Member> members) {
  final currentId = channel.client.state.currentUser?.id;
  final others =
      members.where((member) => member.userId != currentId).toList();
  if (others.length != 1) return null;
  return others.first;
}

class _DirectChatPeerTitle extends StatefulWidget {
  const _DirectChatPeerTitle({
    required this.peerId,
    required this.streamIdentity,
    required this.titleStyle,
    required this.emailStyle,
  });

  final String peerId;
  final DirectChatIdentity streamIdentity;
  final TextStyle? titleStyle;
  final TextStyle? emailStyle;

  @override
  State<_DirectChatPeerTitle> createState() => _DirectChatPeerTitleState();
}

class _DirectChatPeerTitleState extends State<_DirectChatPeerTitle> {
  Future<DirectChatPeerProfile>? _future;

  @override
  void initState() {
    super.initState();
    _loadIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _DirectChatPeerTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.peerId != widget.peerId) {
      _future = null;
      _loadIfNeeded();
    }
  }

  void _loadIfNeeded() {
    final peerId = widget.peerId.trim();
    if (peerId.isEmpty) return;
    _future = DirectChatPeerDirectory.instance.load(peerId);
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) {
      return _DirectChatTitleColumn(
        identity: widget.streamIdentity,
        titleStyle: widget.titleStyle,
        emailStyle: widget.emailStyle,
      );
    }

    return FutureBuilder<DirectChatPeerProfile>(
      future: future,
      initialData: DirectChatPeerDirectory.instance.cached(widget.peerId),
      builder: (context, snapshot) {
        return _DirectChatTitleColumn(
          identity: mergeDirectChatIdentity(
            streamIdentity: widget.streamIdentity,
            profileFirstName: snapshot.data?.firstName,
            profileLastName: snapshot.data?.lastName,
            profileEmail: snapshot.data?.email,
          ),
          titleStyle: widget.titleStyle,
          emailStyle: widget.emailStyle,
        );
      },
    );
  }
}

String? _streamDisplayName(User? user) {
  if (user == null) return null;
  final extraName = _extraString(user, 'name');
  if (extraName != null) return extraName;
  final name = user.name.trim();
  if (name.isEmpty || name == user.id) return null;
  return name;
}

String? _extraString(User? user, String key) {
  final value = user?.extraData[key];
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

class _DirectChatTitleColumn extends StatelessWidget {
  const _DirectChatTitleColumn({
    required this.identity,
    required this.titleStyle,
    required this.emailStyle,
  });

  final DirectChatIdentity identity;
  final TextStyle? titleStyle;
  final TextStyle? emailStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          identity.title,
          style: titleStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (identity.email != null && identity.email!.isNotEmpty)
          Text(
            identity.email!,
            style: emailStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
