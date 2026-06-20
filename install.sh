#!/usr/bin/env bash
set -euo pipefail

OPENCODE_DIR="${HOME}/.config/opencode"

echo "Installing orchestrator-loop to ${OPENCODE_DIR}..."
echo ""

mkdir -p "${OPENCODE_DIR}/skills"
for skill in orchestrator-loop diagnose to-issues to-prd; do
  rm -rf "${OPENCODE_DIR}/skills/${skill}"
  cp -r ".opencode/skills/${skill}" "${OPENCODE_DIR}/skills/"
  echo "  skills/${skill}/SKILL.md"
done

mkdir -p "${OPENCODE_DIR}/prompts"
for prompt in orchestrator.txt implementer.txt meta-analyst.txt; do
  cp ".opencode/prompts/${prompt}" "${OPENCODE_DIR}/prompts/"
  echo "  prompts/${prompt}"
done

if [ -f "${OPENCODE_DIR}/opencode.json" ]; then
  echo ""
  echo "WARNING: ${OPENCODE_DIR}/opencode.json already exists."
  echo "Manually merge the 'agent' section from opencode.json in this repo."
else
  cp "opencode.json" "${OPENCODE_DIR}/"
  echo "  opencode.json"
fi

echo ""
echo "Done. Orchestrator-loop agents and skills are now available globally."
echo ""
echo "Next steps:"
echo "  1. Open opencode in any project"
echo "  2. Switch to the 'orchestrator' agent (Tab key)"
echo "  3. Describe the work item you want implemented"
echo ""
echo "  To enable custom GitHub tools in another project:"
echo "    cp -r .opencode/tools <target-project>/.opencode/tools"
echo "    # Then add tool permissions to opencode.json (see AGENTS.md)"
echo ""
echo "  Or set up the GitHub Action:"
echo "    cp .github/workflows/orchestrator-loop.yml <target-project>/.github/workflows/"
