const GEO_ENDPOINT = 'https://geocoding-api.open-meteo.com/v1/search';
const WEATHER_ENDPOINT = 'https://api.open-meteo.com/v1/forecast';
const AIR_ENDPOINT = 'https://air-quality-api.open-meteo.com/v1/air-quality';

const coordinateCache = new Map();

function toNumber(value, fallback = 0) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
}

function normalizeZoneName(zoneName) {
    const raw = String(zoneName || '').trim();
    if (!raw) return 'Bengaluru';
    const parts = raw.split(',').map((p) => p.trim()).filter(Boolean);
    return parts[0] || raw;
}

function eventId(prefix, zoneName) {
    const stamp = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const zone = String(zoneName || 'GEN')
        .toUpperCase()
        .replace(/[^A-Z0-9]+/g, '-')
        .slice(0, 12);
    return `${prefix}-${zone}-${stamp}`;
}

function riskLevelFromRain(mm) {
    if (mm >= 30) return 'High';
    if (mm >= 10) return 'Moderate';
    return 'Low';
}

function riskLevelFromHeat(celsius) {
    if (celsius >= 43) return 'High';
    if (celsius >= 38) return 'Moderate';
    return 'Low';
}

function riskLevelFromAqi(aqi) {
    if (aqi >= 150) return 'High';
    if (aqi >= 80) return 'Moderate';
    return 'Good';
}

function trafficIndex({ rainMm, usAqi, hour }) {
    let score = 0.2;
    if (rainMm >= 10) score += 0.35;
    if (usAqi >= 100) score += 0.25;
    if ((hour >= 8 && hour <= 11) || (hour >= 17 && hour <= 21)) score += 0.2;
    return Math.min(1, score);
}

function eventSeverity(level) {
    if (level === 'High') return 'catastrophic';
    if (level === 'Moderate') return 'severe';
    return 'normal';
}

function eventZoneStatus(level) {
    if (level === 'High') return 'triggered';
    if (level === 'Moderate') return 'watchlist';
    return 'stable';
}

async function resolveCoordinates(zoneName) {
    const zone = normalizeZoneName(zoneName);
    if (coordinateCache.has(zone)) {
        return coordinateCache.get(zone);
    }

    try {
        const url = `${GEO_ENDPOINT}?name=${encodeURIComponent(zone)}&count=1&language=en&format=json`;
        const response = await fetch(url);
        if (!response.ok) {
            throw new Error(`Geocoding failed with status ${response.status}`);
        }
        const payload = await response.json();
        const first = payload?.results?.[0];
        if (!first) {
            throw new Error('No geocoding results found');
        }

        const coords = {
            latitude: toNumber(first.latitude, 12.9716),
            longitude: toNumber(first.longitude, 77.5946),
            zoneLabel: `${first.name || zone}${first.country ? `, ${first.country}` : ''}`,
        };
        coordinateCache.set(zone, coords);
        return coords;
    } catch (_) {
        const fallback = {
            latitude: 12.9716,
            longitude: 77.5946,
            zoneLabel: zone,
        };
        coordinateCache.set(zone, fallback);
        return fallback;
    }
}

async function fetchLiveSignals(zoneName) {
    let location;
    if (typeof zoneName === 'object' && zoneName !== null) {
        const payload = zoneName;
        const hasCoords = Number.isFinite(Number(payload.latitude)) && Number.isFinite(Number(payload.longitude));
        if (hasCoords) {
            location = {
                latitude: toNumber(payload.latitude, 12.9716),
                longitude: toNumber(payload.longitude, 77.5946),
                zoneLabel: String(payload.zoneName || payload.zoneLabel || 'Custom Zone'),
            };
        } else {
            location = await resolveCoordinates(payload.zoneName || payload.zoneLabel || 'Bengaluru');
        }
    } else {
        location = await resolveCoordinates(zoneName);
    }
    const { latitude, longitude } = location;

    const weatherUrl = `${WEATHER_ENDPOINT}?latitude=${latitude}&longitude=${longitude}&current=temperature_2m,precipitation,weather_code&hourly=temperature_2m,precipitation_probability,precipitation&forecast_days=1&timezone=auto`;
    const airUrl = `${AIR_ENDPOINT}?latitude=${latitude}&longitude=${longitude}&current=us_aqi,pm2_5,pm10&timezone=auto`;

    const [weatherRes, airRes] = await Promise.all([fetch(weatherUrl), fetch(airUrl)]);

    if (!weatherRes.ok || !airRes.ok) {
        throw new Error('Failed to fetch Open-Meteo live signals');
    }

    const [weather, air] = await Promise.all([weatherRes.json(), airRes.json()]);

    const temperature = toNumber(weather?.current?.temperature_2m, 0);
    const rainMm = toNumber(weather?.current?.precipitation, 0);
    const usAqi = toNumber(air?.current?.us_aqi, 0);
    const pm25 = toNumber(air?.current?.pm2_5, 0);
    const pm10 = toNumber(air?.current?.pm10, 0);
    const nowHour = new Date().getHours();
    const trafficScore = trafficIndex({ rainMm, usAqi, hour: nowHour });

    const rainLevel = riskLevelFromRain(rainMm);
    const heatLevel = riskLevelFromHeat(temperature);
    const aqiLevel = riskLevelFromAqi(usAqi);
    const trafficLevel = trafficScore > 0.75 ? 'High' : (trafficScore > 0.45 ? 'Moderate' : 'Normal');

    const riskFeed = [
        { label: 'Rain', level: rainLevel, icon: 'R' },
        { label: 'Heat', level: heatLevel, icon: 'H' },
        { label: 'AQI', level: aqiLevel, icon: 'A' },
        { label: 'Traffic', level: trafficLevel, icon: 'T' },
    ];

    const triggerAlerts = [
        {
            eventType: 'flood',
            severity: eventSeverity(rainLevel),
            zoneStatus: eventZoneStatus(rainLevel),
            eventId: eventId('FLD', location.zoneLabel),
            dataSource: 'Open-Meteo Forecast API',
            timestamp: new Date().toISOString(),
            metrics: { rainMm },
        },
        {
            eventType: 'heat',
            severity: eventSeverity(heatLevel),
            zoneStatus: eventZoneStatus(heatLevel),
            eventId: eventId('HEAT', location.zoneLabel),
            dataSource: 'Open-Meteo Forecast API',
            timestamp: new Date().toISOString(),
            metrics: { temperature },
        },
        {
            eventType: 'aqi',
            severity: eventSeverity(aqiLevel),
            zoneStatus: eventZoneStatus(aqiLevel),
            eventId: eventId('AQI', location.zoneLabel),
            dataSource: 'Open-Meteo Air Quality API',
            timestamp: new Date().toISOString(),
            metrics: { usAqi, pm25, pm10 },
        },
        {
            eventType: 'traffic',
            severity: eventSeverity(trafficLevel === 'Normal' ? 'Low' : trafficLevel),
            zoneStatus: eventZoneStatus(trafficLevel === 'Normal' ? 'Low' : trafficLevel),
            eventId: eventId('TRF', location.zoneLabel),
            dataSource: 'Derived Mobility Stress (Open-Meteo Weather + AQI)',
            timestamp: new Date().toISOString(),
            metrics: { trafficScore: Number(trafficScore.toFixed(2)) },
        },
    ];

    return {
        location,
        readings: {
            temperature,
            rainMm,
            usAqi,
            pm25,
            pm10,
            trafficScore: Number(trafficScore.toFixed(2)),
        },
        riskFeed,
        triggerAlerts,
    };
}

module.exports = {
    fetchLiveSignals,
};
