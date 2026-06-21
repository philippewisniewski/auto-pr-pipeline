#!/usr/bin/env bash
set -euo pipefail

OPENCODE_DIR="${HOME}/.config/opencode"

echo "Removing orchestrator-loop from ${OPENCODE_DIR}..."
echo ""

removed=false

# ── Skills ──────────────────────────────────────────────────────────
for skill in orchestrator-loop diagnose to-issues to-prd; do
  if [ -d "${OPENCODE_DIR}/skills/${skill}" ]; then
    rm -rf "${OPENCODE_DIR}/skills/${skill}"
    echo "  skills/${skill}"
    removed=true
  fi
done

# Remove empty skills directory
if [ -d "${OPENCODE_DIR}/skills" ] && [ -z "$(ls -A "${OPENCODE_DIR}/skills" 2>/dev/null)" ]; then
  rmdir "${OPENCODE_DIR}/skills" 2>/dev/null || true
fi

# ── Prompts ─────────────────────────────────────────────────────────
for prompt in orchestrator.txt implementer.txt meta-analyst.txt; do
  if [ -f "${OPENCODE_DIR}/prompts/${prompt}" ]; then
    rm "${OPENCODE_DIR}/prompts/${prompt}"
    echo "  prompts/${prompt}"
    removed=true
  fi
done

# Remove empty prompts directory
if [ -d "${OPENCODE_DIR}/prompts" ] && [ -z "$(ls -A "${OPENCODE_DIR}/prompts" 2>/dev/null)" ]; then
  rmdir "${OPENCODE_DIR}/prompts" 2>/dev/null || true
fi

# ── Custom tools ────────────────────────────────────────────────────
for tool_file in gh-issue.ts gh-pr.ts; do
  if [ -f "${OPENCODE_DIR}/tools/${tool_file}" ]; then
    rm "${OPENCODE_DIR}/tools/${tool_file}"
    echo "  tools/${tool_file}"
    removed=true
  fi
done

# Remove only the tool files we own, leave other user tools intact
if [ -d "${OPENCODE_DIR}/tools" ] && [ -z "$(ls -A "${OPENCODE_DIR}/tools" 2>/dev/null)" ]; then
  rm -rf "${OPENCODE_DIR}/tools"
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
