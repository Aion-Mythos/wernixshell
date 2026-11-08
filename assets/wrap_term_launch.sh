#!/usr/bin/env sh

cat ~/.local/state/vaxison/sequences.txt 2>/dev/null

exec "$@"
