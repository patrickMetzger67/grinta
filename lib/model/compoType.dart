import 'package:cloud_firestore/cloud_firestore.dart';

String keyCompoTypeName = "name";
String keyCompoTypeDefender = "defender";
String keyCompoTypeMidfielder = "midfielder";
String keyCompoTypeMidfielderDefensive = "midfielderDefensive";
String keyCompoTypeMidfielderAttacking = "midfielderAttacking";
String keyCompoTypeStricker ="stricker";
String keyCompoTypeIsDiamond = "diamond";
String keyCompoTypeSoccerType = "soccerType";



class CompoType {

  String? name;
  int? defender;
  int? midfielder;
  int? midfielderDefensive;
  int? midfielderAttacking;
  int? stricker;
  bool? isDiamond;
  int? soccerType;
  DocumentReference? ref;

  CompoType({
    this.name,
    this.defender,
    this.midfielder,
    this.midfielderDefensive,
    this.midfielderAttacking,
    this.stricker,
    this.isDiamond,
    this.soccerType,
  });

  CompoType.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    ref = snapshot.reference;
    name = snapshot.get(keyCompoTypeName);
    defender = snapshot.get(keyCompoTypeDefender);
    midfielder  = snapshot.get(keyCompoTypeMidfielder);
    midfielderDefensive = snapshot.get(keyCompoTypeMidfielderDefensive);
    midfielderAttacking = snapshot.get(keyCompoTypeMidfielderAttacking);
    stricker = snapshot.get(keyCompoTypeStricker);
    isDiamond = snapshot.get(keyCompoTypeIsDiamond);
    soccerType = snapshot.get(keyCompoTypeSoccerType);
  }

  @override
  String toString() {
    // TODO: implement toString
    return "compoType: name=$name " +
      "defender=$defender " +
      "midfielder=$midfielder " +
      "midfielderDefensive=$midfielderDefensive " +
      "midfielderAttacking=$midfielderAttacking " +
      "stricker=$stricker " +
      "isDiamond=$isDiamond " +
      "soccerType=$soccerType ";
  }


}