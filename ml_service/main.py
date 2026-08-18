"""
FastAPI ML microservice entry point.
Exposes /predict endpoint consumed by the Node.js backend.
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import os

from src.prediction.predictor import LifestylePredictor

app = FastAPI(
    title="EcoLife ML Service",
    description="Personalised lifestyle and carbon insights engine using scikit-learn",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load model on startup
predictor = LifestylePredictor()


# ── Request/Response schemas ────────────────────────────────────────────────
class HabitData(BaseModel):
    avg_sleep_hours:   float
    avg_exercise_mins: float
    avg_screen_hours:  float
    meal_type:         str          # vegan | vegetarian | mixed | meat_heavy
    avg_carbon_kg:     float
    streak_days:       int
    days_of_data:      Optional[int] = 7


class InsightResponse(BaseModel):
    category:    str
    title:       str
    description: str
    action:      str
    priority:    int                 # 1 = highest


# ── Endpoints ────────────────────────────────────────────────────────────────
@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": predictor.is_ready}


@app.post("/predict", response_model=list[InsightResponse])
def predict(data: HabitData):
    try:
        insights = predictor.generate_insights(data.model_dump())
        return insights
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
