#!/usr/bin/python3
# Push helper - copies notification from input to output
import sys

if len(sys.argv) < 3:
    sys.exit(1)

f1, f2 = sys.argv[1:3]

try:
    open(f2, "w").write(open(f1).read())
except Exception:
    sys.exit(1)
