"""Resource allocation constants."""

# Production defaults
DEFAULT_MEMORY = "512Mi"
DEFAULT_MEMORY_LIMIT = "1Gi"
DEFAULT_CPU = 0.5
DEFAULT_CPU_LIMIT = 1.0

# Development/Preview defaults (lighter)
DEV_MEMORY = "128Mi"
DEV_MEMORY_LIMIT = "256Mi"
DEV_CPU = 0.1
DEV_CPU_LIMIT = 0.25

DEFAULT_REPLICAS = 1
