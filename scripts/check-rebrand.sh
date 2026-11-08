#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Fails if "caelestia" (any case) remains outside the allowed files.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
KEEP=(LICENSE NOTICE CHANGES.md scripts/rebrand.sh scripts/check-rebrand.sh scripts/vsm-shim docs/specs/vaxison-fork.md)
excl=(); for f in "${KEEP[@]}"; do excl+=(":!$f"); done
bad=$(git grep -Iin caelestia -- . "${excl[@]}" || true)
names=$(git ls-files | grep -i caelestia | grep -vxF -f <(printf '%s\n' "${KEEP[@]}") || true)
[ -z "$bad$names" ] && { echo "rebrand check: OK"; exit 0; }
printf '%s\n%s\n' "$bad" "$names"; exit 1
