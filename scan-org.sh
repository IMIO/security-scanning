#!/usr/bin/env bash
# scan-org.sh - Lance gitleaks sur tous les repos de l'org

ORG="imio"
GITHUB_TOKEN="${GITHUB_TOKEN}"
REPORT_DIR="./reports/$(date +%Y-%m-%d)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/.gitleaks.toml"
mkdir -p "$REPORT_DIR"

# Récupère tous les repos (paginé)
repos=$(gh repo list "$ORG" --limit 1000 --json nameWithOwner -q '.[].nameWithOwner')

for repo in $repos; do
  echo "=== Scanning $repo ==="
  repo_name=$(echo "$repo" | cut -d'/' -f2)
  
  git clone "https://x-access-token:${GITHUB_TOKEN}@github.com/${repo}.git" "/tmp/${repo_name}" 2>/dev/null
  
  gitleaks detect \
    --source "/tmp/${repo_name}" \
    --config "${CONFIG_FILE}" \
    --report-format json \
    --report-path "${REPORT_DIR}/${repo_name}.json" \
    --exit-code 0 \
    --redact

  rm -rf "/tmp/${repo_name}"
done

# Agrège tous les rapports JSON en un seul
jq -s 'add // []' "${REPORT_DIR}"/*.json > "${REPORT_DIR}/full-report.json"
echo "Rapport consolidé : ${REPORT_DIR}/full-report.json"
