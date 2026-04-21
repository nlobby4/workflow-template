#!/bin/bash

# --------------------------------------------------
# Shared variables for shell scripts in this repository.
# --------------------------------------------------

# Variables
if [ -t 1 ]; then
  OK="✓ Success:"
  ERROR="✗ Error:"
  WARN="⚠ Warning:"
else
  OK="[OK]:"
  ERROR="[ERROR]:"
  WARN="[WARN]:"
fi
