import 'package:cloud_firestore/cloud_firestore.dart';

class ComptetionGroup {
  final String id;
  final String seasonId;
  final String comptetitonId;
  final String phase;
  final String groupe;
  final List<String> clubIds;

  const ComptetionGroup({
    required this.id,
    required this.seasonId,
    required this.comptetitonId,
    required this.phase,
    required this.groupe,
    required this.clubIds,
  });

  /// Génère l'id :
  /// seasonId_competitionId_phase_groupe
  static String buildId({
    required String seasonId,
    required String comptetitonId,
    required String phase,
    required String groupe,
  }) {
    return [
      seasonId,
      comptetitonId,
      phase,
      groupe,
    ].map(_safeIdPart).join('_');
  }

  /// Évite les caractères problématiques dans un ID Firestore
  static String _safeIdPart(String value) {
    return value
        .trim()
        .replaceAll('/', '-')
        .replaceAll('\\', '-')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  factory ComptetionGroup.create({
    required String seasonId,
    required String comptetitonId,
    required String phase,
    required String groupe,
    List<String> clubIds = const [],
  }) {
    final id = ComptetionGroup.buildId(
      seasonId: seasonId,
      comptetitonId: comptetitonId,
      phase: phase,
      groupe: groupe,
    );

    return ComptetionGroup(
      id: id,
      seasonId: seasonId,
      comptetitonId: comptetitonId,
      phase: phase,
      groupe: groupe,
      clubIds: clubIds,
    );
  }

  factory ComptetionGroup.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};

    return ComptetionGroup.fromMap(
      data,
      fallbackId: doc.id,
    );
  }

  factory ComptetionGroup.fromMap(
      Map<String, dynamic> map, {
        String? fallbackId,
      }) {
    return ComptetionGroup(
      id: (map['id'] ?? fallbackId ?? '').toString(),
      seasonId: (map['seasonId'] ?? '').toString(),
      comptetitonId: (map['comptetitonId'] ?? '').toString(),
      phase: (map['phase'] ?? '').toString(),
      groupe: (map['groupe'] ?? '').toString(),
      clubIds: (map['clubIds'] as List?)
          ?.map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList() ??
          <String>[],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seasonId': seasonId,
      'comptetitonId': comptetitonId,
      'phase': phase,
      'groupe': groupe,
      'clubIds': clubIds,
    };
  }

  ComptetionGroup copyWith({
    String? id,
    String? seasonId,
    String? comptetitonId,
    String? phase,
    String? groupe,
    List<String>? clubIds,
  }) {
    return ComptetionGroup(
      id: id ?? this.id,
      seasonId: seasonId ?? this.seasonId,
      comptetitonId: comptetitonId ?? this.comptetitonId,
      phase: phase ?? this.phase,
      groupe: groupe ?? this.groupe,
      clubIds: clubIds ?? this.clubIds,
    );
  }
}