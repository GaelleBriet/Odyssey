#!/usr/bin/env bash
# Downloads the SIL OFL fonts bundled with Odyssey, with their licenses, into Media/Fonts.
# Static weights are used (WoW renders variable fonts at their default instance only).
# Requires: curl, unzip, python3 with fontTools. Run from the repo root: tools/fetch_fonts.sh
set -euo pipefail
OUT="Media/Fonts"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT"
GF="https://raw.githubusercontent.com/google/fonts/main/ofl"

# Barlow Condensed SemiBold (static in google/fonts)
curl -sfL "$GF/barlowcondensed/BarlowCondensed-SemiBold.ttf" -o "$OUT/BarlowCondensed-SemiBold.ttf"
curl -sfL "$GF/barlowcondensed/OFL.txt" -o "$OUT/OFL-BarlowCondensed.txt"

# Cinzel Bold (static, upstream repo)
curl -sfL "https://raw.githubusercontent.com/NDISCOVER/Cinzel/master/fonts/ttf/Cinzel-Bold.ttf" -o "$OUT/Cinzel-Bold.ttf"
curl -sfL "$GF/cinzel/OFL.txt" -o "$OUT/OFL-Cinzel.txt"

# Nunito Bold: instantiate the variable font at weight 700
curl -sfL "$GF/nunito/Nunito%5Bwght%5D.ttf" -o "$TMP/Nunito-VF.ttf"
python3 -m fontTools.varLib.instancer "$TMP/Nunito-VF.ttf" wght=700 --update-name-table -o "$OUT/Nunito-Bold.ttf" -q
curl -sfL "$GF/nunito/OFL.txt" -o "$OUT/OFL-Nunito.txt"

# Inter SemiBold (static, from the official release)
curl -sfL "https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip" -o "$TMP/inter.zip"
unzip -o -q -j "$TMP/inter.zip" "extras/ttf/Inter-SemiBold.ttf" -d "$OUT"
unzip -q -p "$TMP/inter.zip" "LICENSE.txt" > "$OUT/OFL-Inter.txt"

ls -l "$OUT"
