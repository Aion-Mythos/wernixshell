#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Fails if "caelestia" (any case) remains outside the allowed files.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
KEEP=(LICENSE NOTICE CHANGES.md README.md scripts/rebrand.sh scripts/check-rebrand.sh docs/specs/wernixshell-fork.md)
excl=(); for f in "${KEEP[@]}"; do excl+=(":!$f"); done
bad=$(git grep -Iin caelestia -- . "${excl[@]}" || true)
names=$(git ls-files | grep -i caelestia | grep -vxF -f <(printf '%s\n' "${KEEP[@]}") || true)
# The fork's own former names (Vaxison / VexilionOS).
old=$(git grep -Iin -e vaxison -e vexilion -e vxs -- . ':!CHANGES.md' ':!scripts/check-rebrand.sh' || true)
bad+=$old
[ -z "$bad$names" ] && { echo "rebrand check: OK"; exit 0; }
printf '%s\n%s\n' "$bad" "$names"; exit 1
