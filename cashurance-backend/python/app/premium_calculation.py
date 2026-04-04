"""Premium scoring engine for CashUrance – v2.

Design goals
────────────
1. **No double-counting**: each live signal (rain, heat, AQI, traffic)
   contributes exactly ONE independent loading. They are never compounded
   through a shared "risk score" that is then re-added.
2. **City-sensitive**: a rider in Delhi under 50 mm rain will get a
   meaningfully higher premium than one in Coimbatore with 0 mm rain,
   because the rain loading is derived directly from the live rainfall
   reading.
3. **Non-linear curves**: real-world insurance loads faster at the extremes.
   A drizzle (2 mm) barely moves the premium; a cloudburst (80 mm) sends
   it to the cap.  Same idea for heat, AQI and traffic stress.
4. **Transparent breakdown**: every component is explained in INR so
   the rider can see exactly why their premium is what it is.

Premium formula
───────────────
  Premium = Base + Rain_Loading + Heat_Loading + AQI_Loading
            + Mobility_Loading − Safety_Discount

Each loading has its own input range, curve, and INR cap so they
cannot interfere with each other.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Union


# ───────────────────────── constants ──────────────────────────
BASE_RATE_INR = 20.0

# Per-component INR caps  (min_load, max_load)
RAIN_LOAD_RANGE    = (0.0, 26.0)   # 0 → 26 INR (more aggressive for heavy rain)
HEAT_LOAD_RANGE    = (0.0, 12.0)   # 0 → 12 INR
AQI_LOAD_RANGE     = (0.0, 16.0)   # 0 → 16 INR (aggressive for polluted air)
MOBILITY_LOAD_RANGE = (0.0, 10.0)  # 0 → 10 INR
SAFETY_DISC_RANGE  = (0.0, 8.0)    # 0 → 8  INR discount

# Input normalization anchors
RAIN_ANCHOR_MM      = 65.0    # mm at which rain loading saturates
HEAT_COMFORT_LOW    = 22.0    # °C – lower comfort bound
HEAT_COMFORT_HIGH   = 32.0    # °C – upper comfort bound
HEAT_EXTREME        = 48.0    # °C – loading saturates
COLD_EXTREME        = 5.0     # °C – loading saturates on cold side
AQI_ANCHOR          = 220.0   # US AQI at which AQI loading saturates
TRAFFIC_ANCHOR      = 1.0     # traffic score 0..1

# Trust score thresholds
TRUST_MAX           = 100


# ───────────────────────── helpers ────────────────────────────
def _clamp(v: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, v))


def _smooth_curve(x: float, steepness: float = 3.0) -> float:
    """Map [0, 1] → [0, 1] with a smooth S-ish ramp.

    Uses  f(x) = x^k / (x^k + (1-x)^k)  which is monotone, passes
    through (0,0) and (1,1), and is steeper around the midpoint when
    k > 1.  k = 3 gives a nice insurance-style "accelerating at
    extremes" curve.
    """
    x = _clamp(x, 0.0, 1.0)
    if x == 0.0:
        return 0.0
    if x == 1.0:
        return 1.0
    xk = x ** steepness
    return xk / (xk + (1.0 - x) ** steepness)


def _lerp(t: float, lo: float, hi: float) -> float:
    """Linear interpolation between lo and hi."""
    return lo + t * (hi - lo)


def _rain_city_multiplier(zone: str, rainfall_mm: float) -> float:
    """Extra uplift for monsoon-heavy cities when rain is already significant."""
    zone_key = str(zone or "").strip().lower()
    if rainfall_mm < 15.0:
        return 1.0

    high_rain_cities = {
        "mumbai", "chennai", "kolkata", "kochi", "goa", "panaji",
        "mangaluru", "mangalore", "guwahati", "shillong", "agartala",
        "port blair", "pune",
    }

    if not any(city in zone_key for city in high_rain_cities):
        return 1.0

    # Ramp uplift with rain depth: +8% at 15mm up to +35% at 80mm+
    norm = _clamp((rainfall_mm - 15.0) / 65.0, 0.0, 1.0)
    return round(_lerp(norm, 1.08, 1.35), 4)


def _aqi_city_multiplier(zone: str, us_aqi: float) -> float:
    """Extra uplift for chronic-pollution cities under high AQI."""
    zone_key = str(zone or "").strip().lower()
    if us_aqi < 120.0:
        return 1.0

    high_aqi_cities = {
        "delhi", "gurgaon", "gurugram", "noida", "ghaziabad", "faridabad",
        "kanpur", "lucknow", "patna", "varanasi", "agra", "ludhiana",
        "amritsar", "jaipur", "kolkata",
    }

    if not any(city in zone_key for city in high_aqi_cities):
        return 1.0

    # Ramp uplift with AQI depth: +10% at 120 up to +45% at 300+
    norm = _clamp((us_aqi - 120.0) / 180.0, 0.0, 1.0)
    return round(_lerp(norm, 1.10, 1.45), 4)


# ───────────────── individual risk loadings ───────────────────

def _rain_loading(rainfall_mm: float) -> float:
    """Rain loading: 0 mm → ₹0 … 65+ mm → ₹26, plus city uplift."""
    norm = _clamp(rainfall_mm / RAIN_ANCHOR_MM, 0.0, 1.0)
    curve = _smooth_curve(norm, steepness=3.2)
    base_load = _lerp(curve, *RAIN_LOAD_RANGE)
    return round(base_load, 2)


def _heat_loading(temperature_c: float) -> float:
    """Heat / cold loading.

    Inside the 22–32 °C comfort band → ₹0.
    Deviations away from the band load non‑linearly up to ₹12.
    """
    if HEAT_COMFORT_LOW <= temperature_c <= HEAT_COMFORT_HIGH:
        return 0.0

    if temperature_c > HEAT_COMFORT_HIGH:
        deviation = temperature_c - HEAT_COMFORT_HIGH
        span = HEAT_EXTREME - HEAT_COMFORT_HIGH  # 16 °C
    else:
        deviation = HEAT_COMFORT_LOW - temperature_c
        span = HEAT_COMFORT_LOW - COLD_EXTREME    # 17 °C

    norm = _clamp(deviation / max(span, 1.0), 0.0, 1.0)
    curve = _smooth_curve(norm, steepness=2.0)
    return round(_lerp(curve, *HEAT_LOAD_RANGE), 2)


def _aqi_loading(us_aqi: float) -> float:
    """AQI loading: 0 → ₹0 … 220+ → ₹16, with city uplift."""
    norm = _clamp(us_aqi / AQI_ANCHOR, 0.0, 1.0)
    curve = _smooth_curve(norm, steepness=3.0)
    return round(_lerp(curve, *AQI_LOAD_RANGE), 2)


def _mobility_loading(traffic_score: float, working_hours: float) -> float:
    """Mobility loading from traffic stress × hours on road.

    traffic_score is 0..1 from the live signal.
    working_hours amplifies the exposure: 12 h on road at high traffic
    is worse than 4 h.
    """
    traffic_norm = _clamp(traffic_score / TRAFFIC_ANCHOR, 0.0, 1.0)
    hours_factor = _clamp(working_hours / 12.0, 0.3, 1.0)  # floor at 0.3
    combined = traffic_norm * hours_factor
    curve = _smooth_curve(combined, steepness=2.6)
    return round(_lerp(curve, *MOBILITY_LOAD_RANGE), 2)


def _safety_discount(trust_score: int) -> float:
    """Safety discount for reliable riders.

    trust_score 0–100 → discount ₹0–₹8.
    Higher trust = bigger discount.  Uses a gentler curve so even
    mid-trust riders get a meaningful benefit.
    """
    norm = _clamp(float(trust_score) / TRUST_MAX, 0.0, 1.0)
    curve = _smooth_curve(norm, steepness=1.8)
    return round(_lerp(curve, *SAFETY_DISC_RANGE), 2)


# ──────────────── model confidence estimator ──────────────────

def _model_confidence(
    rainfall_mm: float,
    temperature_c: float,
    us_aqi: float,
    traffic_score: float,
) -> float:
    """Heuristic confidence based on how many strong signals we have.

    When live data is near baseline/defaults (no weather, no AQI),
    confidence is lower because we're essentially guessing.
    """
    signal_strength = 0
    if rainfall_mm > 1.0:
        signal_strength += 1
    if temperature_c > 1.0 or temperature_c < -1.0:
        signal_strength += 1
    if us_aqi > 5.0:
        signal_strength += 1
    if traffic_score > 0.1:
        signal_strength += 1

    # 0 signals → 0.55, 4 signals → 0.95
    return round(_clamp(0.55 + signal_strength * 0.10, 0.55, 0.95), 2)


# ──────────────────── public API surface ──────────────────────

@dataclass(frozen=True)
class PremiumBreakdown:
    base_rate: float
    rain_loading: float
    heat_loading: float
    aqi_loading: float
    mobility_risk: float
    safety_discount: float
    total_premium: float
    model_name: str
    model_confidence: float
    explanation: str


def calculate_premium_breakdown(
    zone: str,
    rainfall_mm: float,
    trust_score: int,
    working_hours: float,
    *,
    temperature_c: float = 30.0,
    us_aqi: float = 50.0,
    traffic_score: float = 0.3,
) -> PremiumBreakdown:
    """Calculate a fully itemised premium breakdown.

    Parameters
    ----------
    zone           : textual zone label (used in explanation only now)
    rainfall_mm    : current / forecast precipitation in mm
    trust_score    : rider reliability score 0‑100
    working_hours  : expected hours on road today
    temperature_c  : current temperature in °C  (keyword-only)
    us_aqi         : current US AQI reading      (keyword-only)
    traffic_score  : derived traffic stress 0‑1   (keyword-only)
    """
    rain_base = _rain_loading(rainfall_mm)
    rain = round(rain_base * _rain_city_multiplier(zone, rainfall_mm), 2)
    heat  = _heat_loading(temperature_c)
    aqi_base = _aqi_loading(us_aqi)
    aqi = round(aqi_base * _aqi_city_multiplier(zone, us_aqi), 2)
    mob   = _mobility_loading(traffic_score, working_hours)
    disc  = _safety_discount(trust_score)

    total = round(BASE_RATE_INR + rain + heat + aqi + mob - disc, 2)
    # Floor: never charge less than the base rate
    total = max(BASE_RATE_INR, total)

    conf = _model_confidence(rainfall_mm, temperature_c, us_aqi, traffic_score)

    parts: list[str] = []
    parts.append(f"Base ₹{BASE_RATE_INR:.0f}")
    if rain > 0:
        parts.append(f"Rain +₹{rain:.2f} ({rainfall_mm:.1f} mm)")
    if heat > 0:
        parts.append(f"Heat +₹{heat:.2f} ({temperature_c:.1f}°C)")
    if aqi > 0:
        parts.append(f"AQI +₹{aqi:.2f} (US AQI {us_aqi:.0f})")
    if mob > 0:
        parts.append(f"Mobility +₹{mob:.2f}")
    if disc > 0:
        parts.append(f"Safety −₹{disc:.2f}")
    parts.append(f"= ₹{total:.2f}/week")

    zone_label = str(zone or "your zone").strip() or "your zone"
    explanation = (
        f"Premium for {zone_label}: {' | '.join(parts)}. "
        f"Each factor is scored independently from live signals."
    )

    return PremiumBreakdown(
        base_rate=BASE_RATE_INR,
        rain_loading=rain,
        heat_loading=heat,
        aqi_loading=aqi,
        mobility_risk=mob,
        safety_discount=disc,
        total_premium=total,
        model_name="cashurance-parametric-v4",
        model_confidence=conf,
        explanation=explanation,
    )


def calculate_premium(
    zone: str,
    rainfall_mm: float,
    trust_score: int,
    working_hours: float,
    *,
    temperature_c: float = 30.0,
    us_aqi: float = 50.0,
    traffic_score: float = 0.3,
):
    """Return (total_premium, explanation) tuple – simple API."""
    b = calculate_premium_breakdown(
        zone, rainfall_mm, trust_score, working_hours,
        temperature_c=temperature_c,
        us_aqi=us_aqi,
        traffic_score=traffic_score,
    )
    return b.total_premium, b.explanation


def calculate_premium_payload(
    zone: str,
    rainfall_mm: float,
    trust_score: int,
    working_hours: float,
    *,
    temperature_c: float = 30.0,
    us_aqi: float = 50.0,
    traffic_score: float = 0.3,
) -> Dict[str, Union[float, str]]:
    """Return the full breakdown as a JSON-ready dict.

    Keys are kept backward-compatible with Node expectations:
      baseRate, zoneRisk, weatherVolatility, mobilityRisk,
      safetyDiscount, premium, modelName, modelConfidence, explanation

    Note: the old "zoneRisk" is now the sum of rain + AQI loadings
    (both are geography-driven), and "weatherVolatility" is the heat
    loading.  This preserves the 5-component shape the Flutter app and
    admin web expect.
    """
    b = calculate_premium_breakdown(
        zone, rainfall_mm, trust_score, working_hours,
        temperature_c=temperature_c,
        us_aqi=us_aqi,
        traffic_score=traffic_score,
    )
    return {
        "baseRate": b.base_rate,
        "zoneRisk": round(b.rain_loading + b.aqi_loading, 2),   # geo-driven risks
        "weatherVolatility": b.heat_loading,                     # temperature risk
        "mobilityRisk": b.mobility_risk,
        "safetyDiscount": b.safety_discount,
        "premium": b.total_premium,
        "modelName": b.model_name,
        "modelConfidence": b.model_confidence,
        "explanation": b.explanation,
    }