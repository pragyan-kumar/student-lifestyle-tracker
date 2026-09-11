/// Represents a single logged carbon emission entry.
class CarbonEntry {
  final String id;
  final String module; // 'transport' | 'food' | 'energy'
  final String label;
  final double carbonKg;
  final DateTime timestamp;
  final String? detail; // e.g. "Car • 12 km" or "Electricity • 5 kWh"

  const CarbonEntry({
    required this.id,
    required this.module,
    required this.label,
    required this.carbonKg,
    required this.timestamp,
    this.detail,
  });
}
