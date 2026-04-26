class Player {
  final String id;
  final String firstName;
  final String lastName;
  final int number;
  final String position; // PG, SG, SF, PF, C
  final String teamId;
  final String? photoUrl;

  const Player({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.number,
    required this.position,
    required this.teamId,
    this.photoUrl,
  });

  String get fullName => '$firstName $lastName';
}
