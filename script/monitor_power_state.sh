#!/usr/bin/env bash
set -euo pipefail

DURATION_SECONDS="${1:-90}"
INTERVAL_SECONDS="${2:-1}"
END_AT=$((SECONDS + DURATION_SECONDS))

echo "Watching power state for ${DURATION_SECONDS}s. Toggle nodoze while this is running."
echo

while (( SECONDS <= END_AT )); do
  timestamp="$(date '+%H:%M:%S')"
  pid="$(pgrep -x Nodoze | paste -sd ',' - || true)"
  [[ -n "$pid" ]] || pid="-"

  pmset_output="$(pmset -g)"
  sleep_disabled="$(printf '%s\n' "$pmset_output" | awk '/SleepDisabled/ { print $2; found=1 } END { if (!found) print "-" }')"
  sleep_line="$(printf '%s\n' "$pmset_output" | awk '/^[[:space:]]*sleep[[:space:]]/ { sub(/^[[:space:]]+/, ""); print; found=1 } END { if (!found) print "sleep -" }')"

  assertions_output="$(pmset -g assertions)"
  prevent_system="$(printf '%s\n' "$assertions_output" | awk '/PreventSystemSleep/ { print $2; exit }')"
  prevent_idle_system="$(printf '%s\n' "$assertions_output" | awk '/PreventUserIdleSystemSleep/ { print $2; exit }')"
  prevent_display="$(printf '%s\n' "$assertions_output" | awk '/PreventUserIdleDisplaySleep/ { print $2; exit }')"
  nodoze_lines="$(printf '%s\n' "$assertions_output" | grep -i 'nodoze' || true)"

  printf '[%s] Nodoze PID=%s SleepDisabled=%s PreventSystemSleep=%s PreventUserIdleSystemSleep=%s PreventDisplaySleep=%s %s\n' \
    "$timestamp" \
    "$pid" \
    "$sleep_disabled" \
    "${prevent_system:--}" \
    "${prevent_idle_system:--}" \
    "${prevent_display:--}" \
    "$sleep_line"

  if [[ -n "$nodoze_lines" ]]; then
    printf '%s\n' "$nodoze_lines" | sed 's/^/  nodoze assertion: /'
  fi

  sleep "$INTERVAL_SECONDS"
done
