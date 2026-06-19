class MemberProfileData {
  final String firstName;
  final String lastName;
  final String? birthDay;
  final String? birthPlace;
  final String nationality;
  final List<int> positions;

  const MemberProfileData({
    required this.firstName,
    required this.lastName,
    required this.nationality,
    this.birthDay,
    this.birthPlace,
    this.positions = const [],
  });

  bool get isValid {
    return firstName.trim().isNotEmpty &&
        lastName.trim().isNotEmpty &&
        nationality.trim().isNotEmpty;
  }
}
