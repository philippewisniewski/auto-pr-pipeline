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
    AGENT_EXTRACT=$(mktemp)
    jq -c '{agent: .agent}' "${REPO_DIR}/opencode.json" > "$AGENT_EXTRACT"
    MERGED_FILE="${OPENCODE_DIR}/opencode.json.merged"
    jq -s '.[0] * .[1]' "${OPENCODE_DIR}/opencode.json" "$AGENT_EXTRACT" > "$MERGED_FILE"
    # Reorder agent keys: build → plan → orchestrator → implementer → reviewer
    # Include build/plan with {} fallback so the tab order is correct even
    # when the existing config doesn't define them (built-in defaults apply).
    jq '.agent as $a | .agent = (
      {build: ($a.build // {})} +
      {plan: ($a.plan // {})} +
      {orchestrator: $a.orchestrator} +
      {implementer: $a.implementer} +
      {reviewer: $a.reviewer}
    )' "$MERGED_FILE" > "${MERGED_FILE}.reordered" \
      && mv "${MERGED_FILE}.reordered" "${OPENCODE_DIR}/opencode.json"
    rm -f "$AGENT_EXTRACT" "$MERGED_FILE"
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
