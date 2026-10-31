# env.sh – zum source'n: Variablen des Trainingsgeländes
# Für Tests überschreibbar: LAB, REG_NAME, REG_PORT, BUILDER
export LAB="${LAB:-$HOME/docker-lab}"
export REG_NAME="${REG_NAME:-docker-lab-registry}"
export REG_PORT="${REG_PORT:-5001}"   # nicht 5000: AirPlay-Empfänger unter macOS
export REGISTRY="localhost:$REG_PORT"
export BUILDER="${BUILDER:-docker-lab}"
export NOTES="$LAB/notes"
