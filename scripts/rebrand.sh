#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Re-runnable caelestia -> Vaxison rebrand. Most specific patterns first.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# Files allowed to keep the old name (also used by scripts/check-rebrand.sh).
KEEP=(LICENSE NOTICE CHANGES.md scripts/rebrand.sh scripts/check-rebrand.sh docs/specs/vaxison-fork.md)
excl=(); for f in "${KEEP[@]}"; do excl+=(":!$f"); done

# Nix is out of scope (Arch only).
git rm -rq --ignore-unmatch flake.nix flake.lock nix

# Content, most specific first.
mapfile -t files < <(git grep -Ilie caelestia -- . "${excl[@]}")
if ((${#files[@]})); then sed -E -i \
  -e 's#the caelestia shell#the vaxison shell#g' \
  -e 's#caelestia-dots/shell#Aion-Mythos/-vexilion-vexison#g' \
  -e 's#caelestia-dots#Aion-Mythos#g' \
  -e 's#\["caelestia"#["vsm"#g' \
  -e 's#QStringList\{ u"caelestia"_s#QStringList{ u"vsm"_s#g' \
  -e 's#\bcaelestia (shell|scheme|wallpaper|record|toggle|clipboard|emoji|screenshot|resizer|pip|update|--version)#vsm \1#g' \
  -e 's#caelestia-cli#vsm#g' \
  -e 's#caelestia-shell#vaxison#g' \
  -e 's#caelestiaLogo#vxsLogo#g' \
  -e 's#Caelestia#Vaxison#g' \
  -e 's#CAELESTIA#VAXISON#g' \
  -e 's#caelestia#vaxison#g' \
  "${files[@]}"; fi

# Paths (deepest first so parents are renamed last).
git ls-files | { grep -i caelestia || true; } | { grep -vxF -f <(printf "%s\n" "${KEEP[@]}") || true; } | awk -F/ '{print NF" "$0}' | sort -rn | cut -d' ' -f2- |
while read -r p; do
  d=$(dirname "$p"); b=$(basename "$p")
  n=$(sed -e 's#Caelestia#Vaxison#g' -e 's#CAELESTIA#VAXISON#g' -e 's#caelestia#vaxison#g' <<<"$b")
  [ "$b" = "$n" ] || { mkdir -p "$d"; git mv "$p" "$d/$n"; }
done
# Directories (git ls-files lists files only), deepest first.
find . -path ./.git -prune -o -type d -iname '*caelestia*' -print | awk -F/ '{print NF" "$0}' | sort -rn | cut -d' ' -f2- |
while read -r d; do
  n=$(dirname "$d")/$(basename "$d" | sed -e 's#Caelestia#Vaxison#g' -e 's#CAELESTIA#VAXISON#g' -e 's#caelestia#vaxison#g')
  git mv "$d" "$n"
done
