import 'package:flutter/material.dart';
import 'package:grinta/screen/agendaScreen.dart';

import '../homeScreen.dart';
import '../webNavigationShell.dart';


class WebAppRoot extends StatelessWidget {
  const WebAppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return WebNavigationShell(
      appTitle: 'Grinta',
      appIcon: Icons.sports_soccer_rounded,
      initialIndex: 0,
      items: [
        const WebShellItem(
          label: 'Tableau de bord',
          icon: Icons.dashboard_outlined,
          page: HomeScreen(),
        ),
        
        WebShellItem(
          label: 'Agenda',
          icon: Icons.calendar_month_outlined,
          page:AgendaScreen(
            loadItems: ({
              required DateTime start,
              required DateTime end,
            }) async {
              final allItems = <AgendaItem>[
                AgendaItem(
                  id: '1',
                  startAt: DateTime.now().add(const Duration(days: 1, hours: 18)),
                  endAt: DateTime.now().add(const Duration(days: 1, hours: 20)),
                  title: 'Match contre FC Rivière',
                  subtitle: 'Stade municipal',
                  type: AgendaItemType.match,
                ),
                AgendaItem(
                  id: '2',
                  startAt: DateTime.now().add(const Duration(days: 2, hours: 17)),
                  endAt: DateTime.now().add(const Duration(days: 2, hours: 19)),
                  title: 'Entraînement collectif',
                  subtitle: 'Terrain annexe',
                  type: AgendaItemType.entrainement,
                ),
                AgendaItem(
                  id: '3',
                  startAt: DateTime.now().add(const Duration(days: 4, hours: 9)),
                  endAt: DateTime.now().add(const Duration(days: 4, hours: 10)),
                  title: 'Préparation physique',
                  subtitle: 'Salle de sport',
                  type: AgendaItemType.preparationPhysique,
                ),
              ];

              return allItems.where((item) {
                return item.startAt.millisecondsSinceEpoch >= start.millisecondsSinceEpoch &&
                    item.startAt.millisecondsSinceEpoch <= end.millisecondsSinceEpoch;
              }).toList()
                ..sort((a, b) => a.startAt.compareTo(b.startAt));
            },
            onAddEvent: () {
              // ouvrir l'écran de création
            },
          )
        ),
        /*
        WebShellItem(
          label: 'Club',
          icon: Icons.shield_outlined,
          page: ClubScreen(),
        ),*/
      ],
    );
  }
}