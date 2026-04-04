from fastapi import FastAPI
from pydantic import BaseModel, Field
from app.premium_calculation import calculate_premium, calculate_premium_payload

app = FastAPI(title="CashUrance Premium Engine")

class PremiumRequest(BaseModel):
    zone: str
    rainfall_mm: float = Field(ge=0, le=300)
    trust_score: int = Field(ge=0, le=100)
    working_hours: float = Field(ge=0, le=24)
    temperature_c: float = Field(default=30.0, ge=-20, le=60)
    us_aqi: float = Field(default=50.0, ge=0, le=500)
    traffic_score: float = Field(default=0.3, ge=0, le=1.0)

class PremiumResponse(BaseModel):
    premium: float
    explanation: str


class MLPremiumResponse(BaseModel):
    baseRate: float
    zoneRisk: float
    weatherVolatility: float
    mobilityRisk: float
    safetyDiscount: float
    premium: float
    modelName: str
    modelConfidence: float
    explanation: str


@app.post("/calculate-premium", response_model=PremiumResponse)
def get_premium(data: PremiumRequest):
    premium, explanation = calculate_premium(
        zone=data.zone,
        rainfall_mm=data.rainfall_mm,
        trust_score=data.trust_score,
        working_hours=data.working_hours,
        temperature_c=data.temperature_c,
        us_aqi=data.us_aqi,
        traffic_score=data.traffic_score,
    )
    return {"premium": premium, "explanation": explanation}


@app.post("/ml/premium", response_model=MLPremiumResponse)
def get_ml_premium(data: PremiumRequest):
    return calculate_premium_payload(
        zone=data.zone,
        rainfall_mm=data.rainfall_mm,
        trust_score=data.trust_score,
        working_hours=data.working_hours,
        temperature_c=data.temperature_c,
        us_aqi=data.us_aqi,
        traffic_score=data.traffic_score,
    )