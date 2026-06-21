#!/usr/bin/env bash
set -euo pipefail

OPENCODE_DIR="${HOME}/.config/opencode"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing orchestrator-loop to ${OPENCODE_DIR}..."
echo ""

# ── Skills ──────────────────────────────────────────────────────────
mkdir -p "${OPENCODE_DIR}/skills"
for skill in orchestrator-loop diagnose to-issues to-prd; do
  rm -rf "${OPENCODE_DIR}/skills/${skill}"
  cp -r "${REPO_DIR}/.opencode/skills/${skill}" "${OPENCODE_DIR}/skills/"
  echo "  skills/${skill}/SKILL.md"
done

# ── Prompts ─────────────────────────────────────────────────────────
mkdir -p "${OPENCODE_DIR}/prompts"
for prompt in orchestrator.txt implementer.txt meta-analyst.txt; do
  cp "${REPO_DIR}/.opencode/prompts/${prompt}" "${OPENCODE_DIR}/prompts/"
  echo "  prompts/${prompt}"
done

# ── Custom tools ────────────────────────────────────────────────────
if [ -d "${REPO_DIR}/.opencode/tools" ]; then
  mkdir -p "${OPENCODE_DIR}/tools"
  for tool_file in "${REPO_DIR}"/.opencode/tools/*.ts; do
    tool_name=$(basename "$tool_file")
    cp "$tool_file" "${OPENCODE_DIR}/tools/"
    echo "  tools/${tool_name}"
  done

  # Install tool dependencies if not already present
  if [ -f "${REPO_DIR}/.opencode/package.json" ] && [ ! -d "${OPENCODE_DIR}/tools/node_modules" ]; then
    cp "${REPO_DIR}/.opencode/package.json" "${OPENCODE_DIR}/tools/"
    cp "${REPO_DIR}/.opencode/package-lock.json" "${OPENCODE_DIR}/tools/" 2>/dev/null || true
    echo "  tools/package.json (installing dependencies...)"
    (cd "${OPENCODE_DIR}/tools" && npm install --quiet 2>/dev/null) || \
      echo "  (run 'npm install' in ${OPENCODE_DIR}/tools/ if tools fail to load)"
  fi
fi

# ── Agent config ────────────────────────────────────────────────────
if [ -f "${OPENCODE_DIR}/opencode.json" ]; then
  if command -v jq &>/dev/null; then
    TMP_FILE=$(mktemp)
    # Rewrite .opencode/prompts/ → prompts/ for the global install path
    sed 's|\.opencode/prompts/|prompts/|g' "${REPO_DIR}/opencode.json" | \
      jq -c '{agent: .agent}' > "$TMP_FILE"
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
  sed 's|\.opencode/prompts/|prompts/|g' "${REPO_DIR}/opencode.json" > "${OPENCODE_DIR}/opencode.json"
  echo "  opencode.json"
fi

echo ""
echo "Done! Orchestrator-loop agents, skills, and tools are now available globally."
echo ""
echo "Next steps:"
echo "  1. Open opencode in any project"
echo "  2. Switch to the 'orchestrator' agent (Tab key)"
echo "  3. Describe the work item you want implemented"
echo ""
echo "  To set up the GitHub Action in a target project:"
echo "    cp .github/workflows/orchestrator-loop.yml <target-project>/.github/workflows/"
