"""
Rule-based + ML insight generator.

Phase 1 (MVP): Heuristic rules generate insights while training data is collected.
Phase 2: scikit-learn RandomForest trained on aggregated anonymised user data.
"""

import os
import joblib
import numpy as np
from pathlib import Path


class LifestylePredictor:
    MODEL_PATH = Path(__file__).parent.parent / "models" / "lifestyle_model.pkl"

    def __init__(self):
        self.model = None
        self.is_ready = False
        self._load_model()

    def _load_model(self):
        """Load serialised sklearn model if it exists, else use rule-based fallback."""
        if self.MODEL_PATH.exists():
            self.model = joblib.load(self.MODEL_PATH)
            self.is_ready = True
        else:
            # Rule-based mode until we have enough training data
            self.is_ready = True  # rules always work

    def generate_insights(self, data: dict) -> list[dict]:
        """
        Generate prioritised list of personalised insights.
        Returns list of {category, title, description, action, priority}.
        """
        insights = []

        sleep     = data.get("avg_sleep_hours", 7)
        exercise  = data.get("avg_exercise_mins", 30)
        screen    = data.get("avg_screen_hours", 3)
        meal      = data.get("meal_type", "mixed")
        carbon    = data.get("avg_carbon_kg", 5.0)
        streak    = data.get("streak_days", 0)

        # ── Sleep insight ────────────────────────────────────────────────
        if sleep < 6:
            insights.append({
                "category"   : "Sleep",
                "title"      : "Critical Sleep Deficit Detected",
                "description": f"Your average sleep is {sleep:.1f}h — well below the 6–9h healthy range. This pattern is linked to burnout and exam fatigue.",
                "action"     : "Set a sleep reminder",
                "priority"   : 1,
            })
        elif sleep < 7:
            insights.append({
                "category"   : "Sleep",
                "title"      : "Slightly Below Optimal Sleep",
                "description": f"You're averaging {sleep:.1f}h. Aim for 7–8h during exam periods to maintain focus.",
                "action"     : "Adjust bedtime by 30 min",
                "priority"   : 2,
            })

        # ── Exercise insight ────────────────────────────────────────────
        if exercise < 20:
            insights.append({
                "category"   : "Exercise",
                "title"      : "Almost No Physical Activity",
                "description": f"You've averaged only {exercise:.0f} mins of exercise/day. Even a 20-min walk improves mood and academic focus.",
                "action"     : "Log a 20-min walk today",
                "priority"   : 1,
            })
        elif exercise < 30:
            insights.append({
                "category"   : "Exercise",
                "title"      : "Just Below the 30-Min Target",
                "description": f"You're at {exercise:.0f} min/day. Adding 10 more minutes earns 15 bonus EcoPoints.",
                "action"     : "Add 10-min stretch",
                "priority"   : 3,
            })

        # ── Carbon insight ──────────────────────────────────────────────
        if carbon > 5:
            savings = round((carbon - 2) * 0.3, 1)
            insights.append({
                "category"   : "Carbon",
                "title"      : "High Carbon Footprint This Week",
                "description": f"Your daily average is {carbon:.1f} kg CO₂. Switching 2 auto rides to metro could save ~{savings} kg CO₂/week.",
                "action"     : "Plan metro commute",
                "priority"   : 1,
            })

        # ── Diet insight ────────────────────────────────────────────────
        if meal == "meat_heavy":
            insights.append({
                "category"   : "Diet",
                "title"      : "High-Emission Diet Pattern",
                "description": "Meat-heavy meals contribute ~7.2 kg CO₂/day. Trying 2 vegetarian days/week saves ~9.4 kg CO₂ monthly.",
                "action"     : "Try vegetarian tomorrow",
                "priority"   : 2,
            })

        # ── Screen time insight ─────────────────────────────────────────
        if screen > 6:
            insights.append({
                "category"   : "Screen Time",
                "title"      : "Excess Screen Time Alert",
                "description": f"You're averaging {screen:.1f}h/day of screen time. High screen use correlates with poor sleep onset.",
                "action"     : "Enable screen-off reminder",
                "priority"   : 2,
            })

        # ── Streak / gamification nudge ─────────────────────────────────
        if streak >= 5 and streak < 7:
            insights.append({
                "category"   : "Rewards",
                "title"      : "2 Days Away from a 7-Day Badge!",
                "description": f"You're on a {streak}-day streak. Complete habits for 2 more days to unlock the '7-Day Streak' badge and earn 50 bonus points.",
                "action"     : "View today's checklist",
                "priority"   : 3,
            })

        # Sort by priority, return top 4
        insights.sort(key=lambda x: x["priority"])
        return insights[:4] if insights else [self._default_insight()]

    def _default_insight(self) -> dict:
        return {
            "category"   : "General",
            "title"      : "Great Work! Keep It Up",
            "description": "Your lifestyle habits look healthy this week. Keep logging to unlock more personalised insights.",
            "action"     : "View dashboard",
            "priority"   : 5,
        }
