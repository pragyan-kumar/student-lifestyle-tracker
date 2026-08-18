const axios    = require('axios');
const { logger } = require('../../utils/logger');

const CARBON_API_BASE = 'https://www.carboninterface.com/api/v1';
const API_KEY = process.env.CARBON_INTERFACE_API_KEY;

/**
 * Calls Carbon Interface API for vehicle emission estimate.
 * Returns null if API key not configured or request fails.
 */
const callCarbonInterfaceAPI = async (commute) => {
  if (!API_KEY) return null;

  const vehicleTypeMap = {
    car_petrol : 'passenger_vehicle',
    car_diesel : 'passenger_vehicle',
    bus        : 'bus',
    auto       : 'taxi',
  };

  const vehicleType = vehicleTypeMap[commute.mode];
  if (!vehicleType) return null;  // walk/bike/metro don't need API call

  try {
    const { data } = await axios.post(
      `${CARBON_API_BASE}/estimates`,
      {
        type           : 'vehicle',
        distance_unit  : 'km',
        distance_value : commute.distanceKm,
        vehicle_model_id: process.env.CARBON_API_VEHICLE_MODEL_ID || '7268a9b7-17e8-4c8d-acca-57059252afe9',
      },
      { headers: { Authorization: `Bearer ${API_KEY}`, 'Content-Type': 'application/json' } },
    );

    return {
      carbonKg: data.data.attributes.carbon_kg,
      source  : 'carbon_interface_api',
    };
  } catch (err) {
    logger.warn('Carbon Interface API call failed:', err.message);
    return null;
  }
};

module.exports = { callCarbonInterfaceAPI };
