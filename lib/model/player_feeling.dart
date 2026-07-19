/// Échelle "Comment te sens-tu ?" — 1 (très mal) → 5 (très bien).
enum PlayerFeeling {
  veryBad(1),
  bad(2),
  neutral(3),
  good(4),
  veryGood(5);

  const PlayerFeeling(this.value);
  final int value;

  static PlayerFeeling? fromValue(int? value) {
    if (value == null) return null;
    for (final feeling in PlayerFeeling.values) {
      if (feeling.value == value) return feeling;
    }
    return null;
  }
}
