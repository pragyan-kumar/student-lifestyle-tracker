import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/carbon_api_service.dart';
import '../../data/models/carbon_entry.dart';

// ── State ────────────────────────────────────────────────────────────────────

class CarbonCalculatorState {
  final double transportKg;
  final double foodKg;
  final double energyKg;
  final bool isLoading;
  final String? error;
  final double? lastResultKg;
  final List<CarbonEntry> todayEntries;

  const CarbonCalculatorState({
    this.transportKg = 0.0,
    this.foodKg = 0.0,
    this.energyKg = 0.0,
    this.isLoading = false,
    this.error,
    this.lastResultKg,
    this.todayEntries = const [],
  });

  double get totalKg => transportKg + foodKg + energyKg;

  CarbonCalculatorState copyWith({
    double? transportKg,
    double? foodKg,
    double? energyKg,
    bool? isLoading,
    String? error,
    double? lastResultKg,
    List<CarbonEntry>? todayEntries,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return CarbonCalculatorState(
      transportKg: transportKg ?? this.transportKg,
      foodKg: foodKg ?? this.foodKg,
      energyKg: energyKg ?? this.energyKg,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastResultKg: clearResult ? null : (lastResultKg ?? this.lastResultKg),
      todayEntries: todayEntries ?? this.todayEntries,
    );
  }
}

// ── Notifier (Riverpod 3.x Notifier API) ─────────────────────────────────────

class CarbonCalculatorNotifier extends Notifier<CarbonCalculatorState> {
  final _uuid = const Uuid();

  CarbonApiService get _api => ref.read(carbonApiServiceProvider);

  @override
  CarbonCalculatorState build() => const CarbonCalculatorState();

  // ── Transport ──────────────────────────────────────────────────────────────

  Future<void> calculateTransport({
    required String mode,
    required double distanceKm,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearResult: true);
    try {
      double kg = 0.0;

      switch (mode) {
        case 'Walk':
        case 'Bicycle':
          kg = 0.0;
          break;
        case 'Metro':
          kg = 0.041 * distanceKm;
          break;
        case 'Bus':
          kg = await _api.estimateFuelCombustion(fuelType: 'dlo', litres: distanceKm * 0.035);
          break;
        case 'Auto':
          kg = await _api.estimateFuelCombustion(fuelType: 'lpg', litres: distanceKm * 0.06);
          break;
        case 'Car':
          kg = await _api.estimateFuelCombustion(fuelType: 'pet', litres: distanceKm * 0.07);
          break;
        case 'Motorcycle':
          kg = await _api.estimateFuelCombustion(fuelType: 'pet', litres: distanceKm * 0.04);
          break;
      }

      final entry = CarbonEntry(
        id: _uuid.v4(),
        module: 'transport',
        label: mode,
        carbonKg: kg,
        timestamp: DateTime.now(),
        detail: '$mode • ${distanceKm.toStringAsFixed(1)} km',
      );

      state = state.copyWith(
        isLoading: false,
        lastResultKg: kg,
        transportKg: state.transportKg + kg,
        todayEntries: [entry, ...state.todayEntries],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Calculation failed: $e');
    }
  }

  Future<void> calculateFlight({
    required String departure,
    required String destination,
    required int passengers,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearResult: true);
    try {
      double kg = await _api.estimateFlight(
        departure: departure,
        destination: destination,
        passengers: passengers,
      );
      if (kg == 0.0) kg = 90.0 * passengers;

      final entry = CarbonEntry(
        id: _uuid.v4(),
        module: 'transport',
        label: 'Flight',
        carbonKg: kg,
        timestamp: DateTime.now(),
        detail: '$departure → $destination • $passengers pax',
      );

      state = state.copyWith(
        isLoading: false,
        lastResultKg: kg,
        transportKg: state.transportKg + kg,
        todayEntries: [entry, ...state.todayEntries],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Calculation failed: $e');
    }
  }

  // ── Food ───────────────────────────────────────────────────────────────────

  void calculateFood({
    required String foodKey,
    required String foodLabel,
    required double grams,
  }) {
    final kg = _api.estimateFood(foodKey: foodKey, grams: grams);

    final entry = CarbonEntry(
      id: _uuid.v4(),
      module: 'food',
      label: foodLabel,
      carbonKg: kg,
      timestamp: DateTime.now(),
      detail: '$foodLabel • ${grams.toStringAsFixed(0)} g',
    );

    state = state.copyWith(
      lastResultKg: kg,
      foodKg: state.foodKg + kg,
      todayEntries: [entry, ...state.todayEntries],
    );
  }

  // ── Energy ─────────────────────────────────────────────────────────────────

  Future<void> calculateElectricity({
    required double kwh,
    required String country,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearResult: true);
    try {
      final kg = await _api.estimateElectricity(kwh: kwh, country: country);
      final entry = CarbonEntry(
        id: _uuid.v4(),
        module: 'energy',
        label: 'Electricity',
        carbonKg: kg,
        timestamp: DateTime.now(),
        detail: '${kwh.toStringAsFixed(1)} kWh • ${country.toUpperCase()}',
      );
      state = state.copyWith(
        isLoading: false,
        lastResultKg: kg,
        energyKg: state.energyKg + kg,
        todayEntries: [entry, ...state.todayEntries],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Calculation failed: $e');
    }
  }

  Future<void> calculateFuel({
    required String fuelType,
    required String fuelLabel,
    required double litres,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearResult: true);
    try {
      final kg = await _api.estimateFuelCombustion(fuelType: fuelType, litres: litres);
      final entry = CarbonEntry(
        id: _uuid.v4(),
        module: 'energy',
        label: fuelLabel,
        carbonKg: kg,
        timestamp: DateTime.now(),
        detail: '$fuelLabel • ${litres.toStringAsFixed(1)} L',
      );
      state = state.copyWith(
        isLoading: false,
        lastResultKg: kg,
        energyKg: state.energyKg + kg,
        todayEntries: [entry, ...state.todayEntries],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Calculation failed: $e');
    }
  }

  void clearResult() => state = state.copyWith(clearResult: true);

  void reset() => state = const CarbonCalculatorState();
}

// ── Providers ─────────────────────────────────────────────────────────────────

final carbonApiServiceProvider = Provider<CarbonApiService>((_) => CarbonApiService());

final carbonCalculatorProvider =
    NotifierProvider<CarbonCalculatorNotifier, CarbonCalculatorState>(
  CarbonCalculatorNotifier.new,
);
