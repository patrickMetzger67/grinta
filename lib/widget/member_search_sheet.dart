import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/widget/create_member_sheet.dart';
import 'package:grinta/widget/playerPhoto.dart';
import 'package:grinta/widget/player_contact_lines.dart';

/// Shows a searchable bottom sheet to pick an existing [Player] member.
Future<Player?> showMemberSearchSheet(
  BuildContext context, {
  required String title,
  Set<String> excludeMemberIds = const <String>{},
  bool showCreateButton = false,
}) {
  return showModalBottomSheet<Player>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useRootNavigator: false,
    builder: (_) => MemberSearchSheet(
      title: title,
      excludeMemberIds: excludeMemberIds,
      showCreateButton: showCreateButton,
    ),
  );
}

class MemberSearchSheet extends StatefulWidget {
  const MemberSearchSheet({
    super.key,
    required this.title,
    this.excludeMemberIds = const <String>{},
    this.showCreateButton = false,
  });

  final String title;
  final Set<String> excludeMemberIds;
  final bool showCreateButton;

  @override
  State<MemberSearchSheet> createState() => _MemberSearchSheetState();
}

class _MemberSearchSheetState extends State<MemberSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final PlayerService _playerService = PlayerService();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = _searchController.text);
    });
  }

  String _firestoreSearchToken(String query) {
    final tokens = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) {
      return '';
    }
    return tokens.first;
  }

  List<String> _queryTokens(String query) {
    return query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
  }

  bool _matchesAllTokens(Player player, List<String> tokens) {
    if (tokens.isEmpty) {
      return false;
    }

    final String displayName =
        playerDisplayName(player, unknownLabel: '').toLowerCase();
    final Iterable<String> searchOptions = (player.searchOptions ?? const [])
        .map((value) => value.toString().toLowerCase());

    return tokens.every(
      (token) =>
          displayName.contains(token) ||
          searchOptions.any(
            (option) => option.startsWith(token) || option.contains(token),
          ),
    );
  }

  bool _isExcluded(Player player) {
    final String? memberId = effectiveMemberId(player);
    if (memberId != null && widget.excludeMemberIds.contains(memberId)) {
      return true;
    }

    final String userId = player.userID?.trim() ?? '';
    if (userId.isNotEmpty && widget.excludeMemberIds.contains(userId)) {
      return true;
    }

    return false;
  }

  Future<void> _onCreateMemberPressed() async {
    final Player? created = await showCreateMemberSheet(context);
    if (created != null && mounted) {
      Navigator.pop(context, created);
    }
  }

  List<Player> _filterResults(List<Player> players) {
    final tokens = _queryTokens(_query);
    if (tokens.isEmpty) {
      return const <Player>[];
    }

    final results = players
        .where((player) => !_isExcluded(player))
        .where((player) => _matchesAllTokens(player, tokens))
        .toList();

    for (final player in results) {
      normalizePlayerMemberId(player);
    }

    results.sort(
      (a, b) => playerDisplayName(a).toLowerCase().compareTo(
            playerDisplayName(b).toLowerCase(),
          ),
    );
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.sizeOf(context).height;
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final height = deviceHeight - (statusBarHeight + (kToolbarHeight / 1.5));
    final l10n = context.l10n;
    final colors = context.appColors;
    final searchToken = _firestoreSearchToken(_query);

    final fabBottomPadding = widget.showCreateButton ? 88.0 : 0.0;

    return SizedBox(
      height: height,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: widget.showCreateButton
            ? FloatingActionButton(
                heroTag: 'grinta-fab-member-search-create',
                tooltip: l10n.actionCreatePlayer,
                onPressed: _onCreateMemberPressed,
                child: const Icon(Icons.person_add_outlined),
              )
            : null,
        body: Column(
          children: [
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 14),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: l10n.actionBack,
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.hintSearchMember,
                  hintText: l10n.hintSearchMember,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: const Color(0xFF8C98A8).withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: searchToken.isEmpty
                  ? Center(
                      child: Text(
                        l10n.memberSearchPrompt,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : StreamBuilder<List<Player>>(
                      stream: _playerService.streamMembersBySearchOptions(
                        searchToken,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final members =
                            _filterResults(snapshot.data ?? const []);

                        if (members.isEmpty) {
                          return Center(
                            child: Text(
                              l10n.emptyNoData,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.only(bottom: fabBottomPadding),
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                          final member = members[index];
                          final name = playerDisplayName(
                            member,
                            unknownLabel: l10n.entityPlayerUnknown,
                          );

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(context, member),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    PlayerPhoto(player: member),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          PlayerContactLines(player: member),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
