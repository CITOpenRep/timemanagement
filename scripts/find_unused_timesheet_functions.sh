#!/usr/bin/env bash
set -euo pipefail

root="${1:-.}"
file="$root/models/timesheet.js"

if [[ ! -f "$file" ]]; then
  echo "Missing file: $file" >&2
  exit 1
fi

# List function names with line numbers, then report usage outside timesheet.js.
grep -n "^function " "$file" | while IFS=: read -r line rest; do
  name=$(echo "$rest" | sed -E 's/^function ([^(]+).*/\1/')
  if grep -R --exclude="$(basename "$file")" -n "${name}(" "$root" >/dev/null; then
    echo "USED: $name ($file:$line)"
  else
    echo "UNUSED: $name ($file:$line)"
  fi
done
