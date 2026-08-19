import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/confirm_delete_dialog.dart';

void main() {
  testWidgets('shows the failure inside the open dialog, not a SnackBar',
      (WidgetTester tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          extensions: const <ThemeExtension<dynamic>>[AppColors.light],
        ),
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () {
                  showConfirmDeleteDialog(
                    context: context,
                    title: l10n.teamDetailConfirmDeleteTitle,
                    message: l10n.teamDetailConfirmRemovePlayerTeam('2.3'),
                    onConfirm: () async {
                      throw Exception(
                        '[cloud_firestore/permission-denied] Missing or insufficient permissions.',
                      );
                    },
                  );
                },
                child: const Text('open-delete'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-delete'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.teamDetailConfirmDeleteTitle), findsOneWidget);
    await tester.tap(find.text(l10n.actionDelete));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('confirmDeleteDialogError')), findsOneWidget);
    expect(find.text(l10n.errorDeletePermissionDenied), findsOneWidget);
    expect(find.text(l10n.teamDetailConfirmDeleteTitle), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });
}
