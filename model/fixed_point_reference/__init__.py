"""与阶段1 RTL数值契约一致的位精确定点参考模型。"""

from .config import FixedConfig
from .cordic import CordicResult, cordic_sincos, degrees_to_phase
from .geometry import FixedHalfPlane, FixedPoint, FixedLocalizationResult, localize_fixed

__all__ = [
    "CordicResult",
    "FixedConfig",
    "FixedHalfPlane",
    "FixedLocalizationResult",
    "FixedPoint",
    "cordic_sincos",
    "degrees_to_phase",
    "localize_fixed",
]
