#!/usr/bin/env bash
set -euo pipefail

# ANSI Color Codes
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. Root & Dependency Checks
[[ $EUID -eq 0 ]] || { echo "Error: Must run as root." >&2; exit 1; }
command -v oscap &>/dev/null || { echo "Error: 'oscap' missing. Run: dnf install openscap-scanner scap-security-guide" >&2; exit 1; }

SSG_FILE="/usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml"
[[ -f "$SSG_FILE" ]] || { echo "Error: Data stream missing at $SSG_FILE" >&2; exit 1; }

# 2. Benchmark Selection
echo -e "${GREEN}=== Welcome to AutoSCAP Version 2 ===${NC}"
echo "1) DISA STIG  2) HIPAA  3) CIS (L2)  4) PCI-DSS  5) Custom"
read -rp "Select choice [1-5]: " BENCHMARK_CHOICE

case "$BENCHMARK_CHOICE" in
    1) PROFILE_ID="xccdf_org.ssgproject.content_profile_stig"; BENCHMARK_NAME="DISA STIG" ;;
    2) PROFILE_ID="xccdf_org.ssgproject.content_profile_hipaa"; BENCHMARK_NAME="HIPAA" ;;
    3) PROFILE_ID="xccdf_org.ssgproject.content_profile_cis"; BENCHMARK_NAME="CIS" ;;
    4) PROFILE_ID="xccdf_org.ssgproject.content_profile_pci-dss"; BENCHMARK_NAME="PCI-DSS" ;;
    5) read -rp "Enter full Profile ID: " PROFILE_ID; BENCHMARK_NAME="Custom" ;;
    *) echo "Invalid choice." >&2; exit 1 ;;
esac

# 3. Scan Mode Selection
echo -e "\nSelect Scan Mode:"
echo "1) Regular Scan (Audit only)"
echo "2) Remediation Scan (Audit AND auto-fix)"
read -rp "Select mode [1-2]: " MODE_CHOICE

REMEDIATE_FLAG=""
if [[ "$MODE_CHOICE" == "2" ]]; then
    REMEDIATE_FLAG="--remediate"
    echo -e "\n[WARNING] Remediation mode will modify system configurations."
elif [[ "$MODE_CHOICE" != "1" ]]; then
    echo "Invalid mode choice." >&2
    exit 1
fi

# 4. Path Setup & Execution
read -rp "XML results path [/var/log/scan-results.xml]: " XML_PATH
XML_PATH="${XML_PATH:-/var/log/scan-results.xml}"
mkdir -p "$(dirname "$XML_PATH")"

echo -e "\nRunning $BENCHMARK_NAME scan..."
set +e
oscap xccdf eval $REMEDIATE_FLAG --profile "$PROFILE_ID" --results "$XML_PATH" "$SSG_FILE"
SCAN_EXIT_CODE=$?
set -e

if [[ $SCAN_EXIT_CODE -eq 0 || $SCAN_EXIT_CODE -eq 2 ]]; then
    echo -e "\nScan complete. Results saved to: $XML_PATH"
else
    echo "Error: Scan failed with code $SCAN_EXIT_CODE." >&2
    exit "$SCAN_EXIT_CODE"
fi

# 5. Optional HTML Report Generation
read -rp "Generate HTML report? (y/n): " CONVERT_HTML
if [[ "$CONVERT_HTML" =~ ^[Yy]$ ]]; then
    read -rp "HTML report path [/var/log/scan-report.html]: " HTML_PATH
    HTML_PATH="${HTML_PATH:-/var/log/scan-report.html}"
    mkdir -p "$(dirname "$HTML_PATH")"

    if oscap xccdf generate report "$XML_PATH" > "$HTML_PATH"; then
        echo "HTML report generated: $HTML_PATH"
    else
        echo "Error: Failed to generate HTML report." >&2
    fi
fi

# 6. Parse XML Results for Summary Totals
PASSED_COUNT=$(grep -c '<result>pass</result>' "$XML_PATH" || true)
FAILED_COUNT=$(grep -c '<result>fail</result>' "$XML_PATH" || true)
FIXED_COUNT=$(grep -c '<result>fixed</result>' "$XML_PATH" || true)

echo -e "\n=========================================="
echo -e "           AutoScap Summary           "
echo -e "=========================================="
echo -e "Passed Checks : ${GREEN}${PASSED_COUNT}${NC}"
echo -e "Failed Checks : ${RED}${FAILED_COUNT}${NC}"
if [[ "$MODE_CHOICE" == "2" ]]; then
    echo -e "Fixed Checks  : ${BLUE}${FIXED_COUNT}${NC}"
fi
echo -e "=========================================="

echo "Done."
