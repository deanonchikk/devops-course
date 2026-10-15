#!/usr/bin/env bash
set -u

if [[ $# -ne 1 || -z ${1:-} ]]; then
  printf 'Usage: %s SERVICE\n' "$0" >&2
  exit 2
fi

service=$1
syslog=/var/log/syslog

for tool in systemctl journalctl sudo date grep awk; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$tool" >&2
    exit 1
  fi
done

if [[ ! -f $syslog ]] || ! sudo -n test -r "$syslog"; then
  printf 'Cannot read %s; run on the VM as deployer.\n' "$syslog" >&2
  exit 1
fi

cutoff=$(date -u -d '1 hour ago' '+%Y-%m-%dT%H:%M:%S') || exit 1

service_exit=0
if systemctl is-active --quiet -- "$service"; then
  printf 'Service %s: active\n' "$service"
else
  status=$(systemctl is-active -- "$service" 2>/dev/null || true)
  printf 'Service %s: %s\n' "$service" "${status:-unknown}"
  printf 'Last 10 journal entries:\n'
  if ! sudo -n journalctl -u "$service" -n 10 --no-pager; then
    printf 'Could not read the journal for %s.\n' "$service" >&2
  fi
  service_exit=1
fi

if ! error_count=$(
  sudo -n grep -i 'error' "$syslog" |
    awk -v cutoff="$cutoff" 'substr($1, 1, 19) >= cutoff { count++ } END { print count + 0 }'
  pipeline_status=("${PIPESTATUS[@]}")
  if (( pipeline_status[0] > 1 || pipeline_status[1] != 0 )); then
    exit 1
  fi
); then
  printf 'Could not count errors in %s.\n' "$syslog" >&2
  exit 1
fi

printf 'Errors in %s during the last hour: %s\n' "$syslog" "$error_count"
exit "$service_exit"
