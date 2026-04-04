const DEFAULT_ML_SERVICE_URL = 'http://127.0.0.1:8001';

function toNumber(value, fallback = 0) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
}

function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
}

function rainCityMultiplier(zoneName, rainMm) {
    const zone = String(zoneName || '').toLowerCase();
    if (rainMm < 15) return 1;

    const highRainCities = [
        'mumbai', 'chennai', 'kolkata', 'kochi', 'goa', 'panaji',
        'mangaluru', 'mangalore', 'guwahati', 'shillong', 'agartala',
        'port blair', 'pune',
    ];

    if (!highRainCities.some((city) => zone.includes(city))) return 1;

    const norm = clamp((rainMm - 15) / 65, 0, 1);
    return 1.08 + norm * (1.35 - 1.08);
}

function aqiCityMultiplier(zoneName, usAqi) {
    const zone = String(zoneName || '').toLowerCase();
    if (usAqi < 120) return 1;

    const highAqiCities = [
        'delhi', 'gurgaon', 'gurugram', 'noida', 'ghaziabad', 'faridabad',
        'kanpur', 'lucknow', 'patna', 'varanasi', 'agra', 'ludhiana',
        'amritsar', 'jaipur', 'kolkata',
    ];

    if (!highAqiCities.some((city) => zone.includes(city))) return 1;

    const norm = clamp((usAqi - 120) / 180, 0, 1);
    return 1.10 + norm * (1.45 - 1.10);
}

function fallbackPremiumBreakdown({ readings, zoneName }) {
    const baseRate = 20;

    // ── Rain loading (non-linear, 0–26 INR with city uplift) ───
    const rainMm = toNumber(readings.rainMm);
    const rainNorm = clamp(rainMm / 65, 0, 1);
    const rainCurve = rainNorm ** 3.2 / (rainNorm ** 3.2 + (1 - rainNorm || 0.001) ** 3.2);
    const rainLoad = rainCurve * 26 * rainCityMultiplier(zoneName, rainMm);
    const zoneRisk = Math.round(rainLoad * 100) / 100;

    // ── Heat loading (0–12 INR) ──────────────────────────────────
    const temp = toNumber(readings.temperature);
    let heatDev = 0;
    if (temp > 32) heatDev = clamp((temp - 32) / 16, 0, 1);
    else if (temp < 22) heatDev = clamp((22 - temp) / 17, 0, 1);
    const heatCurve = heatDev ** 2 / (heatDev ** 2 + (1 - heatDev || 0.001) ** 2);
    const weatherVolatility = Math.round(heatCurve * 12 * 100) / 100;

    // ── AQI loading (0–16 INR with city uplift) ──────────────────
    const usAqi = toNumber(readings.usAqi);
    const aqiNorm = clamp(usAqi / 220, 0, 1);
    const aqiCurve = aqiNorm ** 3 / (aqiNorm ** 3 + (1 - aqiNorm || 0.001) ** 3);
    const aqiLoad = Math.round(aqiCurve * 16 * aqiCityMultiplier(zoneName, usAqi) * 100) / 100;

    // zoneRisk in the response = rain + AQI (geography-driven)
    const combinedZoneRisk = Math.round((zoneRisk + aqiLoad) * 100) / 100;

    // ── Mobility loading (0–10 INR, steeper at high congestion) ──
    const mobilityNorm = clamp(toNumber(readings.trafficScore), 0, 1);
    const mobilityCurve = mobilityNorm ** 2.6 / (mobilityNorm ** 2.6 + (1 - mobilityNorm || 0.001) ** 2.6);
    const mobilityRisk = Math.round(mobilityCurve * 10 * 100) / 100;

    const safetyDiscount = 4; // fallback assumes average trust

    return {
        baseRate,
        zoneRisk: combinedZoneRisk,
        weatherVolatility,
        mobilityRisk,
        safetyDiscount,
        aiReason: `Fallback score from live signals for ${zoneName || 'your zone'}: rain ${toNumber(readings.rainMm).toFixed(1)}mm, temp ${toNumber(readings.temperature).toFixed(1)}°C, AQI ${toNumber(readings.usAqi).toFixed(0)}.`,
        modelName: 'fallback-parametric-v4',
        modelConfidence: 0.6,
    };
}

async function scorePremiumWithML({ zoneName, readings, trustScore = 80, workingHours = 9 }) {
    const serviceUrl = String(process.env.ML_PREMIUM_SERVICE_URL || DEFAULT_ML_SERVICE_URL).replace(/\/$/, '');
    const payload = {
        zone: zoneName || 'moderate',
        rainfall_mm: clamp(toNumber(readings.rainMm, 0), 0, 300),
        trust_score: Math.round(clamp(toNumber(trustScore, 80), 0, 100)),
        working_hours: clamp(toNumber(workingHours, 9), 0, 24),
        // ── NEW: pass live signals so Python can score them directly ──
        temperature_c: clamp(toNumber(readings.temperature, 30), -20, 60),
        us_aqi: clamp(toNumber(readings.usAqi, 50), 0, 500),
        traffic_score: clamp(toNumber(readings.trafficScore, 0.3), 0, 1),
    };

    try {
        const response = await fetch(`${serviceUrl}/ml/premium`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
        });

        if (!response.ok) {
            throw new Error(`ML service responded with ${response.status}`);
        }

        const data = await response.json();
        return {
            baseRate: toNumber(data.baseRate, 20),
            zoneRisk: toNumber(data.zoneRisk, 10),
            weatherVolatility: toNumber(data.weatherVolatility, 5),
            mobilityRisk: toNumber(data.mobilityRisk, 5),
            safetyDiscount: toNumber(data.safetyDiscount, 5),
            aiReason: String(data.explanation || 'ML premium score generated.'),
            modelName: String(data.modelName || 'cashurance-parametric-v4'),
            modelConfidence: clamp(toNumber(data.modelConfidence, 0.75), 0, 1),
        };
    } catch (_) {
        return fallbackPremiumBreakdown({ readings, zoneName });
    }
}

module.exports = {
    scorePremiumWithML,
};
