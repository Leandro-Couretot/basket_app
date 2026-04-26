class Team {
  final String id;
  final String name;
  final String? logoUrl;
  final String? city;

  const Team({
    required this.id,
    required this.name,
    this.logoUrl,
    this.city,
  });
}
