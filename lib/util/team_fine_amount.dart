/// Parses a user-entered fine amount that may use `,` or `.` as decimal.
///
/// Returns null when [raw] is empty or not a number.
double? parseFineAmount(String? raw) {
  var value = (raw ?? '').trim().replaceAll('\u00a0', '').replaceAll(' ', '');
  if (value.isEmpty) {
    return null;
  }
  value = value.replaceAll('€', '');
  value = value.replaceAll(RegExp('[^0-9,.-]'), '');
  if (value.isEmpty || value == '-' || value == '.' || value == ',') {
    return null;
  }

  if (value.contains(',') && value.contains('.')) {
    if (value.lastIndexOf(',') > value.lastIndexOf('.')) {
      value = value.replaceAll('.', '').replaceAll(',', '.');
    } else {
      value = value.replaceAll(',', '');
    }
  } else {
    value = value.replaceAll(',', '.');
  }

  return double.tryParse(value);
}

/// Formats [amount] with two decimals and a euro sign (e.g. `5,50 €`).
String formatFineAmount(double amount) {
  final String formatted = amount.toStringAsFixed(2).replaceAll('.', ',');
  return '$formatted €';
}
