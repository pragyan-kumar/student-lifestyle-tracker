import 'package:dio/dio.dart';

/// Service that wraps the Carbon Interface REST API.
/// Docs: https://docs.carboninterface.com/
///
/// Fallback offline emission factors are used automatically when the API
/// call fails (e.g. network error or invalid key).
class CarbonApiService {
  static const _apiKey = 'gOSPgLHFs7k4E23EUNWDw';
  static const _baseUrl = 'https://www.carboninterface.com/api/v1/estimates';

  late final Dio _dio;

  CarbonApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
    ));
  }

  // ── Transport ────────────────────────────────────────────────────────────

  /// Estimates CO₂ from fuel combustion for road transport.
  /// [fuelType]: 'pet' (petrol), 'dlo' (diesel), 'lpg'
  /// [litres]: estimated fuel consumed
  Future<double> estimateFuelCombustion({
    required String fuelType,
    required double litres,
  }) async {
    try {
      final response = await _dio.post('', data: {
        'type': 'fuel_combustion',
        'fuel_source_type': fuelType,
        'fuel_source_unit': 'l',
        'fuel_source_value': litres,
      });
      return (response.data['data']['attributes']['carbon_kg'] as num).toDouble();
    } catch (_) {
      // Offline fallback: IPCC emission factors (kg CO₂ per litre)
      const factors = {'pet': 2.31, 'dlo': 2.68, 'lpg': 1.51, 'ng': 2.04};
      return litres * (factors[fuelType] ?? 2.31);
    }
  }

  /// Estimates CO₂ for a flight between two IATA airport codes.
  Future<double> estimateFlight({
    required String departure,
    required String destination,
    required int passengers,
  }) async {
    try {
      final response = await _dio.post('', data: {
        'type': 'flight',
        'passengers': passengers,
        'legs': [
          {'departure_airport': departure.toUpperCase(), 'destination_airport': destination.toUpperCase()},
        ],
      });
      return (response.data['data']['attributes']['carbon_kg'] as num).toDouble();
    } catch (_) {
      // Offline fallback: ~0.255 kg CO₂ per km per passenger (ICAO avg)
      return 0.0; // can't estimate without distance; caller handles this
    }
  }

  // ── Energy ──────────────────────────────────────────────────────────────

  /// Estimates CO₂ from electricity consumption.
  /// [country]: ISO 3166-1 alpha-2 code, e.g. 'in' for India
  Future<double> estimateElectricity({
    required double kwh,
    String country = 'in',
  }) async {
    try {
      final response = await _dio.post('', data: {
        'type': 'electricity',
        'electricity_unit': 'kwh',
        'electricity_value': kwh,
        'country': country.toLowerCase(),
      });
      return (response.data['data']['attributes']['carbon_kg'] as num).toDouble();
    } catch (_) {
      // Offline fallback: India grid emission factor ~0.82 kg CO₂/kWh (CEA 2023)
      const gridFactors = {
        'in': 0.82, 'us': 0.38, 'gb': 0.23, 'de': 0.40, 'au': 0.56,
      };
      return kwh * (gridFactors[country.toLowerCase()] ?? 0.70);
    }
  }

  // ── Food (offline IPCC / Poore & Nemecek 2018 factors) ─────────────────

  /// Returns kg CO₂e per 100g of food item.
  static double foodEmissionFactor(String foodKey) {
    const factors = {
      'beef':       2.70,   // 27 kg/kg → per 100g
      'lamb':       3.92,
      'pork':       1.22,
      'chicken':    0.69,
      'fish':       0.61,
      'eggs':       0.43,
      'dairy':      0.32,
      'rice':       0.27,
      'wheat':      0.15,
      'vegetables': 0.20,
      'fruits':     0.14,
      'lentils':    0.09,
      'tofu':       0.20,
      'nuts':       0.26,
    };
    return factors[foodKey] ?? 0.20;
  }

  /// Calculate food CO₂ offline (no API call needed).
  double estimateFood({required String foodKey, required double grams}) {
    return foodEmissionFactor(foodKey) * (grams / 100.0);
  }
}
