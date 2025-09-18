#!/usr/bin/env bash
set -e
input="${1:-items.txt}"
while IFS= read -r line; do
  [ -z "$line" ] && continue
  ./gemx.sh gen --prompt "$line"
done < "$input"
