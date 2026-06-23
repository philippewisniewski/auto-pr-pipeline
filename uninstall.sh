#!/usr/bin/env bash
set -euo pipefail

OPENCODE_DIR="${HOME}/.config/opencode"

echo "Removing orchestrator-loop from ${OPENCODE_DIR}..."
echo ""

removed=false

# ── Skill ────────────────────────────────────────────────────────────
if [ -d "${OPENCODE_DIR}/skills/orchestrator-loop" ]; then
  rm -rf "${OPENCODE_DIR}/skills/orchestrator-loop"
  echo "  skills/orchestrator-loop"
  removed=true
fi

# Remove empty skills directory
if [ -d "${OPENCODE_DIR}/skills" ] && [ -z "$(ls -A "${OPENCODE_DIR}/skills" 2>/dev/null)" ]; then
  rmdir "${OPENCODE_DIR}/skills" 2>/dev/null || true
fi

# ── opencode.json note ──────────────────────────────────────────────
if [ -f "${OPENCODE_DIR}/opencode.json" ]; then
  echo ""
  echo "  NOTE: opencode.json still contains the orchestrator, implementer,"
  echo "  and reviewer agent definitions. Remove them manually if desired."
fi

if [ "$removed" = false ]; then
  echo "  Nothing to remove — orchestrator-loop was not installed."
fi

echo ""
echo "Done."
