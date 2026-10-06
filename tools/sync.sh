#!/usr/bin/env bash
# Copies the addon into the game's AddOns folder. Usage: tools/sync.sh "/path/to/_classic_beta_"
set -euo pipefail
GAME="${1:?usage: tools/sync.sh <path to _classic_beta_>}"
DEST="$GAME/Interface/AddOns/Odyssey"
mkdir -p "$DEST"
rsync -a --delete \
  --exclude '.git' --exclude 'docs' --exclude 'tests' --exclude 'tools' \
  --exclude '.github' --exclude '*.md' --exclude '.superpowers' \
  "$(dirname "$0")/../" "$DEST/"
echo "Synced to $DEST"
