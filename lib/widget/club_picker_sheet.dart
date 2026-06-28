import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/club.dart';
import 'package:grinta/services/clubService.dart';
import 'package:grinta/util/app_theme.dart';

/// Shows a searchable bottom sheet to pick a club.
Future<Club?> showClubPickerSheet(BuildContext context) {
  return showModalBottomSheet<Club>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const ClubPickerSheet(),
  );
}

class ClubPickerSheet extends StatefulWidget {
  const ClubPickerSheet({super.key});

  @override
  State<ClubPickerSheet> createState() => _ClubPickerSheetState();
}

class _ClubPickerSheetState extends State<ClubPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ClubService _clubService = ClubService();
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

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.sizeOf(context).height;
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final height = deviceHeight - (statusBarHeight + (kToolbarHeight / 1.5));
    final l10n = context.l10n;
    final colors = context.appColors;

    return SizedBox(
      height: height,
      child: Column(
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
                    l10n.teamCreationSelectClub,
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
                labelText: l10n.hintSearchClub,
                hintText: l10n.hintSearchClub,
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
            child: StreamBuilder<List<Club>>(
              stream: _clubService.searchClubs(_query),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final clubs = snapshot.data ?? const <Club>[];

                if (clubs.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.emptyNoData,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: clubs.length,
                  itemBuilder: (context, index) {
                    final club = clubs[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final affiliation = club.affiliation?.trim();
                          if (affiliation == null || affiliation.isEmpty) {
                            return;
                          }
                          Navigator.pop(context, club);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              ClubLogo(url: club.logo ?? ''),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      club.name ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    if ((club.city ?? '').trim().isNotEmpty)
                                      Text(
                                        club.city!.trim(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: colors.textSecondary,
                                              fontWeight: FontWeight.normal,
                                            ),
                                      ),
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
    );
  }
}

class ClubLogo extends StatelessWidget {
  const ClubLogo({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final safeUrl = url.trim();

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border),
      ),
      child: Center(
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: safeUrl.isEmpty
              ? Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: colors.textSecondary,
                )
              : Image.network(
                  safeUrl,
                  key: ValueKey(safeUrl),
                  fit: BoxFit.contain,
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.broken_image_outlined,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                ),
        ),
      ),
    );
  }
}
