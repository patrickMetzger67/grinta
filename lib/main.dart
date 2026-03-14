import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dummyData.dart';


void main() => runApp(MyApp());
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: <LocalizationsDelegate<dynamic>>[
    DefaultMaterialLocalizations.delegate,
    DefaultWidgetsLocalizations.delegate,
    DefaultCupertinoLocalizations.delegate,
    ],
    title: 'Flutter Demo',
    theme: CupertinoThemeData(brightness: Brightness.light),
    home: MaterialPage(),
    );
  }
}
class MaterialPage extends StatefulWidget {
  final String title;

  MaterialPage({Key key, this.title}) : super(key: key);
  @override
  _MaterialPageState createState() {
      return _MaterialPageState();
  }
}

class _MaterialPageState extends State<MaterialPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recettes'),
        actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Ajouter une recette',
          onPressed: () {
          },
        ),
        ]
      ),

      body: _buildBody(context),

    );
  }

  Widget _buildBody(BuildContext context) {
    // TODO A récupérer de cloud firestore
   return _buildList(context, dummyMonthResults);
  }
  Widget _buildList(BuildContext context, List<Map> snapshot ) {
    return ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
    );
  }
  Widget _buildListItem(BuildContext context, Map data) {
    final record = Record.fromMap(data);
    var f = new NumberFormat("###,###.00", "fr_FR");
    return
      Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.album),
            title: Text(record.month.toString()),
            subtitle: Text(f.format(record.clubHouse).toString()),
          ),
          ButtonBar(
            children: <Widget>[
              FlatButton(
                child: const Text('BUY TICKETS'),
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => CupertinoPage(
                        title: "Cupertino Page",
                      ),
                    ),
                  );
                }, // OnPressed
              ),
              FlatButton(
                child: const Text('LISTEN'),
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => CupertinoPage(
                        title: "Cupertino Page",
                      ),
                    ),
                  );
                }, // OnPressed
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class CupertinoPage extends StatelessWidget {
  CupertinoPage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
      ),
      child:
      Center(
          child:
          CupertinoButton.filled(
            child: Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => MaterialPage(
                    title: "Second Page Sir",
                  ),
                ),
              );
            },
          )
      ),
    );
  }
}

class Record {
  final String month;
  final double clubHouse;
  final double recetteEquipe1;
  final double recetteEquipe2;

  final DocumentReference reference;

  Record.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['month'] != null),
        assert(map['clubHouse'] != null),
        assert(map['RecetteEquipe1'] != null),
        assert(map['RecetteEquipe2'] != null),
        month = map['month'],
        clubHouse = map['clubHouse'],
        recetteEquipe1 = map['RecetteEquipe1'],
        recetteEquipe2 = map['RecetteEquipe2'];

      Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  @override
  String toString() => "Record<$month:$clubHouse:$recetteEquipe1:$recetteEquipe2>";
}