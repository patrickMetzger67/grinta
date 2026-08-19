import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Picks a Stream user, excluding the current account and [excludeUserIds].
Future<User?> showChatUserPicker(
  BuildContext context, {
  Iterable<String> excludeUserIds = const [],
  String? title,
}) {
  return Navigator.of(context).push<User>(
    analyticsMaterialRoute<User>(
      screenName: AnalyticsScreenNames.chatUserPicker,
      builder: (_) => ChatUserPickerPage(
        excludeUserIds: excludeUserIds,
        title: title,
      ),
    ),
  );
}

class ChatUserPickerPage extends StatefulWidget {
  const ChatUserPickerPage({
    super.key,
    this.excludeUserIds = const [],
    this.title,
  });

  final Iterable<String> excludeUserIds;
  final String? title;

  @override
  State<ChatUserPickerPage> createState() => _ChatUserPickerPageState();
}

class _ChatUserPickerPageState extends State<ChatUserPickerPage> {
  StreamUserListController? _userListController;
  String? _currentUserId;
  late final TextEditingController _searchController;

  Set<String> get _excluded {
    return {
      ...widget.excludeUserIds.map((id) => id.trim()).where((id) => id.isNotEmpty),
      if (_currentUserId != null) _currentUserId!,
    };
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final currentUserId = StreamChat.of(context).currentUser?.id;
    if (currentUserId == null) return;

    if (_userListController == null || _currentUserId != currentUserId) {
      _currentUserId = currentUserId;
      _userListController?.dispose();
      _userListController = StreamUserListController(
        client: StreamChat.of(context).client,
        limit: 25,
        filter: _filter(''),
        sort: const [SortOption.asc('name')],
      );
    }
  }

  Filter _filter(String query) {
    final queryText = query.trim();
    final excluded = _excluded.toList();
    final filters = <Filter>[
      if (excluded.isNotEmpty) Filter.notIn('id', List<Object>.from(excluded)),
      if (queryText.isNotEmpty) Filter.autoComplete('name', queryText),
    ];
    if (filters.isEmpty) return const Filter.empty();
    if (filters.length == 1) return filters.first;
    return Filter.and(filters);
  }

  void _applySearch(String value) {
    if (_userListController == null) return;
    _userListController!.filter = _filter(value);
    _userListController!.doInitialLoad();
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _userListController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final title = widget.title ?? context.l10n.dialogNewConversation;

    if (_userListController == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: CircularProgressIndicator(color: colors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _applySearch,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: context.l10n.hintSearchUser,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colors.textSecondary,
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _applySearch('');
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: colors.textSecondary,
                        ),
                      ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: colors.primary,
              backgroundColor: colors.surface,
              onRefresh: _userListController!.refresh,
              child: StreamUserListView(
                controller: _userListController!,
                onUserTap: (user) => Navigator.of(context).pop(user),
                itemBuilder: (context, users, index, defaultWidget) {
                  final user = users[index];
                  if (_excluded.contains(user.id)) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.border),
                    ),
                    child: defaultWidget.copyWith(
                      onTap: () => Navigator.of(context).pop(user),
                    ),
                  );
                },
                emptyBuilder: (context) {
                  final hasSearch = _searchController.text.trim().isNotEmpty;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        hasSearch
                            ? context.l10n.emptyNoUserFound
                            : context.l10n.emptyNoUserAvailable,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
