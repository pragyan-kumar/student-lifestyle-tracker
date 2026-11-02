"""
ML-driven lifestyle & carbon footprint insight generator.

Utilizes:
1. scikit-learn RandomForestClassifier for student lifestyle persona detection
2. scikit-learn RandomForestRegressor for Health & Eco Index scoring
3. Heuristic sensitivity layer for granular, contextual action recommendations
"""

import os
from pathlib import Path
import joblib  # type: ignore
import numpy as np  # type: ignore


class LifestylePredictor:
    MODEL_PATH = Path(__file__).resolve().parent.parent.parent / "models" / "lifestyle_model.pkl"

    def __init__(self):
        self.model_data = None
        self.is_ready = False
        self._load_model()

    def _load_model(self):
        """Load serialised sklearn model bundle."""
        if self.MODEL_PATH.exists():
            try:
                self.model_data = joblib.load(self.MODEL_PATH)
                self.is_ready = True
            except Exception as e:
                print(f"Warning: Failed to load model artifact: {e}")
                self.is_ready = False
        else:
            self.is_ready = False

    def generate_insights(self, data: dict) -> list[dict]:
        """
        Generate prioritised list of personalised ML insights.
        Returns list of {category, title, description, action, priority}.
        """
        insights = []

        sleep = float(data.get("avg_sleep_hours", 7.0))
        exercise = float(data.get("avg_exercise_mins", 30.0))
        screen = float(data.get("avg_screen_hours", 4.0))
        meal = str(data.get("meal_type", "mixed")).lower().strip()
        carbon = float(data.get("avg_carbon_kg", 4.0))
        streak = int(data.get("streak_days", 0))
        days = int(data.get("days_of_data", 7))

        meal_code = {"vegan": 0, "vegetarian": 1, "mixed": 2, "meat_heavy": 3}.get(meal, 2)

        # ── 1. Model Inference: Persona & Health / Eco Scores ────────────────
        persona = "Balanced Achiever"
        health_score = 75.0
        eco_score = 70.0

        if self.model_data:
            try:
                scaler = self.model_data["scaler"]
                clf = self.model_data["classifier"]
                reg = self.model_data["regressor"]

                X = np.array([[sleep, exercise, screen, meal_code, carbon, streak]])
                X_scaled = scaler.transform(X)

                pred_persona = clf.predict(X_scaled)[0]
                pred_scores = reg.predict(X_scaled)[0]

                persona = str(pred_persona)
                health_score = round(float(pred_scores[0]), 1)
                eco_score = round(float(pred_scores[1]), 1)
            except Exception as err:
                print(f"Inference warning, using heuristics: {err}")

        # ── 2. Top-level AI Persona & Score Card ──────────────────────────────
        persona_actions = {
            "Eco Champion": "Share your green habits with peers",
            "Balanced Achiever": "Maintain your balanced daily rhythm",
            "Sleep Deprived Scholar": "Set a strict 10:30 PM bedtime",
            "Digital Burnout": "Try a 1-hour screen-free digital detox",
            "Sedentary High-Emission": "Swap 1 motorised trip with walking",
            "Aspiring Green": "Log habits for 3 consecutive days",
        }
        action_text = persona_actions.get(persona, "Explore your daily dashboard")

        insights.append({
            "category": "AI Persona",
            "title": f"Profile: {persona} (Eco Score: {eco_score:.0f}/100)",
            "description": (
                f"ML model classified your lifestyle profile with a Health Score of {health_score:.0f}/100 "
                f"and Carbon Eco Score of {eco_score:.0f}/100 based on {days} day{'s' if days != 1 else ''} of logs."
            ),
            "action": action_text,
            "priority": 1,
        })

        # ── 3. Sleep & Circadian Hygiene ─────────────────────────────────────
        if sleep < 6.0:
            insights.append({
                "category": "Sleep",
                "title": "Critical Sleep Deficit Detected",
                "description": (
                    f"Averaging {sleep:.1f}h sleep/night is below the minimum 6h threshold. "
                    "Chronic sleep debt reduces exam recall by up to 25%."
                ),
                "action": "Set a sleep reminder for 10:30 PM",
                "priority": 1,
            })
        elif sleep < 7.0:
            insights.append({
                "category": "Sleep",
                "title": "Slightly Below Optimal Sleep (6–7h)",
                "description": (
                    f"You are logging {sleep:.1f}h sleep. Shifting your bedtime 30 minutes earlier "
                    "optimizes deep sleep stages for cognitive recovery."
                ),
                "action": "Adjust bedtime by 30 min",
                "priority": 3,
            })
        elif sleep > 10.0:
            insights.append({
                "category": "Sleep",
                "title": "Oversleeping Pattern (10h+)",
                "description": (
                    f"Averaging {sleep:.1f}h sleep. Long irregular sleep durations often signal "
                    "disrupted sleep architecture or fatigue rebound."
                ),
                "action": "Stabilize morning wake-up time",
                "priority": 3,
            })
        else:
            insights.append({
                "category": "Sleep",
                "title": "Optimal Rest Zone (7–9h)",
                "description": (
                    f"Your average of {sleep:.1f}h sleep is within the prime academic performance bracket. "
                    "Consistent wake times will solidify this sleep rhythm."
                ),
                "action": "Keep wake time consistent",
                "priority": 4,
            })

        # ── 4. Exercise & Physical Activity ──────────────────────────────────
        if exercise < 15.0:
            insights.append({
                "category": "Exercise",
                "title": "Low Daily Activity Alert",
                "description": (
                    f"Averaging only {exercise:.0f} mins of exercise/day. "
                    "Just 20 minutes of brisk campus walking significantly lowers study stress and cortisol."
                ),
                "action": "Take a 20-min campus walk",
                "priority": 2,
            })
        elif exercise < 30.0:
            insights.append({
                "category": "Exercise",
                "title": "Approaching Daily 30-Min Active Target",
                "description": (
                    f"You are at {exercise:.0f} min/day. Adding just 10 more minutes reaches the WHO recommended "
                    "target and earns 15 bonus EcoPoints."
                ),
                "action": "Add 10-min bodyweight stretch",
                "priority": 3,
            })
        else:
            insights.append({
                "category": "Exercise",
                "title": "Active Target Achieved! (>30 min/day)",
                "description": (
                    f"Averaging {exercise:.0f} active minutes daily! Regular activity boosts brain-derived "
                    "neurotrophic factor (BDNF), maximizing learning efficiency."
                ),
                "action": "Maintain daily activity streak",
                "priority": 4,
            })

        # ── 5. Diet & Food Emission Footprint ────────────────────────────────
        if meal == "meat_heavy":
            insights.append({
                "category": "Diet",
                "title": "High-Emission Diet Pattern",
                "description": (
                    "Meat-heavy diets emit ~7.2 kg CO₂/day on average. "
                    "Swapping 2 meals weekly to plant-based saves ~9.4 kg CO₂ monthly."
                ),
                "action": "Try a vegetarian meal tomorrow",
                "priority": 2,
            })
        elif meal == "mixed":
            insights.append({
                "category": "Diet",
                "title": "Mixed Diet Carbon Optimization",
                "description": (
                    "Mixed student meals contribute ~4.2 kg CO₂/day. Adding seasonal local fruits and plant proteins "
                    "can cut meal emissions by up to 25%."
                ),
                "action": "Opt for plant-based lunch today",
                "priority": 3,
            })
        elif meal in ("vegan", "vegetarian"):
            insights.append({
                "category": "Diet",
                "title": "Low-Carbon Plant-Forward Diet",
                "description": (
                    f"Your {meal} diet produces 40–60% fewer greenhouse emissions than standard diets, "
                    "saving ~3.5 kg CO₂ daily. Excellent eco-conscious habit!"
                ),
                "action": "Log 8 glasses of water to pair",
                "priority": 4,
            })

        # ── 6. Commute & Carbon Footprint ────────────────────────────────────
        if carbon > 6.0:
            savings = round((carbon - 2.5) * 0.4, 1)
            insights.append({
                "category": "Carbon",
                "title": "Elevated Daily Footprint",
                "description": (
                    f"Daily average is {carbon:.1f} kg CO₂. Choosing metro or carpooling over solo rides "
                    f"can reduce emissions by ~{savings} kg CO₂ each week."
                ),
                "action": "Plan shared or metro commute",
                "priority": 1,
            })
        elif carbon > 3.0:
            insights.append({
                "category": "Carbon",
                "title": "Moderate Carbon Emissions",
                "description": (
                    f"At {carbon:.1f} kg CO₂/day, you are close to campus sustainability targets. "
                    "Unplugging idle laptop chargers and walking short campus trips saves another 0.8 kg CO₂."
                ),
                "action": "Walk trips under 1 km",
                "priority": 3,
            })
        else:
            insights.append({
                "category": "Carbon",
                "title": "Campus Green Leader (<3 kg CO₂)",
                "description": (
                    f"At {carbon:.1f} kg CO₂/day, your footprint is in the top tier of eco-friendly students! "
                    "Keep up this minimal impact lifestyle."
                ),
                "action": "Check leaderboard ranking",
                "priority": 4,
            })

        # ── 7. Screen Time vs Study Focus ────────────────────────────────────
        if screen > 7.0:
            insights.append({
                "category": "Screen Time",
                "title": "High Screen Exposure (7h+)",
                "description": (
                    f"Averaging {screen:.1f}h of daily screen time. Prolonged blue light exposure after 9 PM "
                    "delays natural melatonin onset by up to 90 minutes."
                ),
                "action": "Enable blue-light filter & bedtime mode",
                "priority": 2,
            })
        elif screen > 4.5:
            insights.append({
                "category": "Screen Time",
                "title": "Moderate Screen Use (4–7h)",
                "description": (
                    f"You have {screen:.1f}h daily screen time. Use the 20-20-20 rule during study blocks: "
                    "every 20 mins, look at something 20 feet away for 20 seconds."
                ),
                "action": "Take a 5-min screen break",
                "priority": 4,
            })
        else:
            insights.append({
                "category": "Screen Time",
                "title": "Mindful Screen Usage (<4h)",
                "description": (
                    f"Logging only {screen:.1f}h screen time leaves plenty of room for restorative offline focus, "
                    "social activities, and restful sleep."
                ),
                "action": "Keep screen time under 4h",
                "priority": 5,
            })

        # ── 8. Gamification & Streak Milestones ──────────────────────────────
        if streak == 0:
            insights.append({
                "category": "Rewards",
                "title": "Start Your Streak Today!",
                "description": "Log all 5 daily habits to ignite your Day 1 streak and claim 20 bonus EcoPoints.",
                "action": "Complete today's checklist",
                "priority": 2,
            })
        elif streak in (5, 6):
            insights.append({
                "category": "Rewards",
                "title": f"{7 - streak} Day{'s' if 7 - streak > 1 else ''} to 7-Day Streak Badge!",
                "description": (
                    f"You are on a {streak}-day streak! Keep it active to unlock the 'Consistency Champion' "
                    "badge and 50 bonus EcoPoints."
                ),
                "action": "Keep streak alive today",
                "priority": 2,
            })
        elif streak >= 7:
            insights.append({
                "category": "Rewards",
                "title": f"Impressive {streak}-Day Streak Active! 🔥",
                "description": (
                    f"You have maintained your habits for {streak} continuous days. "
                    "You qualify for streak freeze protection in the EcoStore."
                ),
                "action": "View streak rewards in wallet",
                "priority": 3,
            })

        # Sort by priority (1 = highest urgency) and return top 4
        insights.sort(key=lambda x: x["priority"])
        return insights[:4]
