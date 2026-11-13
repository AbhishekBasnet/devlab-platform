#!/usr/bin/env bash
set -euo pipefail

# Read-only health report for snapper snapshots + disk usage, sent to a Discord webhook.
# It changes nothing on the system: it only runs `snapper list`, `systemctl is-active` and `df`.
#
# Usage:   snapshot-report.sh [--dry-run]     (--dry-run prints the message and sends nothing)
# Webhook: first line of $WEBHOOK_FILE (default ~/.config/snapshot-report/webhook, chmod 600)
# Tunables via environment: CONFIGS, MAX_AGE_HOURS, DISK_WARN

PATH=/usr/local/bin:/usr/bin:/bin   # same PATH under cron/systemd

WEBHOOK_FILE="${WEBHOOK_FILE:-$HOME/.config/snapshot-report/webhook}"
CONFIGS="${CONFIGS:-root home}"          # snapper configs to check
MAX_AGE_HOURS="${MAX_AGE_HOURS:-3}"      # newest timeline snapshot older than this = problem
DISK_WARN="${DISK_WARN:-80}"             # % used on / above this = problem
TIMERS=(snapper-timeline.timer snapper-cleanup.timer)

dry_run=false
[[ "${1:-}" == "--dry-run" ]] && dry_run=true

problems=()
lines=()

# 1. Are the snapper timers running?
for t in "${TIMERS[@]}"; do
    state="$(systemctl is-active "$t" || true)"     # is-active exits non-zero when inactive
    if [[ "$state" == "active" ]]; then
        lines+=("OK   $t: active")
    else
        lines+=("FAIL $t: ${state:-unknown}")
        problems+=("$t is $state")
    fi
done

# 2. Per config: snapshot count and age of the newest timeline snapshot
now="$(date +%s)"
for cfg in $CONFIGS; do
    # Configs with TIMELINE_CREATE=no take no snapshots on purpose, so don't flag them.
    timeline="$(snapper -c "$cfg" --csvout --separator '|' get-config | awk -F'|' '$1 == "TIMELINE_CREATE" {print $2}')"
    if [[ "$timeline" != "yes" ]]; then
        lines+=("SKIP $cfg: timeline snapshots disabled")
        continue
    fi

    if ! out="$(snapper --iso -c "$cfg" --csvout --separator '|' list \
                --columns number,type,date,cleanup --disable-used-space 2>&1)"; then
        lines+=("FAIL snapper '$cfg': cannot list ($out)")
        problems+=("snapper config '$cfg' unreadable")
        continue
    fi

    # skip the header line and snapshot 0 ("current", which has no date)
    count="$(awk -F'|' 'NR>1 && $1 != 0' <<<"$out" | wc -l)"
    newest="$(awk -F'|' 'NR>1 && $4 == "timeline" {print $3}' <<<"$out" | sort | tail -n 1)"

    if [[ -z "$newest" ]]; then
        lines+=("WARN $cfg: $count snapshots, no timeline snapshot")
        problems+=("$cfg has no timeline snapshot")
        continue
    fi

    age_h=$(( (now - $(date -d "$newest" +%s)) / 3600 ))
    if (( age_h > MAX_AGE_HOURS )); then
        lines+=("WARN $cfg: $count snapshots, newest timeline is ${age_h}h old ($newest)")
        problems+=("$cfg newest timeline snapshot is ${age_h}h old")
    else
        lines+=("OK   $cfg: $count snapshots, newest timeline ${age_h}h old ($newest)")
    fi
done

# 3. Disk usage on / (note: df is approximate on Btrfs because snapshots share blocks)
used="$(df --output=pcent / | tail -n 1 | tr -dc '0-9')"
if (( used >= DISK_WARN )); then
    lines+=("WARN /: ${used}% used (limit ${DISK_WARN}%)")
    problems+=("/ is ${used}% full")
else
    lines+=("OK   /: ${used}% used")
fi

# Build the message
if (( ${#problems[@]} > 0 )); then
    header="🔴 $(hostname): snapshot problems"
else
    header="🟢 $(hostname): snapshots healthy"
fi
body="$header"$'\n''```'$'\n'"$(printf '%s\n' "${lines[@]}")"$'\n''```'

if $dry_run; then
    printf '%s\n' "$body"
    exit 0
fi

# Send to Discord. Escape backslash, quote and newline so the JSON stays valid.
[[ -r "$WEBHOOK_FILE" ]] || { echo "ERROR: cannot read webhook file: $WEBHOOK_FILE" >&2; exit 1; }
webhook="$(head -n 1 "$WEBHOOK_FILE")"
: "${webhook:?webhook file is empty}"

json="$(printf '%s' "$body" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | awk '{printf "%s\\n", $0}')"
curl --silent --show-error --fail --max-time 15 \
    -H 'Content-Type: application/json' \
    -d "{\"content\":\"$json\"}" \
    "$webhook" >/dev/null

echo "report sent (${#problems[@]} problem(s))"
