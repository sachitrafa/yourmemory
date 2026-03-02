import math
from datetime import datetime, timezone

DECAY_RATE = 0.16  # λ base — halved for high-importance memories


def compute_strength(
    last_accessed_at: datetime,
    recall_count: int,
    importance: float = 0.5,
) -> float:
    """
    Ebbinghaus forgetting curve with importance-modulated decay rate:

        effective_λ = λ × (1 - importance × 0.8)
        strength    = importance × e^(-effective_λ × days) × (1 + recall_count × 0.2)

    Effect on survival time (never recalled, prune threshold = 0.05):
        importance = 1.0  →  effective_λ = 0.032  →  ~94 days
        importance = 0.9  →  effective_λ = 0.045  →  ~64 days
        importance = 0.5  →  effective_λ = 0.096  →  ~24 days
        importance = 0.2  →  effective_λ = 0.134  →  ~10 days
    """
    now = datetime.now(timezone.utc)
    if last_accessed_at.tzinfo is None:
        last_accessed_at = last_accessed_at.replace(tzinfo=timezone.utc)

    days = (now - last_accessed_at).total_seconds() / 86400
    effective_lambda = DECAY_RATE * (1 - importance * 0.8)
    strength = importance * math.exp(-effective_lambda * days) * (1 + recall_count * 0.2)

    return round(strength, 6)
