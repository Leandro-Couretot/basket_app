class Season {
  final String id;
  final String name; // e.g. "2024-2025"
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  const Season({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isActive = false,
  });
}
