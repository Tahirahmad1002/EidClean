# app.py - EidClean Waste Prediction API
#
# Loads the trained RandomForest model and exposes three endpoints:
#   GET  /health
#   GET  /info
#   POST /predict
#
# Run locally with:
#   uvicorn app:app --reload --port 8000
# Or directly with:
#   python app.py
#
# On Render, the process is started by the platform using:
#   uvicorn app:app --host 0.0.0.0 --port $PORT

import os
import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional

# ---------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------
# Model artifacts live in ml_files/ next to this file.
BASE_DIR = Path(__file__).resolve().parent
ML_DIR = BASE_DIR / "ml_files"

MODEL_PATH = ML_DIR / "best_model.pkl"
SCALER_PATH = ML_DIR / "scaler.pkl"
KMEANS_PATH = ML_DIR / "kmeans.pkl"
METADATA_PATH = ML_DIR / "model_metadata.json"


# ---------------------------------------------------------------------
# Load model artifacts at startup
# ---------------------------------------------------------------------
print("Loading model artifacts...")

if not MODEL_PATH.exists():
    raise RuntimeError("Model file not found at %s" % MODEL_PATH)

model = joblib.load(MODEL_PATH)
print("  Model loaded: %s" % type(model).__name__)

scaler = joblib.load(SCALER_PATH)
print("  Scaler loaded: %s" % type(scaler).__name__)

kmeans = joblib.load(KMEANS_PATH)
print("  KMeans loaded: %d clusters" % kmeans.n_clusters)

with open(METADATA_PATH, "r") as f:
    metadata = json.load(f)
print("  Metadata loaded")
print("")


# ---------------------------------------------------------------------
# FastAPI application
# ---------------------------------------------------------------------
app = FastAPI(
    title="EidClean Waste Prediction API",
    description="Predicts Eid-ul-Adha waste for a locality and computes required resources.",
    version="1.0.0",
)

# Allow the admin dashboard to call this API from a different origin.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------
# Request and response models
# ---------------------------------------------------------------------
class PredictRequest(BaseModel):
    population: float = Field(..., gt=0, description="Locality population (PBS Census 2023)")
    housing: float = Field(..., gt=0, description="Number of housing units")
    participation_rate: float = Field(..., ge=0, le=1, description="Qurbani participation rate (0 to 1)")
    area_type: str = Field(..., description="Either 'Rural' or 'Urban'")
    eid_day: int = Field(..., ge=1, le=3, description="Eid day: 1, 2, or 3")


class PredictResponse(BaseModel):
    waste_kg: float
    trucks: int
    workers: int
    bins: int
    model_version: str
    input_summary: dict


# ---------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------
@app.get("/health")
def health():
    return {"status": "ok", "service": "EidClean Prediction API"}


@app.get("/info")
def info():
    return {
        "model_type": metadata["model_type"],
        "target_type": metadata["target_type"],
        "feature_columns": metadata["feature_columns"],
        "metrics": metadata["metrics"],
        "generated_at": metadata.get("generated_at"),
    }


@app.post("/predict", response_model=PredictResponse)
def predict(request: PredictRequest):
    # Encode area type
    area_lower = request.area_type.strip().lower()
    if area_lower not in ("rural", "urban"):
        raise HTTPException(
            status_code=400,
            detail="area_type must be 'Rural' or 'Urban'",
        )
    area_encoded = 1 if area_lower == "urban" else 0

    # Validate against the ranges the model was trained on
    ranges = metadata["input_ranges"]

    def check_range(name, value, key):
        r = ranges.get(key)
        if r and "min" in r and "max" in r:
            if value < r["min"] or value > r["max"]:
                raise HTTPException(
                    status_code=422,
                    detail="%s = %s is outside trained range [%s, %s]" % (
                        name, value, r["min"], r["max"]),
                )

    check_range("population", request.population, "Population_2023")
    check_range("housing", request.housing, "Housing_Units")
    check_range("participation_rate", request.participation_rate,
                "Estimated_Qurbani_Participation_Rate_pct")
    check_range("eid_day", request.eid_day, "Eid_Day")

    # Build feature vector in the order the model expects
    features = np.array([[
        request.population,
        request.housing,
        request.participation_rate,
        area_encoded,
        request.eid_day,
    ]])

    # Predict
    raw_prediction = model.predict(features)[0]

    # Convert from log scale if needed
    if metadata["target_type"] == "log":
        waste_kg = float(np.expm1(raw_prediction))
    else:
        waste_kg = float(raw_prediction)

    waste_kg = max(0.0, waste_kg)

    # Compute resources from waste
    rules = metadata["resource_planning_rules"]
    trucks = int(np.ceil(waste_kg / rules["truck_capacity_kg"]))
    workers = int(np.ceil(waste_kg / rules["worker_capacity_kg"]))
    bins = int(np.ceil(waste_kg / rules["bin_capacity_kg"]))

    return PredictResponse(
        waste_kg=round(waste_kg, 2),
        trucks=trucks,
        workers=workers,
        bins=bins,
        model_version=metadata.get("generated_at", "unknown"),
        input_summary={
            "population": request.population,
            "housing": request.housing,
            "participation_rate": request.participation_rate,
            "area_type": request.area_type,
            "eid_day": request.eid_day,
        },
    )


# ---------------------------------------------------------------------
# Run directly (used for local testing)
# ---------------------------------------------------------------------
if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)