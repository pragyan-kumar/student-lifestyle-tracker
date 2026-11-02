"""
Training script for EcoLife Student Lifestyle & Carbon Footprint ML Model.
Trains a scikit-learn ensemble pipeline:
1. Lifestyle Persona Classifier (RandomForestClassifier)
2. Health & Eco Index Regressor (RandomForestRegressor)
Saves artifact to ml_service/models/lifestyle_model.pkl
"""

from pathlib import Path
import joblib  # type: ignore
import numpy as np  # type: ignore
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor  # type: ignore
from sklearn.preprocessing import StandardScaler  # type: ignore

MEAL_MAP = {
    "vegan": 0,
    "vegetarian": 1,
    "mixed": 2,
    "meat_heavy": 3,
}

PERSONAS = [
    "Eco Champion",
    "Balanced Achiever",
    "Sleep Deprived Scholar",
    "Digital Burnout",
    "Sedentary High-Emission",
    "Aspiring Green",
]

def generate_synthetic_dataset(n_samples: int = 2500, random_state: int = 42):
    """
    Generate realistic student lifestyle dataset based on campus behavioral research.
    """
    rng = np.random.default_rng(random_state)

    # 1. Sleep: normal distribution centered around 6.8h, clip 3-12h
    sleep = np.clip(rng.normal(loc=6.8, scale=1.5, size=n_samples), 3.0, 11.5)

    # 2. Exercise: exponential/gamma distribution skewed towards 20-30m
    exercise = np.clip(rng.gamma(shape=2.0, scale=14.0, size=n_samples), 0.0, 150.0)

    # 3. Screen time: centered around 5.5h with high variance for students
    screen = np.clip(rng.normal(loc=5.5, scale=2.0, size=n_samples), 1.0, 14.0)

    # 4. Meal type: [vegan: 10%, vegetarian: 35%, mixed: 40%, meat_heavy: 15%]
    meal_probs = [0.10, 0.35, 0.40, 0.15]
    meal_codes = rng.choice([0, 1, 2, 3], size=n_samples, p=meal_probs)

    # 5. Daily Carbon emission: depends partly on meal + commute simulation
    base_carbon = rng.normal(loc=4.5, scale=2.0, size=n_samples)
    meal_carbon_addon = np.array([0.5, 1.2, 2.5, 5.0])[meal_codes]
    carbon = np.clip(base_carbon + meal_carbon_addon, 0.4, 25.0)

    # 6. Streak days: geometric distribution
    streaks = np.clip(rng.geometric(p=0.15, size=n_samples) - 1, 0, 45)

    # Label assignment based on multi-criteria domain heuristics
    personas = []
    health_scores = []
    eco_scores = []

    for i in range(n_samples):
        s = sleep[i]
        e = exercise[i]
        sc = screen[i]
        m = meal_codes[i]
        c = carbon[i]
        st = streaks[i]

        # Health score (0 - 100)
        h_score = (
            min(s / 8.0, 1.0) * 35.0
            + min(e / 45.0, 1.0) * 35.0
            + max(0, 1.0 - (sc / 10.0)) * 20.0
            + min(st / 10.0, 1.0) * 10.0
        )
        health_scores.append(round(float(np.clip(h_score, 10.0, 100.0)), 1))

        # Eco score (0 - 100)
        e_score = (
            max(0, 1.0 - (c / 12.0)) * 55.0
            + (1.0 - (m / 3.0)) * 35.0
            + min(st / 14.0, 1.0) * 10.0
        )
        eco_scores.append(round(float(np.clip(e_score, 10.0, 100.0)), 1))

        # Persona classification
        if c < 3.2 and m <= 1 and (e >= 25 or s >= 6.5):
            personas.append("Eco Champion")
        elif s < 6.0 and sc >= 6.0:
            personas.append("Digital Burnout")
        elif s < 6.0 and e >= 15:
            personas.append("Sleep Deprived Scholar")
        elif e < 20.0 and c > 5.5:
            personas.append("Sedentary High-Emission")
        elif s >= 6.5 and e >= 25 and sc <= 5.0:
            personas.append("Balanced Achiever")
        else:
            personas.append("Aspiring Green")

    X = np.column_stack([sleep, exercise, screen, meal_codes, carbon, streaks])
    y_persona = np.array(personas)
    y_scores = np.column_stack([health_scores, eco_scores])

    return X, y_persona, y_scores


def train():
    print("[1/3] Generating synthetic lifestyle dataset...")
    X, y_persona, y_scores = generate_synthetic_dataset(3000)

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    print("[2/3] Training RandomForest Persona Classifier...")
    clf = RandomForestClassifier(n_estimators=100, max_depth=8, random_state=42)
    clf.fit(X_scaled, y_persona)

    print("[3/3] Training Multi-target Score Regressor...")
    reg = RandomForestRegressor(n_estimators=100, max_depth=8, random_state=42)
    reg.fit(X_scaled, y_scores)

    model_dir = Path(__file__).resolve().parent.parent.parent / "models"
    model_dir.mkdir(parents=True, exist_ok=True)
    model_path = model_dir / "lifestyle_model.pkl"

    payload = {
        "scaler": scaler,
        "classifier": clf,
        "regressor": reg,
        "features": [
            "avg_sleep_hours",
            "avg_exercise_mins",
            "avg_screen_hours",
            "meal_type",
            "avg_carbon_kg",
            "streak_days",
        ],
        "personas": PERSONAS,
        "meal_map": MEAL_MAP,
    }

    joblib.dump(payload, model_path)
    print(f"SUCCESS: Trained model saved to: {model_path}")


if __name__ == "__main__":
    train()
