#!/usr/bin/env bash
set -euo pipefail

OPENCODE_DIR="${HOME}/.config/opencode"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing orchestrator-loop v2 to ${OPENCODE_DIR}..."
echo ""

# ── Skill ────────────────────────────────────────────────────────────
mkdir -p "${OPENCODE_DIR}/skills"
rm -rf "${OPENCODE_DIR}/skills/orchestrator-loop"
cp -r "${REPO_DIR}/.opencode/skills/orchestrator-loop" "${OPENCODE_DIR}/skills/"
echo "  skills/orchestrator-loop/SKILL.md"

# ── Agent config ────────────────────────────────────────────────────
if [ -f "${OPENCODE_DIR}/opencode.json" ]; then
  if command -v jq &>/dev/null; then
    TMP_FILE=$(mktemp)
    jq -c '{agent: .agent}' "${REPO_DIR}/opencode.json" > "$TMP_FILE"
    jq -s '.[0] * .[1]' "${OPENCODE_DIR}/opencode.json" "$TMP_FILE" > "${TMP_FILE}.merged" \
      && mv "${TMP_FILE}.merged" "${OPENCODE_DIR}/opencode.json"
    rm -f "$TMP_FILE"
    echo "  opencode.json (agents merged)"
  else
    echo ""
    echo "  WARNING: jq not found — install it with: brew install jq"
    echo "  Then manually merge the 'agent' section from opencode.json"
    echo "  in this repo into ${OPENCODE_DIR}/opencode.json"
  fi
else
  cp "${REPO_DIR}/opencode.json" "${OPENCODE_DIR}/opencode.json"
  echo "  opencode.json"
fi

echo ""
echo "Done! Orchestrator-loop v2 is ready."
echo ""
echo "Next steps:"
echo "  1. Open opencode in any project"
echo "  2. Switch to the 'orchestrator' agent (Tab key)"
echo "  3. Select a work item"
